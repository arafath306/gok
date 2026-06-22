-- ============================================================================
-- NESTED COMMENTS AND SAVE/SHARE COUNTERS SYSTEM MIGRATION
-- Execute this script in your Supabase SQL Editor.
-- ============================================================================

-- 1. Add necessary columns to comments table
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS saves_count INTEGER DEFAULT 0 NOT NULL;
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS shares_count INTEGER DEFAULT 0 NOT NULL;
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS replies_count INTEGER DEFAULT 0 NOT NULL;

-- 2. Create saved_comments table
CREATE TABLE IF NOT EXISTS public.saved_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_user_comment_save UNIQUE (user_id, comment_id)
);
ALTER TABLE public.saved_comments DISABLE ROW LEVEL SECURITY;

-- 3. Function to increment comment shares_count
CREATE OR REPLACE FUNCTION public.increment_comment_shares_count(c_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.comments
    SET shares_count = shares_count + 1
    WHERE id = c_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Trigger for saved_comments changes to auto-update saves_count on comments
CREATE OR REPLACE FUNCTION public.handle_saved_comments_change()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.comments
        SET saves_count = saves_count + 1
        WHERE id = NEW.comment_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.comments
        SET saves_count = GREATEST(0, saves_count - 1)
        WHERE id = OLD.comment_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_saved_comments_change ON public.saved_comments;
CREATE TRIGGER on_saved_comments_change
AFTER INSERT OR DELETE ON public.saved_comments
FOR EACH ROW EXECUTE FUNCTION public.handle_saved_comments_change();

-- 5. Update the handle_comment_change trigger function to handle replies_count for comments
CREATE OR REPLACE FUNCTION public.handle_comment_change()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF NEW.parent_id IS NULL THEN
      -- Increment reply count on the thread (only for top-level comments)
      UPDATE public.threads SET replies_count = replies_count + 1 WHERE id = NEW.thread_id;
    ELSE
      -- If this is a nested comment, increment replies_count on the parent comment
      UPDATE public.comments SET replies_count = replies_count + 1 WHERE id = NEW.parent_id;
    END IF;
  ELSIF (TG_OP = 'DELETE') THEN
    IF OLD.parent_id IS NULL THEN
      -- Decrement reply count on the thread (only for top-level comments)
      UPDATE public.threads SET replies_count = GREATEST(0, replies_count - 1) WHERE id = OLD.thread_id;
    ELSE
      -- If this is a nested comment, decrement replies_count on the parent comment
      UPDATE public.comments SET replies_count = GREATEST(0, replies_count - 1) WHERE id = OLD.parent_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
