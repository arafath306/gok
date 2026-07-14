-- ============================================================================
-- DAK SOCIAL NETWORK - SECURITY & LINTER FIXED MIGRATION
-- Copy and run this script in your Supabase SQL Editor (https://database.supabase.com)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FIX: FUNCTION SEARCH PATH MUTABLE (0011)
-- Set explicit search_path for functions to prevent search path hijacking.
-- ----------------------------------------------------------------------------
ALTER FUNCTION public.notify_fcm_edge_function() SET search_path = public, pg_temp;
ALTER FUNCTION public.decrement_community_member_count(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.get_personalized_feed(uuid, integer, integer) SET search_path = public, pg_temp;
ALTER FUNCTION public.increment_comment_shares_count(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.increment_community_member_count(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.increment_shares_count(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.increment_thread_views(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.log_user_interaction(uuid, uuid, text, integer) SET search_path = public, pg_temp;

-- ----------------------------------------------------------------------------
-- 2. FIX: EXTENSION IN PUBLIC (0014)
-- pg_net in this version does not support SET SCHEMA, so we skip this warning
-- to avoid dropping the extension and losing queue/trigger data.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 3. FIX: PERMISSIVE RLS POLICY ON moderator_keys (0024)
-- Drop the unrestricted public policy and restrict it to authenticated Admins only.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Allow anon all operations" ON public.moderator_keys;

-- Create secure policy for managing keys (only profiles with role = 'Admin' can modify)
CREATE POLICY "Allow admin manage moderator keys"
    ON public.moderator_keys FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
              AND profiles.role = 'Admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
              AND profiles.role = 'Admin'
        )
    );

-- ----------------------------------------------------------------------------
-- 4. FIX: PUBLIC STORAGE BUCKET ALLOWS LISTING (0025)
-- Restrict SELECT policy on public buckets so clients cannot list all files.
-- Public downloads via getPublicUrl bypass SELECT RLS, so this will NOT break images.
-- ----------------------------------------------------------------------------

-- A. avatars bucket
DROP POLICY IF EXISTS "Allow public read access on avatars" ON storage.objects;
CREATE POLICY "Allow public read access on avatars"
    ON storage.objects FOR SELECT
    TO authenticated
    USING ( bucket_id = 'avatars' );

-- B. thread-audios bucket
DROP POLICY IF EXISTS "Public Access for thread audios" ON storage.objects;
CREATE POLICY "Public Access for thread audios"
    ON storage.objects FOR SELECT
    TO authenticated
    USING ( bucket_id = 'thread-audios' );

-- ----------------------------------------------------------------------------
-- 5. FIX: SECURING SECURITY DEFINER FUNCTIONS (0029)
-- Revoke execution from public/anonymous roles to ensure only logged-in users 
-- can call the REST RPC endpoints.
-- ----------------------------------------------------------------------------

-- Revoke default public execution
REVOKE EXECUTE ON FUNCTION public.decrement_community_member_count(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_community_member_count(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_comment_shares_count(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_shares_count(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_thread_views(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.log_user_interaction(uuid, uuid, text, integer) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_personalized_feed(uuid, integer, integer) FROM PUBLIC, anon, authenticated;

-- Grant execution explicitly to authenticated users (and service_role)
GRANT EXECUTE ON FUNCTION public.decrement_community_member_count(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.increment_community_member_count(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.increment_comment_shares_count(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.increment_shares_count(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.increment_thread_views(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.log_user_interaction(uuid, uuid, text, integer) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_personalized_feed(uuid, integer, integer) TO authenticated, service_role;
