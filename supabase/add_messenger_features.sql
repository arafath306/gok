-- ============================================================================
-- MIGRATION: ADD MESSENGER UPGRADE FEATURES
-- Run this in the Supabase SQL Editor.
-- ============================================================================

-- 1. Add media support columns to public.messages
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_type TEXT; -- 'image', 'file', etc.

-- 2. Add active status columns to public.profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active_status_enabled BOOLEAN DEFAULT true NOT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL;
