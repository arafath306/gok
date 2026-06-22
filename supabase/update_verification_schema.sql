-- Update profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS verified_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS verified_plan_id TEXT;

-- Update verification_requests table
ALTER TABLE public.verification_requests 
ADD COLUMN IF NOT EXISTS face_image_url TEXT,
ADD COLUMN IF NOT EXISTS is_renewal BOOLEAN DEFAULT FALSE;
