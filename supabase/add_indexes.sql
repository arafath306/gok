-- ============================================================================
-- DAK SOCIAL NETWORK - DATABASE INDEXES FOR PERFORMANCE OPTIMIZATION
-- Execute this script in your Supabase project's SQL Editor.
-- ============================================================================

-- 1. THREADS (POSTS) TABLE
-- Optimizes loading a specific user's posts
CREATE INDEX IF NOT EXISTS idx_threads_user_id ON public.threads(user_id);
-- Optimizes sorting feeds by newest (used in global feeds and pagination)
CREATE INDEX IF NOT EXISTS idx_threads_created_at ON public.threads(created_at DESC);

-- 2. LIKES (REACTIONS) TABLE
-- Optimizes counting likes and fetching users who liked a post
CREATE INDEX IF NOT EXISTS idx_likes_thread_id ON public.likes(thread_id);
-- Optimizes finding posts a specific user liked
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes(user_id);

-- 3. COMMENTS (REPLIES) TABLE
-- Optimizes fetching all comments for a specific post
CREATE INDEX IF NOT EXISTS idx_comments_thread_id ON public.comments(thread_id);
-- Optimizes loading nested replies for a specific comment
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON public.comments(parent_id);
-- Optimizes fetching all comments made by a specific user
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON public.comments(user_id);
-- Optimizes sorting comments by newest
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON public.comments(created_at ASC);

-- 4. COMMENT LIKES TABLE
CREATE INDEX IF NOT EXISTS idx_comment_likes_comment_id ON public.comment_likes(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_likes_user_id ON public.comment_likes(user_id);

-- 5. FOLLOWS RELATIONSHIP TABLE
-- Optimizes fetching who a user is following
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows(follower_id);
-- Optimizes fetching a user's followers
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);

-- 6. MESSAGES (DM CHAT) TABLE
-- Optimizes loading chat history for the sender
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
-- Optimizes loading chat history for the receiver
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
-- Optimizes sorting chats chronologically
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);

-- 7. NOTIFICATIONS TABLE
-- Optimizes loading a user's notification feed
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
-- Optimizes sorting notifications by newest
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
-- Optimizes filtering out unread notifications quickly
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read) WHERE is_read = false;

-- 8. REPORTS TABLE
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON public.reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);

-- 9. MUTES & BLOCKS TABLES
CREATE INDEX IF NOT EXISTS idx_blocks_blocker_id ON public.blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_mutes_muter_id ON public.mutes(muter_id);

-- 10. REPOSTS TABLE
CREATE INDEX IF NOT EXISTS idx_reposts_thread_id ON public.reposts(thread_id);
CREATE INDEX IF NOT EXISTS idx_reposts_user_id ON public.reposts(user_id);

-- 11. THREAD HIDES TABLE
CREATE INDEX IF NOT EXISTS idx_thread_hides_user_id ON public.thread_hides(user_id);
