-- Migration: Add Admin Panel integration fields
-- Run this in your Supabase SQL Editor.

-- 1. Add fields to public.profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS reach_multiplier NUMERIC DEFAULT 1.0 NOT NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role TEXT; -- 'Admin', 'Moderator', 'Junior Mod', etc.

-- 2. Add fields to public.threads
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS is_boosted BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS boost_status TEXT DEFAULT 'none' NOT NULL; -- 'none', 'active', 'paused', 'terminated'
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS boost_spend INTEGER DEFAULT 0 NOT NULL;
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS boost_reach INTEGER DEFAULT 0 NOT NULL;
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS boost_roi TEXT DEFAULT '+0.0%' NOT NULL;

-- 3. Add fields to public.topics
ALTER TABLE public.topics ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false NOT NULL;
