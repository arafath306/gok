-- Migration to add support for post pinning, muting notifications, profile hiding, and custom user hiding.
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS mute_notifications BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS hide_from_profile BOOLEAN DEFAULT false NOT NULL;

-- Create thread hides table to restrict visibility to specific users
CREATE TABLE IF NOT EXISTS public.thread_hides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_thread_hide_user UNIQUE (thread_id, user_id)
);

-- Enable Realtime for thread_hides table
ALTER PUBLICATION supabase_realtime ADD TABLE public.thread_hides;

-- Update notify_on_like function to check mute_notifications
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

-- Update notify_on_comment function to check mute_notifications
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
