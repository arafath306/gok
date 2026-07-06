-- Pigeon Communities Phase 1 Schema Migration (Idempotent)

-- 1. Communities Table
CREATE TABLE IF NOT EXISTS public.communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    handle TEXT UNIQUE,
    topic TEXT,
    description TEXT,
    avatar_url TEXT,
    banner_url TEXT,
    privacy TEXT DEFAULT 'public', -- 'public' or 'restricted'
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    member_count INT DEFAULT 1,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure all columns exist in case the table was created previously with fewer columns
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS handle TEXT UNIQUE;
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS topic TEXT;
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS banner_url TEXT;
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS privacy TEXT DEFAULT 'public';
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS member_count INT DEFAULT 1;
ALTER TABLE public.communities ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;

-- Enable RLS for communities
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

-- 2. Community Members Table
CREATE TABLE IF NOT EXISTS public.community_members (
    community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'owner', 'moderator', 'member'
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (community_id, user_id)
);

-- Enable RLS for community members
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;

-- 3. Community Rules Table
CREATE TABLE IF NOT EXISTS public.community_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for community rules
ALTER TABLE public.community_rules ENABLE ROW LEVEL SECURITY;

-- 4. Alter Threads Table to support community posts
ALTER TABLE public.threads
ADD COLUMN IF NOT EXISTS community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_communities_name ON public.communities(name);
CREATE INDEX IF NOT EXISTS idx_community_members_user_id ON public.community_members(user_id);
CREATE INDEX IF NOT EXISTS idx_threads_community_id ON public.threads(community_id);

-- ==========================
-- ROW LEVEL SECURITY POLICIES
-- ==========================

-- Policies for communities
DROP POLICY IF EXISTS "Public and Restricted communities are viewable by everyone." ON public.communities;
CREATE POLICY "Public and Restricted communities are viewable by everyone."
ON public.communities FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Users can create communities." ON public.communities;
CREATE POLICY "Users can create communities."
ON public.communities FOR INSERT
WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Owners can update their communities." ON public.communities;
CREATE POLICY "Owners can update their communities."
ON public.communities FOR UPDATE
USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Owners can delete their communities." ON public.communities;
CREATE POLICY "Owners can delete their communities."
ON public.communities FOR DELETE
USING (auth.uid() = owner_id);

-- Policies for community_members
DROP POLICY IF EXISTS "Community members are viewable by everyone." ON public.community_members;
CREATE POLICY "Community members are viewable by everyone."
ON public.community_members FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Users can join public communities." ON public.community_members;
CREATE POLICY "Users can join public communities."
ON public.community_members FOR INSERT
WITH CHECK (
    (auth.uid() = user_id 
    AND EXISTS (
        SELECT 1 FROM public.communities 
        WHERE id = community_id AND privacy = 'public'
    ))
    OR EXISTS (
        SELECT 1 FROM public.communities 
        WHERE id = community_id AND owner_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Owners and moderators can manage members." ON public.community_members;
CREATE POLICY "Owners and moderators can manage members."
ON public.community_members FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = community_members.community_id
        AND user_id = auth.uid()
        AND role IN ('owner', 'moderator')
    )
);

DROP POLICY IF EXISTS "Users can leave or moderators can remove members." ON public.community_members;
CREATE POLICY "Users can leave or moderators can remove members."
ON public.community_members FOR DELETE
USING (
    auth.uid() = user_id OR
    EXISTS (
        SELECT 1 FROM public.community_members cm
        WHERE cm.community_id = community_members.community_id
        AND cm.user_id = auth.uid()
        AND cm.role IN ('owner', 'moderator')
    )
);

-- Policies for community_rules
DROP POLICY IF EXISTS "Rules are viewable by everyone." ON public.community_rules;
CREATE POLICY "Rules are viewable by everyone."
ON public.community_rules FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Only owners and moderators can insert rules." ON public.community_rules;
CREATE POLICY "Only owners and moderators can insert rules."
ON public.community_rules FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = community_rules.community_id
        AND user_id = auth.uid()
        AND role IN ('owner', 'moderator')
    )
);

DROP POLICY IF EXISTS "Only owners and moderators can update rules." ON public.community_rules;
CREATE POLICY "Only owners and moderators can update rules."
ON public.community_rules FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = community_rules.community_id
        AND user_id = auth.uid()
        AND role IN ('owner', 'moderator')
    )
);

DROP POLICY IF EXISTS "Only owners and moderators can delete rules." ON public.community_rules;
CREATE POLICY "Only owners and moderators can delete rules."
ON public.community_rules FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.community_members
        WHERE community_id = community_rules.community_id
        AND user_id = auth.uid()
        AND role IN ('owner', 'moderator')
    )
);

-- RPC functions to increment and decrement community member counts safely

CREATE OR REPLACE FUNCTION increment_community_member_count(c_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.communities
  SET member_count = member_count + 1
  WHERE id = c_id;
END;
$$;

CREATE OR REPLACE FUNCTION decrement_community_member_count(c_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.communities
  SET member_count = GREATEST(member_count - 1, 0)
  WHERE id = c_id;
END;
$$;
