-- Migration: Create user_sessions table for active sessions tracking
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_name TEXT NOT NULL,
    location TEXT NOT NULL,
    status TEXT NOT NULL,
    ip_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_active TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Disable RLS initially if needed, then enable RLS
ALTER TABLE public.user_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow users to read their own sessions" ON public.user_sessions;
DROP POLICY IF EXISTS "Allow users to insert their own sessions" ON public.user_sessions;
DROP POLICY IF EXISTS "Allow users to update their own sessions" ON public.user_sessions;
DROP POLICY IF EXISTS "Allow users to delete their own sessions" ON public.user_sessions;

-- Policies
CREATE POLICY "Allow users to read their own sessions"
    ON public.user_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Allow users to insert their own sessions"
    ON public.user_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update their own sessions"
    ON public.user_sessions FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Allow users to delete their own sessions"
    ON public.user_sessions FOR DELETE
    USING (auth.uid() = user_id);
