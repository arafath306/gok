-- Migration: Create support_tickets table for contact submissions
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    email TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT DEFAULT 'pending' NOT NULL, -- 'pending', 'in_review', 'resolved'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Disable/Enable RLS
ALTER TABLE public.support_tickets DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Allow public to insert support tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Allow admins to select/update/delete support tickets" ON public.support_tickets;

CREATE POLICY "Allow public to insert support tickets"
    ON public.support_tickets FOR INSERT
    WITH CHECK (true); -- Anyone can contact support

CREATE POLICY "Allow admins to select/update/delete support tickets"
    ON public.support_tickets FOR ALL
    USING (
        -- Allow authenticated user to read/modify if they have Admin/Moderator role in profiles
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() AND (role = 'Admin' OR role = 'Moderator')
        )
    );
