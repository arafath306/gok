-- ============================================================================
-- PIAGOAN - STORAGE BUCKET SETUP
-- Run this in the Supabase SQL Editor to set up the storage bucket.
--
-- All images (profile avatars, cover photos, and thread post images) are
-- stored in a single 'avatars' bucket using path prefixes:
--   - avatars/{uid}/img_*.jpg   -> Profile avatar photos
--   - covers/{uid}/img_*.jpg    -> Cover/banner photos
--   - posts/{uid}/thread_*.jpg  -> Thread post images
-- ============================================================================

-- 1. Create the single 'avatars' bucket (public so URLs are accessible)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- NOTE: The 'covers' bucket is no longer needed. All uploads go through
-- the 'avatars' bucket with folder prefixes. You can safely delete the
-- 'covers' bucket from Supabase Storage if it exists.

-- 2. Drop existing policies to avoid conflicts on re-run
drop policy if exists "Allow public read access on avatars" on storage.objects;
drop policy if exists "Allow authenticated uploads to avatars" on storage.objects;
drop policy if exists "Allow authenticated updates in avatars" on storage.objects;
drop policy if exists "Allow authenticated deletes from avatars" on storage.objects;
-- Legacy policies (if created previously)
drop policy if exists "Allow public read access to avatars and covers" on storage.objects;
drop policy if exists "Allow authenticated uploads to avatars and covers" on storage.objects;
drop policy if exists "Allow authenticated updates in avatars and covers" on storage.objects;
drop policy if exists "Allow authenticated deletes from avatars and covers" on storage.objects;

-- 3. Create RLS policies for the avatars bucket

-- Policy: Allow public read (anyone can view images)
create policy "Allow public read access on avatars"
on storage.objects for select
using ( bucket_id = 'avatars' );

-- Policy: Allow authenticated users to upload files
create policy "Allow authenticated uploads to avatars"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'avatars' );

-- Policy: Allow authenticated users to update (overwrite) their files
create policy "Allow authenticated updates in avatars"
on storage.objects for update
to authenticated
using ( bucket_id = 'avatars' )
with check ( bucket_id = 'avatars' );

-- Policy: Allow authenticated users to delete their files
create policy "Allow authenticated deletes from avatars"
on storage.objects for delete
to authenticated
using ( bucket_id = 'avatars' );
