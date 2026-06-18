-- Create topics table
CREATE TABLE IF NOT EXISTS public.topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create post_topics junction table
CREATE TABLE IF NOT EXISTS public.post_topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID REFERENCES public.threads(id) ON DELETE CASCADE NOT NULL,
    topic_id UUID REFERENCES public.topics(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_post_topic UNIQUE (thread_id, topic_id)
);

-- Function to extract alphanumeric words and hashtags from text
CREATE OR REPLACE FUNCTION public.extract_words_and_hashtags(content TEXT)
RETURNS TEXT[] AS $$
DECLARE
  words TEXT[];
  clean_words TEXT[] := '{}';
  w TEXT;
  clean_w TEXT;
  stop_words TEXT[] := ARRAY[
    'ami', 'tumi', 'ebong', 'kintu', 'holo', 'ache', 'chilo', 'hobe', 'is', 'the', 'and', 'are', 'that', 'this', 'for', 'you', 'with', 'have', 'was', 'were', 'not', 'but', 'আমি', 'তুমি', 'এবং', 'কিন্তু', 'হলো', 'আছে', 'ছিল', 'হবে', 'একটা', 'করে', 'করা', 'হয়ে', 'থেকে', 'দিয়ে', 'জন্য', 'সাথে', 'নিয়ে', 'করেছে', 'হচ্ছে', 'হবে', 'এখানে', 'কোনো', 'টাকা', 'আজকে', 'আজ', 'কাল', 'গতকাল', 'নিয়ে', 'থেকে', 'এবং', 'কিন্তু', 'অথবা'
  ];
BEGIN
  IF content IS NULL THEN
    RETURN '{}';
  END IF;

  -- Split by non-alphanumeric/non-hashtag characters
  words := regexp_split_to_array(lower(content), '[^a-z0-9#\u0980-\u09FF]+');
  
  FOREACH w IN ARRAY words LOOP
    -- Trim typical punctuation
    clean_w := trim(w, '.,!?;:"''()[]{}#');
    
    -- If it was a hashtag, prepend '#'
    IF left(w, 1) = '#' THEN
      clean_w := '#' || clean_w;
    END IF;
    
    -- Ignore empty strings, stop words, or short words (except hashtags)
    IF clean_w != '' AND NOT (clean_w = ANY(stop_words)) THEN
      IF (left(clean_w, 1) = '#' AND length(clean_w) >= 2) OR (length(clean_w) >= 3) THEN
        -- Basic group merging for common synonyms
        IF clean_w = 'ai' OR clean_w = 'a.i.' OR clean_w = 'artificial intelligence' THEN
          clean_w := 'ai';
        ELSIF clean_w = 'flutterdev' OR clean_w = 'flutter' THEN
          clean_w := 'flutter';
        END IF;
        clean_words := array_append(clean_words, clean_w);
      END IF;
    END IF;
  END LOOP;
  
  RETURN ARRAY(SELECT DISTINCT unnest(clean_words));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Trigger function to synchronize thread content with topics
CREATE OR REPLACE FUNCTION public.sync_thread_topics()
RETURNS TRIGGER AS $$
DECLARE
  extracted_topics TEXT[];
  t_name TEXT;
  t_id UUID;
BEGIN
  -- Delete old mentions if updating
  IF TG_OP = 'UPDATE' THEN
    DELETE FROM public.post_topics WHERE thread_id = OLD.id;
  END IF;

  -- Extract keywords/hashtags
  extracted_topics := public.extract_words_and_hashtags(NEW.content);

  -- Insert and map each topic
  FOREACH t_name IN ARRAY extracted_topics LOOP
    -- Insert into topics table if it doesn't exist
    INSERT INTO public.topics (name)
    VALUES (t_name)
    ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
    RETURNING id INTO t_id;

    -- Insert relation
    INSERT INTO public.post_topics (thread_id, topic_id, user_id, created_at)
    VALUES (NEW.id, t_id, NEW.user_id, NEW.created_at)
    ON CONFLICT (thread_id, topic_id) DO NOTHING;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger registration
