-- Fix for poll_votes foreign key constraint that prevents voting
-- Run this in your Supabase SQL Editor

-- 1. Drop the existing foreign key constraint that references auth.users
ALTER TABLE public.poll_votes 
  DROP CONSTRAINT IF EXISTS poll_votes_user_id_fkey;

-- 2. Add the correct foreign key constraint referencing public.profiles
ALTER TABLE public.poll_votes 
  ADD CONSTRAINT poll_votes_user_id_fkey 
  FOREIGN KEY (user_id) 
  REFERENCES public.profiles(id) 
  ON DELETE CASCADE;

-- 3. Ensure RLS allows authenticated users to insert votes
DROP POLICY IF EXISTS "Allow authenticated users to vote" ON public.poll_votes;
CREATE POLICY "Allow authenticated users to vote" ON public.poll_votes
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. Ensure RLS allows users to delete their votes
DROP POLICY IF EXISTS "Allow users to delete their own votes" ON public.poll_votes;
CREATE POLICY "Allow users to delete their own votes" ON public.poll_votes
FOR DELETE USING (auth.uid() = user_id);

-- 5. Ensure public read access is enabled
DROP POLICY IF EXISTS "Allow public read access to poll votes" ON public.poll_votes;
CREATE POLICY "Allow public read access to poll votes" ON public.poll_votes
FOR SELECT USING (true);
