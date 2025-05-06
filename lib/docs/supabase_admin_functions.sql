-- SQL file for setting up a server-side function to create the profile-images bucket
-- This SQL needs to be executed in your Supabase SQL Editor to create the necessary
-- stored procedures that bypass RLS for admin operations.

-- Function to ensure the profile-images bucket exists with proper permissions
-- This function can be called from Flutter with RPC
CREATE OR REPLACE FUNCTION admin_ensure_bucket_exists(bucket_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  bucket_exists BOOLEAN;
BEGIN
  -- Check if the user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users u 
    JOIN public.users pu ON u.id = pu.id 
    WHERE u.id = auth.uid() AND pu.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Permission denied: Only admins can create buckets';
  END IF;

  -- Check if bucket exists
  SELECT EXISTS (
    SELECT 1 FROM storage.buckets 
    WHERE name = bucket_name
  ) INTO bucket_exists;

  -- Create the bucket if it doesn't exist
  IF NOT bucket_exists THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES (bucket_name, bucket_name, true);
    
    -- Add default RLS policies for the new bucket
    -- Allow everyone to read
    EXECUTE format('
      CREATE POLICY "Public bucket read access" 
      ON storage.objects FOR SELECT 
      USING (bucket_id = %L)', bucket_name);
      
    -- Allow authenticated users to upload to their own folder
    EXECUTE format('
      CREATE POLICY "Users can upload to own folder" 
      ON storage.objects FOR INSERT TO authenticated 
      WITH CHECK (bucket_id = %L AND (storage.foldername(name))[1] = auth.uid()::text)', 
      bucket_name);
      
    -- Allow admins to upload to any folder
    EXECUTE format('
      CREATE POLICY "Admins can upload to any folder" 
      ON storage.objects FOR INSERT TO authenticated 
      WITH CHECK (
        bucket_id = %L AND EXISTS (
          SELECT 1 FROM public.users 
          WHERE id = auth.uid() AND role = ''admin''
        )
      )', bucket_name);
      
    RETURN true;
  END IF;

  RETURN bucket_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function that will handle profile picture uploads with elevated permissions
CREATE OR REPLACE FUNCTION admin_upload_profile_picture(
  user_id UUID, 
  file_path TEXT, 
  file_content BYTEA,
  content_type TEXT DEFAULT 'image/jpeg'
)
RETURNS TEXT AS $$
DECLARE
  bucket_name TEXT := 'profile-images';
  file_url TEXT;
BEGIN
  -- Check if the user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users u 
    JOIN public.users pu ON u.id = pu.id 
    WHERE u.id = auth.uid() AND pu.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Permission denied: Only admins can perform this operation';
  END IF;
  
  -- Ensure bucket exists
  PERFORM admin_ensure_bucket_exists(bucket_name);
  
  -- Upload the file to storage
  INSERT INTO storage.objects (bucket_id, name, owner, size, mime_type, content)
  VALUES (bucket_name, file_path, auth.uid(), octet_length(file_content), content_type, file_content);
  
  -- Get the public URL
  file_url := storage.url(bucket_name, file_path);
  
  -- Update the user record with the new profile picture URL
  UPDATE public.users 
  SET 
    profile_picture_url = file_url,
    updated_at = NOW()
  WHERE id = user_id;
  
  RETURN file_url;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to delete all profile pictures for a user
CREATE OR REPLACE FUNCTION admin_delete_profile_pictures(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  bucket_name TEXT := 'profile-images';
  folder_path TEXT;
BEGIN
  -- Check if the user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM auth.users u 
    JOIN public.users pu ON u.id = pu.id 
    WHERE u.id = auth.uid() AND pu.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Permission denied: Only admins can delete other user files';
  END IF;
  
  folder_path := user_id::TEXT || '/';
  
  -- Delete all objects in the user's folder
  DELETE FROM storage.objects 
  WHERE bucket_id = bucket_name AND name LIKE folder_path || '%';
  
  -- Update the user record to clear the profile picture URL
  UPDATE public.users 
  SET 
    profile_picture_url = NULL,
    updated_at = NOW()
  WHERE id = user_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
