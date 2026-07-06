-- Allow community moderators and owners to delete any thread in their community
DROP POLICY IF EXISTS "Moderators can delete threads" ON public.threads;

CREATE POLICY "Moderators can delete threads"
ON public.threads
FOR DELETE
USING (
    EXISTS (
        SELECT 1 
        FROM public.community_members m
        WHERE m.community_id = threads.community_id
          AND m.user_id = auth.uid()
          AND m.role IN ('owner', 'moderator')
    )
);

-- Note: The existing policy "Users can delete their own threads" still applies to normal members deleting their own posts.
