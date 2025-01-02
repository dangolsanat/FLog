-- Drop ALL existing policies for storage
DROP POLICY IF EXISTS "Anyone can upload photos" ON storage.objects;
DROP POLICY IF EXISTS "Food photos are viewable by everyone" ON storage.objects;
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload food images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own food images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own food images" ON storage.objects;

-- Create bucket for food photos
INSERT INTO storage.buckets (id, name)
VALUES ('food-images', 'food-images')
ON CONFLICT DO NOTHING;

-- Storage policies
CREATE POLICY "Food photos are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'food-images');

-- Simpler policy without device_id check for now
CREATE POLICY "Anyone can upload photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'food-images'); 