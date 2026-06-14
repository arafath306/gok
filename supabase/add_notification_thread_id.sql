-- ============================================================================
-- SQL TO ADD MISSING COLUMNS TO NOTIFICATIONS TABLE
-- Run this in your Supabase SQL Editor to resolve the missing column errors (42703).
-- ============================================================================

-- Add thread_id column to notifications if it doesn't exist
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE;
