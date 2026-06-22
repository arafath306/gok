-- Migration to add saves_count and shares_count to threads table and setup auto-update trigger for saves

ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS saves_count INTEGER DEFAULT 0 NOT NULL;
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS shares_count INTEGER DEFAULT 0 NOT NULL;

-- Function to increment shares_count
CREATE OR REPLACE FUNCTION public.increment_shares_count(thread_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.threads
    SET shares_count = shares_count + 1
    WHERE id = thread_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger function for saved_posts changes to auto-update saves_count
CREATE OR REPLACE FUNCTION public.handle_saved_posts_change()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.threads
        SET saves_count = saves_count + 1
        WHERE id = NEW.thread_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.threads
        SET saves_count = GREATEST(0, saves_count - 1)
        WHERE id = OLD.thread_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS on_saved_posts_change ON public.saved_posts;

CREATE TRIGGER on_saved_posts_change
AFTER INSERT OR DELETE ON public.saved_posts
FOR EACH ROW EXECUTE FUNCTION public.handle_saved_posts_change();
