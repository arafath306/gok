-- ============================================================================
-- DAK SOCIAL NETWORK - AUTOMATED PUSH NOTIFICATIONS TRIGGERS
-- Execute this script in your Supabase SQL Editor.
-- NOTE: This requires pg_net extension to be enabled in your Supabase Database.
-- Run `CREATE EXTENSION IF NOT EXISTS pg_net;` if you haven't already.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net;

-- 1. Create a generic function that calls the Edge Function
CREATE OR REPLACE FUNCTION public.notify_fcm_edge_function()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  receiver_id UUID;
  receiver_token TEXT;
  sender_name TEXT;
  push_title TEXT;
  push_body TEXT;
  payload JSONB;
BEGIN
  -- Determine context based on the table name
  IF TG_TABLE_NAME = 'messages' THEN
    receiver_id := NEW.receiver_id;
    
    -- Get sender name
    SELECT full_name INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;
    
    push_title := sender_name;
    push_body := 'Sent you a new message';
    
  ELSIF TG_TABLE_NAME = 'comments' THEN
    -- Get the owner of the thread (post) being commented on
    SELECT user_id INTO receiver_id FROM public.threads WHERE id = NEW.thread_id;
    
    -- Don't notify if commenting on own post
    IF receiver_id = NEW.user_id THEN
      RETURN NEW;
    END IF;

    -- Get sender name
    SELECT full_name INTO sender_name FROM public.profiles WHERE id = NEW.user_id;
    
    push_title := 'New Comment';
    push_body := sender_name || ' commented on your post: ' || NEW.content;
    
  END IF;

  -- Fetch the receiver's FCM token
  SELECT fcm_token INTO receiver_token FROM public.profiles WHERE id = receiver_id;

  -- If they have a token, trigger the HTTP request
  IF receiver_token IS NOT NULL THEN
    payload := jsonb_build_object(
      'fcm_token', receiver_token,
      'title', push_title,
      'body', push_body
    );

    -- IMPORTANT: Replace 'lznxtbnqwaryqkyxfwgy' with your actual project ref if different
    PERFORM net.http_post(
      url := 'https://lznxtbnqwaryqkyxfwgy.supabase.co/functions/v1/send_auto_push',
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body := payload
    );
  END IF;

  RETURN NEW;
END;
$$;

-- 2. Create Trigger for Messages
DROP TRIGGER IF EXISTS trigger_push_on_message ON public.messages;
CREATE TRIGGER trigger_push_on_message
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_fcm_edge_function();

-- 3. Create Trigger for Comments
DROP TRIGGER IF EXISTS trigger_push_on_comment ON public.comments;
CREATE TRIGGER trigger_push_on_comment
  AFTER INSERT ON public.comments
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_fcm_edge_function();

