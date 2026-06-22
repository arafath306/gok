-- ============================================================================
-- SQL TO CREATE PROFILE VERIFICATION SYSTEM
-- Run this in your Supabase SQL Editor.
-- ============================================================================

-- 1. Create verification_requests table
CREATE TABLE IF NOT EXISTS public.verification_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    full_name TEXT NOT NULL,
    username TEXT NOT NULL,
    date_of_birth DATE,
    bio TEXT,
    nid_number TEXT NOT NULL,
    nid_front_url TEXT NOT NULL,
    nid_back_url TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    bkash_sender_number TEXT NOT NULL,
    bkash_trx_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any to prevent duplicates on rerun
DROP POLICY IF EXISTS "Users can insert their own verification request" ON public.verification_requests;
DROP POLICY IF EXISTS "Users can select their own verification request" ON public.verification_requests;
DROP POLICY IF EXISTS "Admins can update verification requests" ON public.verification_requests;

-- 2. Create RLS Policies
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

-- 3. Create Trigger Functions for Profile Syncing

-- Trigger for Insert/Upsert (Starts queue)
CREATE OR REPLACE FUNCTION public.handle_verification_request_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles
    SET verification_requested = true, is_verified = false
    WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for Update (Approval / Rejection / Re-submit)
CREATE OR REPLACE FUNCTION public.handle_verification_request_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'approved' THEN
        UPDATE public.profiles
        SET is_verified = true, verification_requested = false
        WHERE id = NEW.user_id;
    ELSIF NEW.status = 'rejected' THEN
        UPDATE public.profiles
        SET is_verified = false, verification_requested = false
        WHERE id = NEW.user_id;
    ELSIF NEW.status = 'pending' THEN
        UPDATE public.profiles
        SET is_verified = false, verification_requested = true
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop triggers if they exist
DROP TRIGGER IF EXISTS on_verification_request_inserted ON public.verification_requests;
DROP TRIGGER IF EXISTS on_verification_request_updated ON public.verification_requests;

-- Create Triggers
CREATE TRIGGER on_verification_request_inserted
    AFTER INSERT ON public.verification_requests
    FOR EACH ROW EXECUTE FUNCTION public.handle_verification_request_insert();

CREATE TRIGGER on_verification_request_updated
    AFTER UPDATE ON public.verification_requests
    FOR EACH ROW EXECUTE FUNCTION public.handle_verification_request_update();
