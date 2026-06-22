-- ============================================================================
-- SQL TO FIX VERIFICATION REQUESTS PERMISSIONS / RLS
-- Run this in your Supabase SQL Editor to make requests visible to the Admin Panel.
-- ============================================================================

-- Option A: Disable Row Level Security entirely on verification_requests
-- (This ensures the Admin Panel can read and update requests without signing in)
ALTER TABLE public.verification_requests DISABLE ROW LEVEL SECURITY;

-- Option B (Alternative): If you prefer to keep RLS enabled but allow public access
-- (Run this if you don't want to disable RLS entirely)
/*
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert their own verification request" ON public.verification_requests;
DROP POLICY IF EXISTS "Users can select their own verification request" ON public.verification_requests;
DROP POLICY IF EXISTS "Admins can update verification requests" ON public.verification_requests;
DROP POLICY IF EXISTS "Allow public insert on verification requests" ON public.verification_requests;
DROP POLICY IF EXISTS "Allow public select on verification requests" ON public.verification_requests;
DROP POLICY IF EXISTS "Allow public update on verification requests" ON public.verification_requests;

CREATE POLICY "Allow public insert on verification requests"
ON public.verification_requests FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow public select on verification requests"
ON public.verification_requests FOR SELECT
USING (true);

CREATE POLICY "Allow public update on verification requests"
ON public.verification_requests FOR UPDATE
USING (true)
WITH CHECK (true);
*/
