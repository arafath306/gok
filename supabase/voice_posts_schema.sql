-- Add audio_url column to threads table
ALTER TABLE public.threads
ADD COLUMN IF NOT EXISTS audio_url TEXT;

-- Create thread-audios bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('thread-audios', 'thread-audios', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for thread-audios bucket
DROP POLICY IF EXISTS "Public Access for thread audios" ON storage.objects;
CREATE POLICY "Public Access for thread audios" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'thread-audios');

DROP POLICY IF EXISTS "Authenticated users can upload thread audios" ON storage.objects;
CREATE POLICY "Authenticated users can upload thread audios" 
ON storage.objects FOR INSERT 
WITH CHECK (
    bucket_id = 'thread-audios' 
    AND auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can delete their own thread audios" ON storage.objects;
CREATE POLICY "Users can delete their own thread audios" 
ON storage.objects FOR DELETE 
USING (
    bucket_id = 'thread-audios' 
    AND auth.uid() = owner
);

-- Note: The feature flag 'enable_voice_posts' can be added in the dak-admin-next panel.
