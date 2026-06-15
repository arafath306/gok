-- 1. Add quote_text column to reposts table to support Quote Posts
ALTER TABLE public.reposts ADD COLUMN IF NOT EXISTS quote_text TEXT;

-- 2. Add UPDATE policy for reposts table to allow users to edit their quote text
DROP POLICY IF EXISTS "Allow users to update their own reposts" ON public.reposts;
CREATE POLICY "Allow users to update their own reposts" 
ON public.reposts FOR UPDATE 
USING (auth.uid() = user_id);
