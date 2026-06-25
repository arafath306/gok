-- ============================================================================
-- Admin Manual Badge Grant Function
-- Run this in Supabase SQL Editor.
-- This creates a SECURITY DEFINER function that bypasses RLS,
-- allowing the admin panel to grant/revoke badges on any profile.
-- ============================================================================

-- Function: grant_verified_badge
-- Grants a verified badge to a user with a specified plan and expiry.
CREATE OR REPLACE FUNCTION public.grant_verified_badge(
  target_user_id UUID,
  plan_id TEXT,
  expires_at TIMESTAMP WITH TIME ZONE
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET
    is_verified = true,
    verified_plan_id = plan_id,
    verified_expires_at = expires_at
  WHERE id = target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found: %', target_user_id;
  END IF;
END;
$$;

-- Function: revoke_verified_badge
-- Revokes a verified badge from a user.
CREATE OR REPLACE FUNCTION public.revoke_verified_badge(
  target_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET
    is_verified = false,
    verified_plan_id = NULL,
    verified_expires_at = NULL
  WHERE id = target_user_id;
END;
$$;

-- Grant execute permission to anon and authenticated roles
-- so the admin panel (using anon key) can call these functions.
GRANT EXECUTE ON FUNCTION public.grant_verified_badge(UUID, TEXT, TIMESTAMP WITH TIME ZONE) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.revoke_verified_badge(UUID) TO anon, authenticated;
