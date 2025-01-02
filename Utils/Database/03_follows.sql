-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Follows are viewable by everyone" ON public.follows;
DROP POLICY IF EXISTS "Users can manage their own follows" ON public.follows;
DROP POLICY IF EXISTS "Users can unfollow" ON public.follows;
DROP POLICY IF EXISTS "Devices can manage their own follows" ON public.follows;

-- Drop existing table and recreate
DROP TABLE IF EXISTS public.follows CASCADE;

-- Create follows table
CREATE TABLE public.follows (
    follower_id UUID REFERENCES public.device_profiles(id) ON DELETE CASCADE,
    following_id UUID REFERENCES public.device_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);

-- Drop existing indexes if they exist
DROP INDEX IF EXISTS follows_follower_idx;
DROP INDEX IF EXISTS follows_following_idx;

-- Create indexes
CREATE INDEX follows_follower_idx ON public.follows(follower_id);
CREATE INDEX follows_following_idx ON public.follows(following_id);

-- RLS Policies
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

-- Anyone can view follows
CREATE POLICY "Follows are viewable by everyone"
ON public.follows FOR SELECT
USING (true);

-- Only the follower device can manage their follows
CREATE POLICY "Devices can manage their own follows"
ON public.follows FOR ALL
USING (follower_id::text = current_setting('app.device_id', true)); 