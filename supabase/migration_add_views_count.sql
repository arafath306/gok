-- Migration: Add views_count to threads table and create increment function
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0 NOT NULL;

-- Function to increment views safely
CREATE OR REPLACE FUNCTION public.increment_thread_views(thread_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.threads 
  SET views_count = views_count + 1 
  WHERE id = thread_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
