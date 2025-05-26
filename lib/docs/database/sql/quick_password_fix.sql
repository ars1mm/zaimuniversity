-- Fix for password hash type issue
-- You can run this directly in the Supabase SQL editor

-- Check if column exists and is an integer
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'users'
        AND column_name = 'password_hash'
        AND data_type = 'integer'
    ) THEN
        -- Alter the column to accept string values
        ALTER TABLE users ALTER COLUMN password_hash TYPE text;
        RAISE NOTICE 'Successfully updated password_hash column from integer to text';
    ELSE
        RAISE NOTICE 'No change needed - password_hash column is already text type or does not exist';
    END IF;
END $$;

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

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_auth_user_hash(uuid) TO authenticated;
