-- Drop the table entirely to wipe out any incorrect columns or bad foreign keys
DROP TABLE IF EXISTS public.poll_votes CASCADE;

-- Recreate the table with the EXACT correct schema
CREATE TABLE public.poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_option_id UUID NOT NULL REFERENCES public.poll_options(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    thread_id UUID NOT NULL REFERENCES public.threads(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, thread_id)
);

-- Enable RLS
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

-- Create Policies
CREATE POLICY "Allow public read access to poll votes" ON public.poll_votes
FOR SELECT USING (true);

CREATE POLICY "Allow authenticated users to vote" ON public.poll_votes
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to delete their own votes" ON public.poll_votes
FOR DELETE USING (auth.uid() = user_id);

-- Force Supabase to reload the schema cache immediately!
NOTIFY pgrst, 'reload schema';
