-- Migration to add image_url to comments table
ALTER TABLE public.comments ADD COLUMN IF NOT EXISTS image_url TEXT;
