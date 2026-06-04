-- Supabase Schema for Dak App

CREATE TABLE profiles (
  id uuid primary key references auth.users(id),
  username text unique,
  full_name text,
  bio text,
  avatar_url text,
  cover_url text,
  followers_count int default 0,
  following_count int default 0,
  created_at timestamp default now()
);

CREATE TABLE threads (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id),
  content text,
  image_urls text[],
  likes_count int default 0,
  replies_count int default 0,
  reposts_count int default 0,
  is_quote boolean default false,
  quoted_thread_id uuid references threads(id),
  created_at timestamp default now()
);

CREATE TABLE likes (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references profiles(id),
  thread_id uuid references threads(id),
  created_at timestamp default now(),
  unique(user_id, thread_id)
);

CREATE TABLE follows (
  id uuid primary key default uuid_generate_v4(),
  follower_id uuid references profiles(id),
  following_id uuid references profiles(id),
  created_at timestamp default now(),
  unique(follower_id, following_id)
);

CREATE TABLE replies (
  id uuid primary key default uuid_generate_v4(),
  thread_id uuid references threads(id),
  user_id uuid references profiles(id),
  content text,
  image_url text,
  created_at timestamp default now()
);

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE replies ENABLE ROW LEVEL SECURITY;

-- Profiles: Public read, User can update own
CREATE POLICY "Public profiles are viewable by everyone." on profiles for select using (true);
CREATE POLICY "Users can insert their own profile." on profiles for insert with check (auth.uid() = id);
CREATE POLICY "Users can update own profile." on profiles for update using (auth.uid() = id);

-- Threads: Public read, authenticated users can insert
CREATE POLICY "Threads viewable by everyone." on threads for select using (true);
CREATE POLICY "Users can insert threads." on threads for insert with check (auth.uid() = user_id);

-- Likes: Public read, User can insert/delete own
CREATE POLICY "Likes viewable by everyone." on likes for select using (true);
CREATE POLICY "Users can insert their own likes." on likes for insert with check (auth.uid() = user_id);
CREATE POLICY "Users can delete their own likes." on likes for delete using (auth.uid() = user_id);

-- Replies: Public read, User can insert
CREATE POLICY "Replies viewable by everyone." on replies for select using (true);
CREATE POLICY "Users can insert replies." on replies for insert with check (auth.uid() = user_id);

-- Function to increment/decrement likes
create function handle_like() returns trigger as $$
begin
  update threads set likes_count = likes_count + 1 where id = new.thread_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_like
  after insert on likes
  for each row execute procedure handle_like();

create function handle_unlike() returns trigger as $$
begin
  update threads set likes_count = likes_count - 1 where id = old.thread_id;
  return old;
end;
$$ language plpgsql security definer;

create trigger on_unlike
  after delete on likes
  for each row execute procedure handle_unlike();
