# Supabase Storage Setup Guide

This document provides detailed steps for setting up and configuring storage in Supabase for the Campus Information System, specifically for handling profile pictures and other user-related media.

## Table of Contents
1. [Creating Storage Buckets](#creating-storage-buckets)
2. [Configuring Bucket Permissions](#configuring-bucket-permissions)
3. [Setting Up Row Level Security (RLS)](#setting-up-row-level-security-rls)
4. [Implementing Client-Side Upload](#implementing-client-side-upload)
5. [Handling Profile Pictures](#handling-profile-pictures)

## Creating Storage Buckets

1. **Log in to your Supabase project dashboard**
2. **Navigate to Storage** in the left sidebar
3. **Create a new bucket**:
   - Click the "New Bucket" button
   - Name it `profile_pictures`
   - Choose "Private" for bucket type (access controlled through policies)
   - Click "Create"
4. **Create additional buckets** if needed for other media types:
   - `documents` - For storing academic documents and course materials
   - `general` - For general app assets

## Configuring Bucket Permissions

### Enable Storage for Authenticated Users

1. Go to **Authentication** > **Policies** in your Supabase dashboard
2. Under **Storage**, create policies for each bucket

### Example Storage Policies for Profile Pictures

For the `profile_pictures` bucket:

1. **Create an INSERT policy**:
   - Click "New Policy" on your bucket
   - Policy name: `Allow users to upload their own profile pictures`
   - Allow operation: `INSERT`
   - Policy definition (SQL):
   ```sql
   (auth.uid()::text = (storage.foldername(name))[1])
   ```
   - This allows users to only upload to folders matching their user ID

2. **Create a SELECT policy**:
   - Policy name: `Allow users to view profile pictures`
   - Allow operation: `SELECT`
   - Policy definition (SQL):
   ```sql
   (bucket_id = 'profile_pictures'::text)
   ```
   - Makes profile pictures readable by anyone

3. **Create an UPDATE policy**:
   - Policy name: `Allow users to update their own profile pictures`
   - Allow operation: `UPDATE` 
   - Policy definition (SQL):
   ```sql
   (auth.uid()::text = (storage.foldername(name))[1])
   ```

4. **Create a DELETE policy**:
   - Policy name: `Allow users to delete their own profile pictures`
   - Allow operation: `DELETE`
   - Policy definition (SQL):
   ```sql
   (auth.uid()::text = (storage.foldername(name))[1])
   ```

## Setting Up Row Level Security (RLS)

To link profile pictures to user records, you'll need to update your users table and implement RLS policies:

```sql
-- Add profile_picture_url column to users table if not already present
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;

-- Create or update RLS policy for the users table
CREATE POLICY update_own_profile_picture ON users 
FOR UPDATE TO authenticated 
USING (auth.uid()::text = id::text)
WITH CHECK (auth.uid()::text = id::text);

-- Enable RLS on the users table if not already enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

## Implementing Client-Side Upload

### File Structure for Storage

Organize uploads in a hierarchy:
- `profile_pictures/{user_id}/{file_name}`

This ensures proper isolation of user data and simplifies permission management.

### Flutter Implementation for Profile Picture Upload

Add the following code to your profile management functionality:

```dart
Future<String?> uploadProfilePicture(File imageFile) async {
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = '$userId/$fileName';
    
    // Upload file to Supabase Storage
    final response = await supabase
        .storage
        .from('profile_pictures')
        .upload(filePath, imageFile);
    
    // Get public URL for the uploaded image
    final imageUrlResponse = supabase
        .storage
        .from('profile_pictures')
        .getPublicUrl(filePath);
    
    // Update the user's profile with the new image URL
    await supabase
        .from('users')
        .update({'profile_picture_url': imageUrlResponse})
        .eq('id', userId);
    
    return imageUrlResponse;
  } catch (e) {
    print('Error uploading profile picture: $e');
    return null;
  }
}
```

## Handling Profile Pictures

### Loading Profile Pictures in UI

When displaying profile pictures:

1. Check if `profile_picture_url` is available in the user record
2. If available, use widgets like `CircleAvatar` with `NetworkImage`
3. Provide a fallback to display the user's initials when no image is available

Example widget implementation:

```dart
CircleAvatar(
  radius: 30,
  backgroundColor: primaryColor,
  backgroundImage: profilePictureUrl != null
      ? NetworkImage(profilePictureUrl)
      : null,
  child: profilePictureUrl == null
      ? Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
      : null,
)
```

### Handling Image Loading Failures

Add error handling for image loading:

```dart
Image.network(
  profilePictureUrl,
  errorBuilder: (context, error, stackTrace) {
    return Text(userName[0].toUpperCase());
  },
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator();
  },
)
```

---

For more information about Supabase Storage, refer to the [official documentation](https://supabase.com/docs/guides/storage).
