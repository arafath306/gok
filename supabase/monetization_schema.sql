-- 1. Add Monetization Access to Profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS can_monetize BOOLEAN DEFAULT false NOT NULL;

-- 2. Ensure system_settings table exists and add global toggle
CREATE TABLE IF NOT EXISTS public.system_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
ALTER TABLE public.system_settings DISABLE ROW LEVEL SECURITY;

INSERT INTO public.system_settings (key, value) 
VALUES ('enable_monetization', 'false') 
ON CONFLICT (key) DO NOTHING;

-- 3. Create creator_settings table
CREATE TABLE IF NOT EXISTS public.creator_settings (
    creator_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    monthly_price NUMERIC DEFAULT 0 NOT NULL,
    welcome_message TEXT,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE public.creator_settings DISABLE ROW LEVEL SECURITY;

-- 4. Create creator_subscriptions table
CREATE TABLE IF NOT EXISTS public.creator_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscriber_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    bkash_sender TEXT,
    bkash_trx_id TEXT,
    status TEXT DEFAULT 'pending' NOT NULL, -- 'pending', 'active', 'rejected', 'expired'
    plan_price NUMERIC DEFAULT 0 NOT NULL,
    starts_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE public.creator_subscriptions DISABLE ROW LEVEL SECURITY;

-- Subscriptions should be unique for a given subscriber-creator pair if they are 'active' or 'pending'
CREATE UNIQUE INDEX IF NOT EXISTS unique_active_pending_sub 
ON public.creator_subscriptions (subscriber_id, creator_id) 
WHERE status IN ('active', 'pending');
