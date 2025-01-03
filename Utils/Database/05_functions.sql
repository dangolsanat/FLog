-- Run last: Creates functions and triggers
-- Must run after tables exist since triggers reference them

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS handle_updated_at ON public.device_profiles;
DROP TRIGGER IF EXISTS handle_updated_at ON public.food_entries;

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS public.handle_updated_at();
DROP FUNCTION IF EXISTS public.get_device_feed(UUID);
DROP FUNCTION IF EXISTS public.get_device_feed(TEXT);
DROP FUNCTION IF EXISTS public.get_device_feed(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.get_device_feed(UUID, TEXT);

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
    BEFORE UPDATE ON public.device_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_updated_at
    BEFORE UPDATE ON public.food_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Function to get feed for a device
CREATE OR REPLACE FUNCTION get_device_feed(target_device_id UUID, search_query TEXT DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    device_id UUID,
    title TEXT,
    description TEXT,
    photo_url TEXT,
    meal_type TEXT,
    ingredients TEXT[],
    created_at TIMESTAMPTZ,
    meal_date TIMESTAMPTZ
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
        COALESCE(
            CASE 
                WHEN fe.ingredients IS NULL OR fe.ingredients = 'null'::jsonb OR fe.ingredients = '[]'::jsonb 
                THEN ARRAY[]::TEXT[]
                ELSE ARRAY(SELECT * FROM jsonb_array_elements_text(fe.ingredients))
            END,
            ARRAY[]::TEXT[]
        ),
        fe.created_at,
        fe.meal_date
    FROM food_entries fe
    WHERE fe.device_id = target_device_id
    AND (
        search_query IS NULL
        OR fe.title ILIKE '%' || search_query || '%'
        OR fe.description ILIKE '%' || search_query || '%'
        OR fe.ingredients::text ILIKE '%' || search_query || '%'
    )
    ORDER BY fe.meal_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Create app schema
CREATE SCHEMA IF NOT EXISTS app;

-- Create get_device_id function
CREATE OR REPLACE FUNCTION app.get_device_id()
RETURNS UUID
LANGUAGE SQL STABLE
AS $$
  SELECT COALESCE(
    current_setting('request.headers')::json->>'x-device-id',
    NULL
  )::UUID;
$$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA app TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_device_feed(UUID, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION app.get_device_id() TO anon, authenticated, service_role;
GRANT SELECT ON public.food_entries TO anon, authenticated, service_role; 