-- ============================================================================
-- SQL TO CREATE MISSING SCHEMAS (COMMENTS, MESSAGES, REPOSTS, AUDIT LOGS)
-- Run this in your Supabase SQL Editor to resolve the PGRST205 / Table Not Found errors.
-- ============================================================================

-- 1. Create public.comments table
CREATE TABLE IF NOT EXISTS public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE, -- Supports nested comment replies
    likes_count INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create public.comment_likes table
CREATE TABLE IF NOT EXISTS public.comment_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_comment_like UNIQUE (user_id, comment_id)
);

-- 3. Create public.reposts table
CREATE TABLE IF NOT EXISTS public.reposts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_repost UNIQUE (user_id, thread_id)
);

-- 4. Create public.messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    receiver_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Create public.audit_logs table
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id TEXT NOT NULL,
    action TEXT NOT NULL,
    details TEXT,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Disable Row Level Security (RLS) on newly created tables for direct access
ALTER TABLE public.comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.reposts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs DISABLE ROW LEVEL SECURITY;

-- 7. Add comments and messages to Supabase Realtime publication safely
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table comments already in publication or failed to add.';
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Table messages already in publication or failed to add.';
    END;
  END IF;
END $$;

-- 8. Setup Trigger: Comment count updates on threads
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

DROP TRIGGER IF EXISTS on_comment_change ON public.comments;
CREATE TRIGGER on_comment_change
AFTER INSERT OR DELETE ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.handle_comment_change();

-- 9. Setup Trigger: Notifications on comment inserts
CREATE OR REPLACE FUNCTION public.notify_on_comment()
RETURNS TRIGGER AS $$
DECLARE
  target_user_id TEXT;
  is_muted BOOLEAN;
BEGIN
  SELECT user_id::text, mute_notifications INTO target_user_id, is_muted 
  FROM public.threads 
  WHERE id = NEW.thread_id;
  
  IF target_user_id IS NOT NULL AND target_user_id != NEW.user_id::text AND (is_muted IS NOT TRUE) THEN
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

DROP TRIGGER IF EXISTS on_comment_inserted ON public.comments;
CREATE TRIGGER on_comment_inserted
AFTER INSERT ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.notify_on_comment();

-- 10. Setup Trigger: Repost count updates on threads
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

DROP TRIGGER IF EXISTS on_repost_change ON public.reposts;
CREATE TRIGGER on_repost_change
AFTER INSERT OR DELETE ON public.reposts
FOR EACH ROW EXECUTE FUNCTION public.handle_repost_change();

-- 11. Create public.blocks table
CREATE TABLE IF NOT EXISTS public.blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    blocked_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_blocker_blocked UNIQUE (blocker_id, blocked_id)
);
ALTER TABLE public.blocks DISABLE ROW LEVEL SECURITY;

-- 12. Create public.mutes table
CREATE TABLE IF NOT EXISTS public.mutes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    muter_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    muted_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_muter_muted UNIQUE (muter_id, muted_id)
);
ALTER TABLE public.mutes DISABLE ROW LEVEL SECURITY;

-- 13. Create public.thread_hides table
CREATE TABLE IF NOT EXISTS public.thread_hides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_thread_hide_user UNIQUE (thread_id, user_id)
);
ALTER TABLE public.thread_hides DISABLE ROW LEVEL SECURITY;

-- 14. Enable Realtime updates for these tables
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
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
  END IF;
END $$;
