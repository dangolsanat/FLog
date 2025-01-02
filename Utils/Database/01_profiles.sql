-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop old tables and functions if they exist
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Device Profiles table
CREATE TABLE IF NOT EXISTS public.device_profiles (
    id UUID PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Drop existing indexes if they exist
DROP INDEX IF EXISTS device_profiles_username_idx;

-- Create indexes
CREATE INDEX device_profiles_username_idx ON public.device_profiles(username);

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.device_profiles;
DROP POLICY IF EXISTS "Devices can manage their own profile" ON public.device_profiles;
DROP POLICY IF EXISTS "Temporary allow all operations" ON public.device_profiles;

-- Enable RLS but allow all operations with a single policy
ALTER TABLE public.device_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Temporary allow all operations"
ON public.device_profiles FOR ALL
USING (true); 