-- ============================================================================
-- DAK SOCIAL NETWORK - NEW CLEAN SCHEMAS (NATIVE SUPABASE AUTH)
-- Execute this script in your new Supabase project's SQL Editor (Query Editor).
-- This sets up all tables, triggers, and automated notification scripts.
-- ============================================================================

-- 1. PROFILES TABLE (References Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    bio TEXT,
    avatar_url TEXT,
    cover_url TEXT,
    followers_count INTEGER DEFAULT 0 NOT NULL,
    following_count INTEGER DEFAULT 0 NOT NULL,
    phone TEXT,
    country TEXT,
    division TEXT,
    city TEXT,
    village TEXT,
    zip TEXT,
    gender TEXT,
    birthdate TEXT,
    is_private BOOLEAN DEFAULT false NOT NULL,
    allow_mentions TEXT DEFAULT 'everyone' NOT NULL, -- 'everyone', 'people_you_follow', 'no_one'
    filter_adult BOOLEAN DEFAULT true NOT NULL,
    autoplay_videos BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) or disable for direct access (default: disable for ease)
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- AUTOMATIC PROFILE CREATION TRIGGER ON SIGNUP
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url, is_private)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || SUBSTRING(NEW.id::text FROM 1 FOR 8)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Dak User'),
    NEW.raw_user_meta_data->>'avatar_url',
    false
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 2. THREADS (POSTS) TABLE
CREATE TABLE IF NOT EXISTS public.threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    image_urls TEXT[], -- Array of image URLs
    video_url TEXT,
    likes_count INTEGER DEFAULT 0 NOT NULL,
    replies_count INTEGER DEFAULT 0 NOT NULL,
    reposts_count INTEGER DEFAULT 0 NOT NULL,
    views_count INTEGER DEFAULT 0 NOT NULL,
    is_pinned BOOLEAN DEFAULT false NOT NULL,
    mute_notifications BOOLEAN DEFAULT false NOT NULL,
    hide_from_profile BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE public.threads DISABLE ROW LEVEL SECURITY;


-- 3. LIKES (REACTIONS) TABLE
CREATE TABLE IF NOT EXISTS public.likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    reaction_type TEXT DEFAULT '❤️' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_thread_like UNIQUE (user_id, thread_id)
);
ALTER TABLE public.likes DISABLE ROW LEVEL SECURITY;


-- 4. COMMENTS (REPLIES) TABLE
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE, -- Supports nested replies
    likes_count INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE public.comments DISABLE ROW LEVEL SECURITY;


-- 5. COMMENT LIKES TABLE
CREATE TABLE IF NOT EXISTS public.comment_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_comment_like UNIQUE (user_id, comment_id)
);
ALTER TABLE public.comment_likes DISABLE ROW LEVEL SECURITY;


-- 6. FOLLOWS RELATIONSHIP TABLE
CREATE TABLE IF NOT EXISTS public.follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_follower_following UNIQUE (follower_id, following_id)
);
ALTER TABLE public.follows DISABLE ROW LEVEL SECURITY;


-- 7. MESSAGES (DM CHAT) TABLE
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;


-- 8. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, -- Target user
    actor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, -- Performer
    type TEXT NOT NULL, -- 'like', 'comment', 'follow', 'message', 'mention'
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT notifications_type_check CHECK (LOWER(type) IN ('like', 'comment', 'reply', 'follow', 'mention', 'message'))
);
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;


-- 9. REPORTS TABLE
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, -- Reporter
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending' NOT NULL, -- 'pending', 'resolved'
    action_taken TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE public.reports DISABLE ROW LEVEL SECURITY;


-- 10. SYSTEM SETTINGS & AUDIT LOGS
CREATE TABLE IF NOT EXISTS public.system_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
ALTER TABLE public.system_settings DISABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id TEXT NOT NULL,
    action TEXT NOT NULL,
    details TEXT,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE public.audit_logs DISABLE ROW LEVEL SECURITY;

-- Initialize default admin settings
INSERT INTO public.system_settings (key, value) VALUES 
('maintenance_mode', 'false'),
('disable_signups', 'false'),
('api_rate_limit', '100')
ON CONFLICT (key) DO NOTHING;


-- 11. BLOCKS TABLE
CREATE TABLE IF NOT EXISTS public.blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    blocked_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_blocker_blocked UNIQUE (blocker_id, blocked_id)
);
ALTER TABLE public.blocks DISABLE ROW LEVEL SECURITY;


-- 12. MUTES TABLE
CREATE TABLE IF NOT EXISTS public.mutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    muter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    muted_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_muter_muted UNIQUE (muter_id, muted_id)
);
ALTER TABLE public.mutes DISABLE ROW LEVEL SECURITY;


