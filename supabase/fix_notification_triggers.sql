-- ============================================================================
-- SQL TO UPDATE NOTIFICATION TRIGGERS AND CONSTRAINT
-- Run this in your Supabase SQL Editor to resolve the type conversion error (42804)
-- and check constraint violation (23514).
-- ============================================================================

-- 1. Fix the notifications type check constraint to be case-insensitive
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check 
  CHECK (LOWER(type) IN ('like', 'comment', 'reply', 'follow', 'mention', 'message'));

-- 2. Fix notify_on_comment trigger function
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

-- 3. Fix notify_on_like trigger function
CREATE OR REPLACE FUNCTION public.notify_on_like()
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
      'like',
      NEW.thread_id,
      'liked your post'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Fix notify_on_follow trigger function
CREATE OR REPLACE FUNCTION public.notify_on_follow()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.following_id::text != NEW.follower_id::text THEN
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
