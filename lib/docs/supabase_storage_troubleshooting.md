# Supabase Storage Troubleshooting Guide

## Common Error: Missing `admin_ensure_bucket_exists` Function

### Error Description

If you encounter the following error when working with Supabase Storage in the application:

```
PostgrestException(message: Could not find the function public.admin_ensure_bucket_exists(bucket_name) in the schema cache, code: PGRST202, details: Searched for the function public.admin_ensure_bucket_exists with parameter bucket_name or with a single unnamed json/jsonb parameter, but no matches were found in the schema cache., hint: null)
```

This occurs when your Supabase instance is missing the RPC function required for bucket management in storage.

### Solution 1: Create the RPC Function in Supabase

1. **Log into your Supabase dashboard** at [https://app.supabase.com/](https://app.supabase.com/)

2. **Navigate to the SQL Editor**:
   - Click on the "SQL Editor" tab in the left sidebar
   - Create a new query

3. **Execute the following SQL**:

```sql
-- Function to ensure a storage bucket exists
CREATE OR REPLACE FUNCTION admin_ensure_bucket_exists(bucket_name TEXT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO storage.buckets (id, name)
  VALUES (bucket_name, bucket_name)
  ON CONFLICT (id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant access to authenticated users
GRANT EXECUTE ON FUNCTION admin_ensure_bucket_exists(TEXT) TO authenticated;
```

4. **Run the query** and verify that it executes without errors

5. **Restart your application** to verify the issue is resolved

### Solution 2: Code-based Workaround

If you don't have access to modify the Supabase database directly, you can implement a workaround in your code:

```dart
Future<void> createBucketIfNotExists(String bucketName) async {
  try {
    // Try to get bucket info first
    await supabase.storage.getBucket(bucketName);
    print('Bucket $bucketName exists');
  } catch (error) {
    // Bucket doesn't exist, try to create it
    try {
      await supabase.storage.createBucket(bucketName, {
        'public': false,  // Adjust bucket privacy as needed
      });
      print('Created bucket $bucketName');
    } catch (e) {
      // Handle creation error
      // Note: If multiple requests try to create the same bucket simultaneously,
      // this might throw an error that can be safely ignored
      print('Error creating bucket: $e');
    }
  }
}
```

Call this function before attempting to upload files to a bucket:

```dart
// Example usage
await createBucketIfNotExists('profile_pictures');
await supabase.storage.from('profile_pictures').upload(...);
```

### Prevention

To prevent this issue in future deployments:

1. **Include the required SQL function** in your database migration scripts
2. **Document the required Supabase setup** in your deployment guidelines
3. **Add error handling** in your storage service layer to handle missing buckets gracefully

## Related Issues

This error commonly occurs in the following scenarios:

- First-time setup of the application with a new Supabase instance
- When upgrading from an older version of Supabase
- When deploying to a new environment

## Last Updated

May 14, 2025
