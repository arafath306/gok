-- ============================================================================
-- DAK SOCIAL NETWORK - MODERATOR KEYS TABLE & POLICIES
-- Execute this script in your Supabase SQL Editor.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.moderator_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    permissions TEXT[] NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE public.moderator_keys ENABLE ROW LEVEL SECURITY;

-- 1. Policy to allow anonymous read access (necessary for checking code validity during login)
DROP POLICY IF EXISTS "Allow public read access to active moderator keys" ON public.moderator_keys;
CREATE POLICY "Allow public read access to active moderator keys"
    ON public.moderator_keys FOR SELECT
    USING (is_active = true AND (expires_at IS NULL OR expires_at > now()));

-- 2. Policy to allow all operations (Insert, Update, Delete) to the admin panel using anonymous key (or auth)
DROP POLICY IF EXISTS "Allow anon all operations" ON public.moderator_keys;
CREATE POLICY "Allow anon all operations"
    ON public.moderator_keys FOR ALL
    USING (true)
    WITH CHECK (true);
