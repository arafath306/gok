-- ============================================================================
-- DAK SOCIAL NETWORK - MISSING RLS POLICIES MIGRATION
-- Run this in your Supabase SQL Editor to resolve RLS Enabled No Policy warnings.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Table: conversations
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view conversations they participate in" ON public.conversations;
CREATE POLICY "Users can view conversations they participate in"
    ON public.conversations FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants 
            WHERE conversation_id = conversations.id 
              AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
CREATE POLICY "Users can create conversations"
    ON public.conversations FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update conversations" ON public.conversations;
CREATE POLICY "Users can update conversations"
    ON public.conversations FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants 
            WHERE conversation_id = conversations.id 
              AND user_id = auth.uid()
        )
    );

-- ----------------------------------------------------------------------------
-- 2. Table: conversation_participants
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view participants of their conversations" ON public.conversation_participants;
CREATE POLICY "Users can view participants of their conversations"
    ON public.conversation_participants FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = conversation_participants.conversation_id 
              AND cp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can add themselves to conversations" ON public.conversation_participants;
CREATE POLICY "Users can add themselves to conversations"
    ON public.conversation_participants FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can leave conversations" ON public.conversation_participants;
CREATE POLICY "Users can leave conversations"
    ON public.conversation_participants FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 3. Table: creator_settings
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Allow authenticated read of creator settings" ON public.creator_settings;
CREATE POLICY "Allow authenticated read of creator settings"
    ON public.creator_settings FOR SELECT
    TO authenticated
    USING (is_active = true);

DROP POLICY IF EXISTS "Creators can manage own settings" ON public.creator_settings;
CREATE POLICY "Creators can manage own settings"
    ON public.creator_settings FOR ALL
    TO authenticated
    USING (auth.uid() = creator_id)
    WITH CHECK (auth.uid() = creator_id);

-- ----------------------------------------------------------------------------
-- 4. Table: creator_subscriptions
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON public.creator_subscriptions;
CREATE POLICY "Users can view their own subscriptions"
    ON public.creator_subscriptions FOR SELECT
    TO authenticated
    USING (auth.uid() = subscriber_id OR auth.uid() = creator_id);

DROP POLICY IF EXISTS "Users can insert their own subscriptions" ON public.creator_subscriptions;
CREATE POLICY "Users can insert their own subscriptions"
    ON public.creator_subscriptions FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = subscriber_id);

DROP POLICY IF EXISTS "Users can update their own subscriptions" ON public.creator_subscriptions;
CREATE POLICY "Users can update their own subscriptions"
    ON public.creator_subscriptions FOR UPDATE
    TO authenticated
    USING (auth.uid() = subscriber_id OR auth.uid() = creator_id);

-- ----------------------------------------------------------------------------
-- 5. Table: user_feed_cache
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own feed cache" ON public.user_feed_cache;
CREATE POLICY "Users can view their own feed cache"
    ON public.user_feed_cache FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage their own feed cache" ON public.user_feed_cache;
CREATE POLICY "Users can manage their own feed cache"
    ON public.user_feed_cache FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 6. Table: user_interactions
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view their own interactions" ON public.user_interactions;
CREATE POLICY "Users can view their own interactions"
    ON public.user_interactions FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can log their own interactions" ON public.user_interactions;
CREATE POLICY "Users can log their own interactions"
    ON public.user_interactions FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 7. Table: verification_plans
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Allow read of verification plans" ON public.verification_plans;
CREATE POLICY "Allow read of verification plans"
    ON public.verification_plans FOR SELECT
    USING (true); -- Publicly viewable for everyone (even non-logged-in visitors)
