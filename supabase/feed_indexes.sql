-- ============================================================================
-- DAK SOCIAL NETWORK - HIGH PERFORMANCE INDEXES FOR AI FEED
-- Run this script in your Supabase SQL Editor.
-- These indexes are CRITICAL for the get_personalized_feed() algorithm to scale
-- to 10k+ users without causing 100% CPU usage or full table scans.
-- ============================================================================

-- 1. Index on threads.created_at (DESC)
-- Reason: The AI feed algorithm always filters by `created_at > (now() - INTERVAL '7 days')`
-- Without this, Supabase will scan every single post ever made just to find the recent ones.
CREATE INDEX IF NOT EXISTS idx_threads_created_at_desc ON public.threads (created_at DESC);

-- 2. Index on threads.category
-- Reason: The algorithm joins on user_interactions and matches categories.
CREATE INDEX IF NOT EXISTS idx_threads_category ON public.threads (category);

-- 3. Index on threads.user_id
-- Reason: The algorithm constantly filters out blocked/muted users and the user's own posts (user_id != p_user_id).
CREATE INDEX IF NOT EXISTS idx_threads_user_id ON public.threads (user_id);

-- 4. Index on follows (follower_id & following_id)
-- Reason: Used to check relationship pool (t.user_id IN (SELECT following_id FROM follows...))
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows (follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows (following_id);

-- 5. Index on blocks (blocker_id & blocked_id)
-- Reason: Used in the excluded_users CTE.
CREATE INDEX IF NOT EXISTS idx_blocks_blocker_id ON public.blocks (blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocks_blocked_id ON public.blocks (blocked_id);

-- 6. Index on mutes (muter_id & muted_id)
-- Reason: Used in the excluded_users CTE.
CREATE INDEX IF NOT EXISTS idx_mutes_muter_id ON public.mutes (muter_id);
CREATE INDEX IF NOT EXISTS idx_mutes_muted_id ON public.mutes (muted_id);

-- 7. Index on thread_hides and reports
-- Reason: Used to filter out hidden and reported threads.
CREATE INDEX IF NOT EXISTS idx_thread_hides_user_id ON public.thread_hides (user_id);
CREATE INDEX IF NOT EXISTS idx_reports_user_id_thread_id ON public.reports (user_id, thread_id);

-- 8. Index on user_feed_cache
-- Reason: Allows instant feed fetching on subsequent pagination loads.
CREATE INDEX IF NOT EXISTS idx_feed_cache_user_score ON public.user_feed_cache (user_id, score DESC);

-- 9. Index on user_interactions (for the 7 days weight recalculation)
CREATE INDEX IF NOT EXISTS idx_interactions_user_created ON public.user_interactions (user_id, created_at DESC);
