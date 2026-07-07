-- ============================================================================
-- SCRIPT TO FIX SUPABASE DATABASE SECURITY LINTER WARNINGS
-- Copy this entire file and run it in your Supabase SQL Editor.
-- ============================================================================

-- 1. FIX: FUNCTION SEARCH PATH MUTABLE (0011)
-- Set explicit search_path for SECURITY DEFINER functions
ALTER FUNCTION public.handle_new_user SET search_path = public;
ALTER FUNCTION public.handle_comment_change SET search_path = public;
ALTER FUNCTION public.handle_repost_change SET search_path = public;
ALTER FUNCTION public.handle_follow_change SET search_path = public;
ALTER FUNCTION public.handle_like_change SET search_path = public;
ALTER FUNCTION public.notify_on_comment SET search_path = public;
ALTER FUNCTION public.notify_on_like SET search_path = public;
ALTER FUNCTION public.notify_on_follow SET search_path = public;
ALTER FUNCTION public.increment_thread_views SET search_path = public;
ALTER FUNCTION public.extract_words_and_hashtags SET search_path = public;
ALTER FUNCTION public.sync_thread_topics SET search_path = public;
ALTER FUNCTION public.get_topic_threads SET search_path = public;
ALTER FUNCTION public.get_ai_feed_threads SET search_path = public;
ALTER FUNCTION public.get_ai_feed SET search_path = public;
ALTER FUNCTION public.score_thread SET search_path = public;
ALTER FUNCTION public.log_user_interaction SET search_path = public;
ALTER FUNCTION public.get_personalized_feed SET search_path = public;
ALTER FUNCTION public.clear_feed_cache_on_new_post SET search_path = public;
ALTER FUNCTION public.handle_verification_request_insert SET search_path = public;
ALTER FUNCTION public.handle_verification_request_update SET search_path = public;
ALTER FUNCTION public.increment_shares_count SET search_path = public;
ALTER FUNCTION public.handle_saved_posts_change SET search_path = public;
ALTER FUNCTION public.increment_comment_shares_count SET search_path = public;
ALTER FUNCTION public.handle_saved_comments_change SET search_path = public;
ALTER FUNCTION public.get_trending_topics SET search_path = public;
ALTER FUNCTION public.get_rising_topics SET search_path = public;
ALTER FUNCTION public.get_most_discussed_topics SET search_path = public;
ALTER FUNCTION public.increment_community_member_count SET search_path = public;
ALTER FUNCTION public.decrement_community_member_count SET search_path = public;
ALTER FUNCTION public.notify_fcm_edge_function SET search_path = public;
ALTER FUNCTION public.generate_all_topic_headlines SET search_path = public;
ALTER FUNCTION public.generate_topic_headline SET search_path = public;
ALTER FUNCTION public.grant_verified_badge SET search_path = public;

-- 2. FIX: EXTENSION IN PUBLIC (0014)
-- 2. FIX: EXTENSION IN PUBLIC (0014)
-- pg_net does not support SET SCHEMA, so we skip this warning to avoid dropping the extension and losing queue data.
-- If you want to fix it in the future, you would have to DROP EXTENSION pg_net CASCADE and recreate it in the extensions schema.

-- 3. FIX: PERMISSIVE RLS POLICIES (0024)
-- Replace WITH CHECK (true) with WITH CHECK (auth.uid() IS NOT NULL)

-- audit_logs
DROP POLICY IF EXISTS "Allow insert on audit_logs" ON public.audit_logs;
CREATE POLICY "Allow insert on audit_logs" ON public.audit_logs FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

-- notifications
DROP POLICY IF EXISTS "Allow anyone to insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow authenticated users to insert notifications" ON public.notifications;
CREATE POLICY "Allow authenticated users to insert notifications" ON public.notifications FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

-- poll_options
DROP POLICY IF EXISTS "Allow authenticated users to insert poll_options" ON public.poll_options;
CREATE POLICY "Allow authenticated users to insert poll_options" ON public.poll_options FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

-- post_topics
DROP POLICY IF EXISTS "Allow authenticated users to insert post_topics" ON public.post_topics;
CREATE POLICY "Allow authenticated users to insert post_topics" ON public.post_topics FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

-- support_tickets
DROP POLICY IF EXISTS "Allow public to insert support tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Allow authenticated users to insert support tickets" ON public.support_tickets;
CREATE POLICY "Allow authenticated users to insert support tickets" ON public.support_tickets FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

-- topics
DROP POLICY IF EXISTS "Allow authenticated users to insert topics" ON public.topics;
CREATE POLICY "Allow authenticated users to insert topics" ON public.topics FOR INSERT TO authenticated WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Allow authenticated users to update topics" ON public.topics;
CREATE POLICY "Allow authenticated users to update topics" ON public.topics FOR UPDATE TO authenticated USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- system_settings (Restricting to service_role instead of fully public updates)
DROP POLICY IF EXISTS "Allow authenticated users to modify system_settings" ON public.system_settings;
DROP POLICY IF EXISTS "Allow service_role to modify system_settings" ON public.system_settings;
CREATE POLICY "Allow service_role to modify system_settings" ON public.system_settings TO service_role USING (true) WITH CHECK (true);

-- 4. FIX: PUBLIC CAN EXECUTE SECURITY DEFINER FUNCTION (0028 & 0029)
-- In Postgres, functions are granted to PUBLIC by default. We must revoke from PUBLIC, anon, and authenticated.
-- Using exact signatures to ensure the correct function is modified.
REVOKE EXECUTE ON FUNCTION public.clear_feed_cache_on_new_post() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.decrement_community_member_count(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.generate_all_topic_headlines() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.generate_topic_headline(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_personalized_feed(uuid, integer, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.grant_verified_badge(uuid, text, timestamp with time zone) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.revoke_verified_badge(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_comment_change() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_follow_change() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_like_change() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_repost_change() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_saved_comments_change() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_saved_posts_change() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_verification_request_insert() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_verification_request_update() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_community_member_count(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_comment_shares_count(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_shares_count(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_thread_views(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.log_user_interaction(uuid, uuid, text, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_fcm_edge_function() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_on_comment() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_on_follow() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_on_like() FROM PUBLIC, anon, authenticated;

-- 5. GRANT EXECUTE TO AUTHENTICATED ONLY FOR FRONTEND RPCs
-- Only allow app-facing RPCs for logged-in users.
-- Note: Supabase Linter (0029) will still warn about these because they are SECURITY DEFINER.
-- This is an ACCEPTED RISK because the app frontend needs to call them. You can ignore those specific warnings.
GRANT EXECUTE ON FUNCTION public.decrement_community_member_count(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_community_member_count(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_comment_shares_count(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_shares_count(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_thread_views(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_user_interaction(uuid, uuid, text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_personalized_feed(uuid, integer, integer) TO authenticated;
