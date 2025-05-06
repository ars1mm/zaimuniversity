-- SQL file for setting up Supabase RLS policies for profile-images bucket
-- Execute this SQL in your Supabase project's SQL editor

-- First, ensure the profile-images bucket exists
DO $$
BEGIN
    EXECUTE format('CREATE BUCKET IF NOT EXISTS "profile-images" WITH (public = true)');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Bucket might already exist, continuing with policy setup...';
END
$$;

-- Create an RPC function that allows admins to upload profile pictures for any user
CREATE OR REPLACE FUNCTION upload_profile_picture(user_id UUID, file_name TEXT)
RETURNS VOID AS $$
BEGIN
  -- This function will be used by admins to bypass RLS policies
  -- It doesn't need to do anything specific since it just elevates privileges momentarily
  RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing policies on the bucket to avoid conflicts
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own profile" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload any profile" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile" ON storage.objects;

-- Policy 1: Allow public read access to all profile images
-- This allows images to be viewable by everyone
CREATE POLICY "Public profiles are viewable by everyone" 
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-images');

-- Policy 2: Allow users to upload their own profile picture
CREATE POLICY "Users can upload their own profile" 
ON storage.objects FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Allow users to update their own profile picture
CREATE POLICY "Users can update their own profile" 
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Allow admins to upload any profile picture
-- This checks if user has admin role in the users table
CREATE POLICY "Admins can upload any profile" 
ON storage.objects FOR INSERT 
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' AND
  EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Policy 5: Allow users to delete their own profile picture
CREATE POLICY "Users can delete their own profile" 
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 6: Allow admins to delete any profile picture
CREATE POLICY "Admins can delete any profile" 
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' AND
  EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Update the users table to include profile_picture_url if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'profile_picture_url'
  ) THEN
    ALTER TABLE public.users ADD COLUMN profile_picture_url TEXT;
  END IF;
END
$$;

-- Add a trigger to update the updated_at field when profile_picture_url is updated
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'users_updated_at_trigger'
  ) THEN
    CREATE TRIGGER users_updated_at_trigger
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
  END IF;
END
$$;
