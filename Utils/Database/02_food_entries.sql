-- Run this after profiles table is created

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Food entries are viewable by everyone" ON public.food_entries;
DROP POLICY IF EXISTS "Users can insert own food entries" ON public.food_entries;
DROP POLICY IF EXISTS "Users can update own food entries" ON public.food_entries;
DROP POLICY IF EXISTS "Users can delete own food entries" ON public.food_entries;
DROP POLICY IF EXISTS "Devices can manage their own entries" ON public.food_entries;
DROP POLICY IF EXISTS "Temporary allow all operations" ON public.food_entries;

-- Drop existing table and recreate
DROP TABLE IF EXISTS public.food_entries CASCADE;

-- Creates food_entries table
CREATE TABLE public.food_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID REFERENCES public.device_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    photo_url TEXT,
    photo_storage_path TEXT,
    meal_type TEXT NOT NULL,
    ingredients JSONB,
    meal_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Drop existing indexes if they exist
DROP INDEX IF EXISTS food_entries_device_id_idx;
DROP INDEX IF EXISTS food_entries_meal_date_idx;

-- Create indexes
CREATE INDEX food_entries_device_id_idx ON public.food_entries(device_id);
CREATE INDEX food_entries_meal_date_idx ON public.food_entries(meal_date DESC);

-- Enable RLS
ALTER TABLE public.food_entries ENABLE ROW LEVEL SECURITY;

-- Create policies for different operations
CREATE POLICY "Food entries are viewable by everyone"
ON public.food_entries FOR SELECT
USING (true);

CREATE POLICY "Users can insert own food entries"
ON public.food_entries FOR INSERT
WITH CHECK (device_id = app.get_device_id());

CREATE POLICY "Users can update own food entries"
ON public.food_entries FOR UPDATE
USING (device_id = app.get_device_id());

CREATE POLICY "Users can delete own food entries"
ON public.food_entries FOR DELETE
USING (device_id = app.get_device_id()); 