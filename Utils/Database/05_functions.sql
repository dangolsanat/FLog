-- Run last: Creates functions and triggers
-- Must run after tables exist since triggers reference them

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS handle_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS handle_updated_at ON public.food_entries;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.handle_updated_at();

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for updated_at
CREATE TRIGGER handle_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at
    BEFORE UPDATE ON public.food_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Function to get feed for a device
CREATE OR REPLACE FUNCTION get_device_feed(device_id UUID)
RETURNS TABLE (
    id UUID,
    device_id UUID,
    title TEXT,
    description TEXT,
    photo_url TEXT,
    meal_type TEXT,
    ingredients JSONB,
    meal_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    username TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fe.id,
        fe.device_id,
        fe.title,
        fe.description,
        fe.photo_url,
        fe.meal_type,
        fe.ingredients,
        fe.meal_date,
        fe.created_at,
        dp.username
    FROM public.food_entries fe
    JOIN public.device_profiles dp ON fe.device_id = dp.id
    WHERE fe.device_id = device_id
    ORDER BY fe.meal_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 