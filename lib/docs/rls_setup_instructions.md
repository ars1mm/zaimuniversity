# Setting up Row-Level Security for Profile Images

This README provides instructions on how to set up the necessary Supabase Row-Level Security (RLS) policies and functions for the profile management features to work correctly.

## Required Setup Steps

1. Log in to your Supabase dashboard
2. Go to the SQL Editor
3. Execute the following SQL files in order:

### 1. Basic RLS Policies

Execute the SQL from `docs/supabase_rls_profiles.sql`

This sets up:
- The "profile-images" bucket if it doesn't exist
- Basic RLS policies for reading, writing, and deleting profile images
- A function to bypass RLS for admin operations

### 2. Admin Functions

Execute the SQL from `docs/supabase_admin_functions.sql`

This creates:
- `admin_ensure_bucket_exists`: Creates the bucket with proper permissions if it doesn't exist
- `admin_upload_profile_picture`: Allows admins to upload profile pictures with elevated privileges
- `admin_delete_profile_pictures`: Allows admins to delete profile pictures

## Troubleshooting RLS Issues

If you encounter "row-level security policy" errors:

1. Make sure you've executed both SQL files mentioned above
2. Verify that the user has the correct role in the "users" table
3. For admin operations, ensure the user's role is set to 'admin'
4. Check that you're using the correct bucket name ("profile-images")

## Common Errors and Solutions

### "Bucket not found" error:
- Execute the `admin_ensure_bucket_exists` function through RPC to create the bucket

### "Row-level security policy" error:
- Ensure the current user has appropriate permissions
- For admin operations, verify the user has the 'admin' role
- Check if the required SQL functions are properly installed

### "Object not found" error:
- Ensure the storage path format is correct (userId/fileName)
- Verify the bucket name is exactly "profile-images" (case-sensitive)

## Testing Your Setup

You can test if your RLS policies are working correctly by:

1. Logging in as a regular user and trying to upload your own profile picture (should work)
2. Logging in as a regular user and trying to upload another user's profile picture (should fail)
3. Logging in as an admin and trying to upload any user's profile picture (should work)
