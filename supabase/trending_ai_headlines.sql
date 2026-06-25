-- ============================================================================
-- DAK SOCIAL NETWORK: AI-POWERED TRENDING TOPICS HEADLINES & CONTEXT
-- Execute this script in your Supabase SQL Editor to set up the AI-powered
-- topic headlines and descriptions.
-- ============================================================================

-- 1. Alter public.topics table to add AI context columns
ALTER TABLE public.topics 
ADD COLUMN IF NOT EXISTS headline TEXT,
ADD COLUMN IF NOT EXISTS summary TEXT,
ADD COLUMN IF NOT EXISTS summary_updated_at TIMESTAMP WITH TIME ZONE;

-- 2. Enable HTTP extension (Christian Katsma pgsql-http) in extensions schema
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- 3. Define function to generate headline & summary for a single topic using OpenRouter
CREATE OR REPLACE FUNCTION public.generate_topic_headline(target_topic_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  topic_name_val TEXT;
  posts_context TEXT;
  payload JSONB;
  models TEXT[] := ARRAY['openai/gpt-oss-120b:free', 'openai/gpt-oss-20b:free', 'google/gemma-4-31b-it:free'];
  model_name TEXT;
  http_status INT;
  response_content TEXT;
  response_json JSONB;
  content_text TEXT;
  inner_json JSONB;
  headline_val TEXT;
  summary_val TEXT;
  success BOOLEAN := false;
BEGIN
  -- Get the topic name
  SELECT name INTO topic_name_val FROM public.topics WHERE id = target_topic_id;
  IF topic_name_val IS NULL THEN
    RETURN false;
  END IF;

  -- Compile recent posts context (last 10 posts)
  SELECT string_agg(row_num || '. ' || left(th.content, 200), E'\n') INTO posts_context
  FROM (
    SELECT th.content, row_number() OVER (ORDER BY th.created_at DESC) as row_num
    FROM public.threads th
    JOIN public.post_topics pt ON pt.thread_id = th.id
    WHERE pt.topic_id = target_topic_id
    ORDER BY th.created_at DESC
    LIMIT 10
  ) th;

  -- If no posts, we can't generate context
  IF posts_context IS NULL OR posts_context = '' THEN
    RETURN false;
  END IF;

  -- Try models in order
  FOREACH model_name IN ARRAY models LOOP
    BEGIN
      -- Construct payload with the current model
      payload := jsonb_build_object(
        'model', model_name,
        'messages', jsonb_build_array(
          jsonb_build_object(
            'role', 'system',
            'content', 'You are a professional social media trending topic analyzer. Analyze the recent posts for the keyword and write: 1) A short catchy headline (max 8 words) summarizing the main news/event. 2) A brief description/context (max 15 words) of what people are discussing. If the posts are primarily in Bengali, write the headline and summary in Bengali. If the posts are primarily in English, write in English. Match the tone and language of the posts. Response must be strictly JSON with keys "headline" and "summary". Do not output markdown, HTML, backticks, or any text other than the JSON object.'
          ),
          jsonb_build_object(
            'role', 'user',
            'content', 'Topic: #' || topic_name_val || E'\n\nRecent posts:\n' || posts_context
          )
        ),
        'response_format', jsonb_build_object('type', 'json_object')
      );

      -- Send HTTP Request to OpenRouter
      SELECT status, content INTO http_status, response_content 
      FROM http((
        'POST',
        'https://openrouter.ai/api/v1/chat/completions',
        ARRAY[
          http_header('Authorization', 'Bearer ' || coalesce(current_setting('app.settings.openrouter_api_key', true), 'YOUR_OPENROUTER_API_KEY')),
          http_header('Content-Type', 'application/json'),
          http_header('HTTP-Referer', 'https://pigeon.social'),
          http_header('X-Title', 'Pigeon App')
        ],
        'application/json',
        payload::text
      )::http_request);

      -- Parse response if HTTP 200 OK
      IF http_status = 200 THEN
        response_json := response_content::jsonb;
        content_text := response_json->'choices'->0->'message'->>'content';
        
        -- Clean markdown code blocks if the model returned them
        content_text := regexp_replace(content_text, '^```(json)?', '', 'i');
        content_text := regexp_replace(content_text, '```$', '', 'i');
        content_text := trim(content_text);

        BEGIN
          inner_json := content_text::jsonb;
          headline_val := trim(inner_json->>'headline');
          summary_val := trim(inner_json->>'summary');

          IF headline_val IS NOT NULL AND headline_val != '' AND summary_val IS NOT NULL AND summary_val != '' THEN
            UPDATE public.topics
            SET headline = headline_val,
                summary = summary_val,
                summary_updated_at = now()
            WHERE id = target_topic_id;
            
            success := true;
            EXIT; -- Exit the model loop on success
          END IF;
        EXCEPTION WHEN OTHERS THEN
          -- Fallback on parsing error
        END;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- Fallback on request or other error
    END;
  END LOOP;

  RETURN success;
END;
$$;

-- 4. Define function to refresh all active topic headlines (trending, rising, discussed)
CREATE OR REPLACE FUNCTION public.generate_all_topic_headlines()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  r RECORD;
BEGIN
  -- Iterate through unique top active topics that haven't been updated in the last 30 minutes
  FOR r IN 
    SELECT DISTINCT t.id, t.name
    FROM (
      SELECT topic_name FROM public.get_trending_topics(15)
      UNION
      SELECT topic_name FROM public.get_rising_topics(3, 15)
      UNION
      SELECT topic_name FROM public.get_most_discussed_topics(15)
    ) active_topics
    JOIN public.topics t ON t.name = active_topics.topic_name
    WHERE t.summary_updated_at IS NULL OR t.summary_updated_at < now() - INTERVAL '30 minutes'
  LOOP
    PERFORM public.generate_topic_headline(r.id);
  END LOOP;
END;
$$;

-- Drop existing RPC functions first to allow changing their return types (since signature OUT columns changed)
DROP FUNCTION IF EXISTS public.get_trending_topics(integer);
DROP FUNCTION IF EXISTS public.get_rising_topics(integer, integer);
DROP FUNCTION IF EXISTS public.get_most_discussed_topics(integer);

-- 5. Redefine Dynamic Trending score function to include headline & summary
CREATE OR REPLACE FUNCTION public.get_trending_topics(limit_val INT DEFAULT 10)
RETURNS TABLE(
  topic_name TEXT,
  post_count BIGINT,
  engagement_count BIGINT,
  headline TEXT,
  summary TEXT
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
    (stats.mentions_count * 1 + stats.likes_count * 1 + stats.comments_count * 3 + stats.reposts_count * 5 + stats.bookmarks_count * 2) as engagement_count,
    t.headline,
    t.summary
  FROM topic_stats stats
  JOIN public.topics t ON t.id = stats.topic_id
  ORDER BY engagement_count DESC
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;

-- 6. Redefine Dynamic Rising score function to include headline & summary
CREATE OR REPLACE FUNCTION public.get_rising_topics(min_mentions INT DEFAULT 3, limit_val INT DEFAULT 10)
RETURNS TABLE(
  topic_name TEXT,
  post_count BIGINT,
  growth_percentage NUMERIC,
  headline TEXT,
  summary TEXT
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
    ) as growth_percentage,
    t.headline,
    t.summary
  FROM today_stats today
  LEFT JOIN yesterday_stats yesterday ON today.topic_id = yesterday.topic_id
  JOIN public.topics t ON t.id = today.topic_id
  WHERE today.mentions >= min_mentions
  ORDER BY growth_percentage DESC
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;

-- 7. Redefine Dynamic Most Discussed function to include headline & summary
CREATE OR REPLACE FUNCTION public.get_most_discussed_topics(limit_val INT DEFAULT 10)
RETURNS TABLE(
  topic_name TEXT,
  post_count BIGINT,
  discussion_count BIGINT,
  headline TEXT,
  summary TEXT
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
    (stats.comments_count + stats.quotes_count) as discussion_count,
    t.headline,
    t.summary
  FROM discussion_stats stats
  JOIN public.topics t ON t.id = stats.topic_id
  ORDER BY discussion_count DESC
  LIMIT limit_val;
END;
$$ LANGUAGE plpgsql;

-- 8. Add a trigger to refresh topic headlines on insert of active posts (throttled)
-- Rather than synchronous trigger call which blocks insertion, scheduling via pg_cron is recommended.
--
-- INSTRUCTIONS TO SCHEDULE WITH pg_cron IN SUPABASE SQL EDITOR:
-- Run this block once in your Supabase dashboard:
-- 
-- SELECT cron.schedule(
--   'refresh-ai-topic-headlines',
--   '*/30 * * * *',  -- every 30 minutes
--   $$ SELECT public.generate_all_topic_headlines(); $$
-- );
--
-- Alternatively, the admin panel or backend worker can periodically call public.generate_all_topic_headlines().
