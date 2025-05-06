-- Supabase Storage Setup SQL Queries
-- This file contains all SQL queries needed to set up storage and related RLS policies

-- 1. Add profile picture URL column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;

-- 2. Create trigger function to handle profile picture updates
CREATE OR REPLACE FUNCTION handle_profile_picture_update()
RETURNS TRIGGER AS $$
BEGIN
  -- If a profile picture is deleted, update the user record
  IF OLD.profile_picture_url IS NOT NULL AND NEW.profile_picture_url IS NULL THEN
    -- Could add logic to delete the file from storage here if needed
    RETURN NEW;
  END IF;
  
  -- If a new profile picture is uploaded, update the user record
  IF NEW.profile_picture_url <> OLD.profile_picture_url THEN
    -- Validate that the URL points to a file in the right bucket
    IF NEW.profile_picture_url NOT LIKE '%/storage/v1/object/public/profile_pictures/%' THEN
      RAISE EXCEPTION 'Profile picture must be stored in the profile_pictures bucket';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create trigger on users table for profile picture updates
DROP TRIGGER IF EXISTS on_profile_picture_update ON users;
CREATE TRIGGER on_profile_picture_update
  BEFORE UPDATE OF profile_picture_url ON users
  FOR EACH ROW
  EXECUTE FUNCTION handle_profile_picture_update();

-- 4. Create function to handle user deletion (cleanup their storage)
CREATE OR REPLACE FUNCTION delete_user_storage()
RETURNS TRIGGER AS $$
DECLARE
  user_id TEXT := OLD.id::TEXT;
BEGIN
  -- This function will be called via a trigger when a user is deleted
  -- It should clean up all files in storage owned by the user
  -- Note: In practice, you would integrate with the storage API or use a stored procedure
  -- that can make API calls to delete the files

  -- For audit purposes, log the deletion
  INSERT INTO deletion_logs (entity_type, entity_id, deleted_at, deleted_by)
  VALUES ('user_storage', user_id, now(), auth.uid());
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create trigger for cleaning up user storage on deletion
DROP TRIGGER IF EXISTS on_user_delete_cleanup_storage ON users;
CREATE TRIGGER on_user_delete_cleanup_storage
  AFTER DELETE ON users
  FOR EACH ROW
  EXECUTE FUNCTION delete_user_storage();

-- 6. Create an audit table for storage operations
CREATE TABLE IF NOT EXISTS storage_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  operation TEXT NOT NULL,
  bucket_id TEXT NOT NULL,
  object_path TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. Create RLS policies for storage_audit_log
ALTER TABLE storage_audit_log ENABLE ROW LEVEL SECURITY;

-- Only allow admins to view the audit logs
CREATE POLICY admin_view_storage_audit ON storage_audit_log
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- 8. Create function to log storage operations
CREATE OR REPLACE FUNCTION log_storage_operation()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO storage_audit_log (user_id, operation, bucket_id, object_path)
  VALUES (
    auth.uid(),
    TG_OP,
    NEW.bucket_id,
    NEW.name
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create bucket-specific RLS policies

-- Profile Pictures Bucket Policies
-- Allow users to insert only into their own folder
CREATE POLICY insert_own_profile_pictures ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'profile_pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow users to update only their own images
CREATE POLICY update_own_profile_pictures ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'profile_pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
  )
  WITH CHECK (
    bucket_id = 'profile_pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow users to delete only their own images
CREATE POLICY delete_own_profile_pictures ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'profile_pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Allow everyone to view profile pictures
CREATE POLICY view_profile_pictures ON storage.objects
  FOR SELECT
  USING (bucket_id = 'profile_pictures');

-- 10. Helper function for creating a new user with profile picture
CREATE OR REPLACE FUNCTION create_user_with_profile(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_role TEXT DEFAULT 'student',
  p_profile_picture_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Create the auth user
  v_user_id := (SELECT id FROM auth.users WHERE email = p_email);
  
  IF v_user_id IS NULL THEN
    v_user_id := extensions.uuid_generate_v4();
    
    -- Insert into auth.users table (this is a simplified example)
    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, role)
    VALUES (v_user_id, p_email, crypt(p_password, gen_salt('bf')), now(), p_role);
  END IF;
  
  -- Create or update the user profile
  INSERT INTO users (id, email, full_name, role, profile_picture_url)
  VALUES (v_user_id, p_email, p_full_name, p_role, p_profile_picture_url)
  ON CONFLICT (id) DO UPDATE
  SET
    full_name = p_full_name,
    role = p_role,
    profile_picture_url = COALESCE(p_profile_picture_url, users.profile_picture_url);
    
  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Helper function to get a signed URL for private file access
CREATE OR REPLACE FUNCTION get_private_file_url(
  bucket_name TEXT,
  file_path TEXT,
  expiry INTEGER DEFAULT 60 -- Default expiry time in seconds
)
RETURNS TEXT AS $$
DECLARE
  signed_url TEXT;
BEGIN
  -- This is a placeholder function that would be implemented using
  -- extensions or custom server-side logic to generate a signed URL
  -- through Supabase's storage API
  
  -- In an actual implementation, you would call the Supabase storage API
  -- to generate a signed URL with the proper expiration
  
  RETURN format('https://your-project-ref.supabase.co/storage/v1/object/sign/public/%s/%s?expiry=%s', 
    bucket_name, file_path, expiry);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