-- 13. THREAD HIDES TABLE (Hides posts for specific users)
CREATE TABLE IF NOT EXISTS public.thread_hides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_thread_hide_user UNIQUE (thread_id, user_id)
);
ALTER TABLE public.thread_hides DISABLE ROW LEVEL SECURITY;


-- 14. REPOSTS TABLE
CREATE TABLE IF NOT EXISTS public.reposts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_repost UNIQUE (user_id, thread_id)
);
ALTER TABLE public.reposts DISABLE ROW LEVEL SECURITY;


-- ============================================================================
-- AUTOMATED TRIGGERS FOR STATISTICS AND NOTIFICATIONS (UUID Standardized)
-- ============================================================================

-- A. Trigger: Comment count updates on threads
CREATE OR REPLACE FUNCTION public.handle_comment_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.threads SET replies_count = replies_count + 1 WHERE id = NEW.thread_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.threads SET replies_count = GREATEST(0, replies_count - 1) WHERE id = OLD.thread_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_comment_change
AFTER INSERT OR DELETE ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.handle_comment_change();


-- B. Trigger: Repost count updates on threads
CREATE OR REPLACE FUNCTION public.handle_repost_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.threads SET reposts_count = reposts_count + 1 WHERE id = NEW.thread_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.threads SET reposts_count = GREATEST(0, reposts_count - 1) WHERE id = OLD.thread_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_repost_change
AFTER INSERT OR DELETE ON public.reposts
FOR EACH ROW EXECUTE FUNCTION public.handle_repost_change();


-- C. Trigger: Follow / Following count updates
CREATE OR REPLACE FUNCTION public.handle_follow_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    UPDATE public.profiles SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.profiles SET following_count = GREATEST(0, following_count - 1) WHERE id = OLD.follower_id;
    UPDATE public.profiles SET followers_count = GREATEST(0, followers_count - 1) WHERE id = OLD.following_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_follow_change
AFTER INSERT OR DELETE ON public.follows
FOR EACH ROW EXECUTE FUNCTION public.handle_follow_change();


-- D. Trigger: Likes count updates on threads
CREATE OR REPLACE FUNCTION public.handle_like_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE public.threads SET likes_count = likes_count + 1 WHERE id = NEW.thread_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE public.threads SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.thread_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_like_change
AFTER INSERT OR DELETE ON public.likes
FOR EACH ROW EXECUTE FUNCTION public.handle_like_change();


-- E. Trigger: Send notifications on post comments
CREATE OR REPLACE FUNCTION public.notify_on_comment()
RETURNS TRIGGER AS $$
DECLARE
  target_user_id UUID;
  is_muted BOOLEAN;
BEGIN
  SELECT user_id, mute_notifications INTO target_user_id, is_muted 
  FROM public.threads 
  WHERE id = NEW.thread_id;
  
  IF target_user_id IS NOT NULL AND target_user_id != NEW.user_id AND (is_muted IS NOT TRUE) THEN
    INSERT INTO public.notifications (user_id, actor_id, type, thread_id, content)
    VALUES (
      target_user_id,
      NEW.user_id,
      'comment',
      NEW.thread_id,
      'commented on your post: ' || LEFT(NEW.content, 50)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_comment_inserted
AFTER INSERT ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.notify_on_comment();


-- F. Trigger: Send notifications on post likes
CREATE OR REPLACE FUNCTION public.notify_on_like()
RETURNS TRIGGER AS $$
DECLARE
  target_user_id UUID;
  is_muted BOOLEAN;
BEGIN
  SELECT user_id, mute_notifications INTO target_user_id, is_muted 
  FROM public.threads 
  WHERE id = NEW.thread_id;
  
  IF target_user_id IS NOT NULL AND target_user_id != NEW.user_id AND (is_muted IS NOT TRUE) THEN
    INSERT INTO public.notifications (user_id, actor_id, type, thread_id, content)
    VALUES (
      target_user_id,
      NEW.user_id,
      'like',
      NEW.thread_id,
      'liked your post'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_like_inserted
AFTER INSERT ON public.likes
FOR EACH ROW EXECUTE FUNCTION public.notify_on_like();


-- G. Trigger: Send notifications on user follows
CREATE OR REPLACE FUNCTION public.notify_on_follow()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.following_id != NEW.follower_id THEN
    INSERT INTO public.notifications (user_id, actor_id, type, content)
    VALUES (
      NEW.following_id,
      NEW.follower_id,
      'follow',
      'started following you'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_follow_inserted
AFTER INSERT ON public.follows
FOR EACH ROW EXECUTE FUNCTION public.notify_on_follow();


-- ============================================================================
-- SUPABASE REALTIME PUBLICATION ENABLEMENT
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.threads;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table threads already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.likes;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table likes already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table comments already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.follows;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table follows already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table messages already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table notifications already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.blocks;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table blocks already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.mutes;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table mutes already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.thread_hides;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table thread_hides already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.reposts;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table reposts already in publication or failed to add.';
    END;
  END IF;
END $$;
