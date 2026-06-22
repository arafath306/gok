-- ============================================================================
-- MIGRATION: ENFORCE BLOCK RESTRICTIONS AT DATABASE LEVEL
-- Run this in the Supabase SQL Editor.
-- ============================================================================

-- 1. PROFILES: Prevent blocked users from reading blocker's profiles, but allow blockers to see blocked profiles (for unblocking)
DROP POLICY IF EXISTS "Allow public read access on profiles" ON public.profiles;

CREATE POLICY "Allow public read access on profiles" 
ON public.profiles FOR SELECT 
USING (
  auth.uid() IS NULL 
  OR NOT EXISTS (
    SELECT 1 FROM public.blocks 
    WHERE blocker_id = id AND blocked_id = auth.uid()
  )
);


-- 2. THREADS: Prevent blockers and blocked users from reading each other's threads/posts
DROP POLICY IF EXISTS "Allow public read access on threads" ON public.threads;

CREATE POLICY "Allow public read access on threads" 
ON public.threads FOR SELECT 
USING (
  auth.uid() IS NULL 
  OR NOT EXISTS (
    SELECT 1 FROM public.blocks 
    WHERE (blocker_id = auth.uid() AND blocked_id = user_id)
       OR (blocker_id = user_id AND blocked_id = auth.uid())
  )
);


-- 3. MESSAGES: Prevent inserting direct messages between blocker and blocked users
DROP POLICY IF EXISTS "Allow users to insert their own messages" ON public.messages;

CREATE POLICY "Allow users to insert their own messages" 
ON public.messages FOR INSERT 
WITH CHECK (
  auth.uid() = sender_id 
  AND NOT EXISTS (
    SELECT 1 FROM public.blocks 
    WHERE (blocker_id = sender_id AND blocked_id = receiver_id)
       OR (blocker_id = receiver_id AND blocked_id = sender_id)
  )
);
