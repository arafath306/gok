-- Migration: Add Profile Verification Columns
-- Run this in your Supabase SQL Editor.

-- 1. Add verification flags to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS verification_requested BOOLEAN DEFAULT false NOT NULL;

-- 2. Grant permissions so authenticated/anon roles can read them, and admins can edit them
-- (Normally disabling RLS handles this, but adding it for future-proofing policies)
CREATE POLICY "Allow public read on verification fields" 
ON public.profiles FOR SELECT 
USING (true);
