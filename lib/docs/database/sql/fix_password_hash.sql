-- Function to fix the password hash issue

-- First, update the users table to ensure password_hash accepts string values
CREATE OR REPLACE FUNCTION fix_password_hash_type()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if the column exists and is an integer
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'password_hash'
        AND data_type = 'integer'
    ) THEN
        -- Alter the column to accept string values
        ALTER TABLE users ALTER COLUMN password_hash TYPE text;
    END IF;
END;
$$;

-- Update the get_auth_user_hash function to ensure it returns text
-- First drop the existing function
DROP FUNCTION IF EXISTS get_auth_user_hash(uuid);

-- Now recreate the function with the correct return type
CREATE FUNCTION get_auth_user_hash(user_id uuid)
RETURNS TABLE(id uuid, encrypted_password text)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT au.id, au.encrypted_password::text
    FROM auth.users au
    WHERE au.id = user_id;
END;
$$;

-- Grant access to the function
GRANT EXECUTE ON FUNCTION get_auth_user_hash(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION fix_password_hash_type() TO authenticated;
