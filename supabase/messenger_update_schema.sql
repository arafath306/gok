-- Advanced Messaging Schema Update
-- Adds support for reactions, read receipts, and message editing.

ALTER TABLE messages
ADD COLUMN IF NOT EXISTS reactions jsonb DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS read_by uuid[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS edited_at timestamptz;

-- Also ensure we have indexes for performance if we start doing heavy queries
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- In case we want to support pinning or archiving chats, we need a chat metadata table
-- Since Pigeon uses a direct message structure, we can store chat preferences per user
CREATE TABLE IF NOT EXISTS chat_preferences (
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    other_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    is_pinned boolean DEFAULT false,
    is_archived boolean DEFAULT false,
    is_muted boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    PRIMARY KEY (user_id, other_user_id)
);

ALTER TABLE chat_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own chat preferences"
    ON chat_preferences FOR ALL
    USING (auth.uid() = user_id);
