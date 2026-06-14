-- 1. Create avatars and covers storage buckets in Supabase
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('covers', 'covers', true)
on conflict (id) do nothing;

-- 2. Drop existing policies if they already exist to avoid errors
drop policy if exists "Allow public read access to avatars and covers" on storage.objects;
drop policy if exists "Allow authenticated uploads to avatars and covers" on storage.objects;
drop policy if exists "Allow authenticated updates in avatars and covers" on storage.objects;
drop policy if exists "Allow authenticated deletes from avatars and covers" on storage.objects;

-- 3. Create RLS policies for storage objects

-- Policy: Allow public read access to avatars and covers
create policy "Allow public read access to avatars and covers"
on storage.objects for select
using ( bucket_id in ('avatars', 'covers') );

-- Policy: Allow authenticated users to upload files to avatars and covers
create policy "Allow authenticated uploads to avatars and covers"
on storage.objects for insert
with check (
  bucket_id in ('avatars', 'covers')
  and auth.role() = 'authenticated'
);

-- Policy: Allow authenticated users to update their files
create policy "Allow authenticated updates in avatars and covers"
on storage.objects for update
using (
  bucket_id in ('avatars', 'covers')
  and auth.role() = 'authenticated'
)
with check (
  bucket_id in ('avatars', 'covers')
  and auth.role() = 'authenticated'
);

-- Policy: Allow authenticated users to delete their files
create policy "Allow authenticated deletes from avatars and covers"
on storage.objects for delete
using (
  bucket_id in ('avatars', 'covers')
  and auth.role() = 'authenticated'
);
