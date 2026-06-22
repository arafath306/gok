-- Create verification_plans table to hold dynamic pricing for badges
CREATE TABLE IF NOT EXISTS public.verification_plans (
    id TEXT PRIMARY KEY, -- 'weekly', 'monthly', 'yearly', 'lifetime'
    name TEXT NOT NULL,
    price NUMERIC NOT NULL,
    discount_price NUMERIC, -- Store discount numeric price if any, otherwise NULL
    interval_unit TEXT NOT NULL, -- 'week', 'month', 'year', 'lifetime'
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Seed default plans
INSERT INTO public.verification_plans (id, name, price, discount_price, interval_unit)
VALUES
('weekly', 'Weekly Plan', 59, NULL, 'week'),
('monthly', 'Monthly Plan', 199, NULL, 'month'),
('yearly', 'Yearly Plan', 1999, NULL, 'year'),
('lifetime', 'Lifetime Plan', 4999, NULL, 'lifetime')
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    price = EXCLUDED.price,
    discount_price = EXCLUDED.discount_price,
    interval_unit = EXCLUDED.interval_unit;

-- Disable RLS for ease of integration (similar to other setup files in this project)
ALTER TABLE public.verification_plans DISABLE ROW LEVEL SECURITY;

-- Add plan_id column to verification_requests table
ALTER TABLE public.verification_requests ADD COLUMN IF NOT EXISTS plan_id TEXT DEFAULT 'monthly';
