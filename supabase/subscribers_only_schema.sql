-- Add is_subscriber_only to threads table
ALTER TABLE public.threads 
ADD COLUMN IF NOT EXISTS is_subscriber_only BOOLEAN DEFAULT false;