CREATE OR REPLACE TRIGGER on_thread_topics_sync
AFTER INSERT OR UPDATE ON public.threads
FOR EACH ROW EXECUTE FUNCTION public.sync_thread_topics();

-- Dynamic Trending score function (last 24 hours score calculation)
CREATE OR REPLACE FUNCTION public.get_trending_topics(limit_val INT DEFAULT 10)
RETURNS TABLE(
  topic_name TEXT,
  post_count BIGINT,
  engagement_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH recent_mentions AS (
    -- Filter max 3 posts per user per topic in last 24h to prevent spam bots
    SELECT pt.topic_id, pt.thread_id, pt.user_id
    FROM (
      SELECT id, topic_id, thread_id, user_id,
             row_number() OVER (PARTITION BY topic_id, user_id ORDER BY created_at DESC) as rank
      FROM public.post_topics
      WHERE created_at >= now() - INTERVAL '24 hours'
    ) pt
    WHERE pt.rank <= 3
  ),
  topic_stats AS (
    SELECT 
      rm.topic_id,
      count(DISTINCT rm.thread_id) as mentions_count,
      -- Count likes on these threads in last 24h
      (SELECT count(*) FROM public.likes l WHERE l.thread_id IN (SELECT rm2.thread_id FROM recent_mentions rm2 WHERE rm2.topic_id = rm.topic_id) AND l.created_at >= now() - INTERVAL '24 hours') as likes_count,
      -- Count comments on these threads in last 24h
      (SELECT count(*) FROM public.comments c WHERE c.thread_id IN (SELECT rm2.thread_id FROM recent_mentions rm2 WHERE rm2.topic_id = rm.topic_id) AND c.created_at >= now() - INTERVAL '24 hours') as comments_count,
      -- Count reposts/shares on these threads in last 24h
      (SELECT count(*) FROM public.reposts r WHERE r.thread_id IN (SELECT rm2.thread_id FROM recent_mentions rm2 WHERE rm2.topic_id = rm.topic_id) AND r.created_at >= now() - INTERVAL '24 hours') as reposts_count,
      -- Count bookmarks (saved_posts) on these threads in last 24h
      (SELECT count(*) FROM public.saved_posts sp WHERE sp.thread_id IN (SELECT rm2.thread_id FROM recent_mentions rm2 WHERE rm2.topic_id = rm.topic_id) AND sp.created_at >= now() - INTERVAL '24 hours') as bookmarks_count
    FROM recent_mentions rm
    GROUP BY rm.topic_id
  )
  SELECT 
    t.name as topic_name,
    stats.mentions_count as post_count,
    (stats.mentions_count * 1 + stats.likes_count * 1 + stats.comments_count * 3 + stats.reposts_count * 5 + stats.bookmarks_count * 2) as engagement_count
  FROM topic_stats stats
  JOIN public.topics t ON t.id = stats.topic_id
  ORDER BY engagement_count DESC
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;

-- Dynamic Rising score function (Growth rate comparison)
CREATE OR REPLACE FUNCTION public.get_rising_topics(min_mentions INT DEFAULT 3, limit_val INT DEFAULT 10)
RETURNS TABLE(
  topic_name TEXT,
  post_count BIGINT,
  growth_percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH today_stats AS (
    SELECT topic_id, count(DISTINCT thread_id) as mentions
    FROM public.post_topics
    WHERE created_at >= now() - INTERVAL '24 hours'
    GROUP BY topic_id
  ),
  yesterday_stats AS (
    SELECT topic_id, count(DISTINCT thread_id) as mentions
    FROM public.post_topics
    WHERE created_at >= now() - INTERVAL '48 hours' AND created_at < now() - INTERVAL '24 hours'
    GROUP BY topic_id
  )
  SELECT 
    t.name as topic_name,
    today.mentions as post_count,
    round(
      ( (today.mentions::numeric - COALESCE(yesterday.mentions, 1)::numeric) / COALESCE(yesterday.mentions, 1)::numeric ) * 100, 
      2
    ) as growth_percentage
  FROM today_stats today
  LEFT JOIN yesterday_stats yesterday ON today.topic_id = yesterday.topic_id
  JOIN public.topics t ON t.id = today.topic_id
  WHERE today.mentions >= min_mentions
  ORDER BY growth_percentage DESC
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;

-- Dynamic Most Discussed function
CREATE OR REPLACE FUNCTION public.get_most_discussed_topics(limit_val INT DEFAULT 10)
RETURNS TABLE(
  topic_name TEXT,
  post_count BIGINT,
  discussion_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH topic_threads_list AS (
    SELECT topic_id, thread_id
    FROM public.post_topics
    WHERE created_at >= now() - INTERVAL '24 hours'
  ),
  discussion_stats AS (
    SELECT 
      ttl.topic_id,
      count(DISTINCT ttl.thread_id) as mentions_count,
      -- Count comments/replies
      (SELECT count(*) FROM public.comments c WHERE c.thread_id IN (SELECT ttl2.thread_id FROM topic_threads_list ttl2 WHERE ttl2.topic_id = ttl.topic_id)) as comments_count,
      -- Count quote posts (reposts with quote text)
      (SELECT count(*) FROM public.reposts r WHERE r.thread_id IN (SELECT ttl2.thread_id FROM topic_threads_list ttl2 WHERE ttl2.topic_id = ttl.topic_id) AND r.quote_text IS NOT NULL AND r.quote_text != '') as quotes_count
    FROM topic_threads_list ttl
    GROUP BY ttl.topic_id
  )
  SELECT 
    t.name as topic_name,
    stats.mentions_count as post_count,
    (stats.comments_count + stats.quotes_count) as discussion_count
  FROM discussion_stats stats
  JOIN public.topics t ON t.id = stats.topic_id
  ORDER BY discussion_count DESC
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;

-- Get posts belonging to a topic
CREATE OR REPLACE FUNCTION public.get_topic_threads(topic_name TEXT)
RETURNS TABLE(
  id UUID,
  user_id UUID,
  content TEXT,
  image_urls TEXT[],
  video_url TEXT,
  likes_count INTEGER,
  replies_count INTEGER,
  reposts_count INTEGER,
  views_count INTEGER,
  is_pinned BOOLEAN,
  mute_notifications BOOLEAN,
  hide_from_profile BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    th.id,
    th.user_id,
    th.content,
    th.image_urls,
    th.video_url,
    th.likes_count,
    th.replies_count,
    th.reposts_count,
    th.views_count,
    th.is_pinned,
    th.mute_notifications,
    th.hide_from_profile,
    th.created_at
  FROM public.threads th
  JOIN public.post_topics pt ON pt.thread_id = th.id
  JOIN public.topics t ON t.id = pt.topic_id
  WHERE t.name = lower(topic_name)
  ORDER BY (th.likes_count * 1 + th.replies_count * 3 + th.reposts_count * 5) DESC;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS
ALTER TABLE public.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_topics ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow public read access to topics" ON public.topics;
DROP POLICY IF EXISTS "Allow public read access to post_topics" ON public.post_topics;
DROP POLICY IF EXISTS "Allow authenticated users to insert post_topics" ON public.post_topics;

-- Add policies
CREATE POLICY "Allow public read access to topics" ON public.topics
  FOR SELECT USING (true);

CREATE POLICY "Allow public read access to post_topics" ON public.post_topics
  FOR SELECT USING (true);

CREATE POLICY "Allow authenticated users to insert post_topics" ON public.post_topics
  FOR INSERT WITH CHECK (true);

-- Backfill existing threads manually
DO $$
DECLARE
  r RECORD;
  extracted_topics TEXT[];
  t_name TEXT;
  t_id UUID;
BEGIN
  FOR r IN SELECT * FROM public.threads LOOP
    extracted_topics := public.extract_words_and_hashtags(r.content);
    FOREACH t_name IN ARRAY extracted_topics LOOP
      INSERT INTO public.topics (name)
      VALUES (t_name)
      ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
      RETURNING id INTO t_id;

      INSERT INTO public.post_topics (thread_id, topic_id, user_id, created_at)
      VALUES (r.id, t_id, r.user_id, r.created_at)
      ON CONFLICT (thread_id, topic_id) DO NOTHING;
    END LOOP;
  END LOOP;
END;
$$;
