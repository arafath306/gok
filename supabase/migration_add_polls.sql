-- 1. Add poll expiration column to threads table
ALTER TABLE public.threads ADD COLUMN IF NOT EXISTS poll_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- 2. Create poll_options table
CREATE TABLE IF NOT EXISTS public.poll_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES public.threads(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create poll_votes table
CREATE TABLE IF NOT EXISTS public.poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_option_id UUID NOT NULL REFERENCES public.poll_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    thread_id UUID NOT NULL REFERENCES public.threads(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, thread_id) -- Prevent voting more than once per thread
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

-- 5. Add RLS Policies for poll_options
DROP POLICY IF EXISTS "Allow public read access to poll options" ON public.poll_options;
CREATE POLICY "Allow public read access to poll options" ON public.poll_options
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow users to create poll options for their threads" ON public.poll_options;
CREATE POLICY "Allow users to create poll options for their threads" ON public.poll_options
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.threads
            WHERE id = thread_id AND user_id = auth.uid()
        )
    );

-- 6. Add RLS Policies for poll_votes
DROP POLICY IF EXISTS "Allow public read access to poll votes" ON public.poll_votes;
CREATE POLICY "Allow public read access to poll votes" ON public.poll_votes
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to vote" ON public.poll_votes;
CREATE POLICY "Allow authenticated users to vote" ON public.poll_votes
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
    );

DROP POLICY IF EXISTS "Allow users to delete their own votes" ON public.poll_votes;
CREATE POLICY "Allow users to delete their own votes" ON public.poll_votes
    FOR DELETE USING (
        auth.uid() = user_id
    );

-- 7. Enable Realtime Replication for these tables
-- Clean up any existing replication settings if already in the publication
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'poll_options'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.poll_options;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'poll_votes'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.poll_votes;
    END IF;
END $$;
