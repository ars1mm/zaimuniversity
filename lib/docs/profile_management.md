# Profile Management Screen Documentation

## Overview

The Profile Management Screen is designed to allow users to manage user profiles in the Zaim University CIS system. The screen follows Supabase Row-Level Security (RLS) policies to ensure proper access control for user data and profile images.

## Features

- View list of users with basic information (admin only)
- Search users by name, email, or role
- View detailed user information in a modal
- Upload and change user profile pictures
- Respects Supabase RLS policies for secure access control

## User Interface

The screen is divided into two main sections:
1. **Search bar**: Allows filtering users by name, email, or role
2. **User list**: Displays user cards with profile image, name, email, and role badge

When a user card is tapped, a detail modal appears with:
- Enlarged profile picture
- Complete user information
- Option to change the profile picture

## Row Level Security (RLS) Implementation

The profile management system uses Supabase's RLS policies to control access to user data and profile images:

### Storage Bucket Policies

The `profile-images` bucket has the following RLS policies:

1. **Public Read Access**: Anyone can view profile images
2. **Self-Upload**: Users can upload images to their own folder in the bucket
3. **Self-Update**: Users can update their own profile images
4. **Admin Upload**: Admins can upload images for any user
5. **Self-Delete**: Users can delete their own profile images
6. **Admin Delete**: Admins can delete any profile image

### Database RLS Policies

The user table has corresponding RLS policies:

1. **Self-Read**: Users can read their own profile data
2. **Admin-Read**: Admins can read all user profiles
3. **Self-Update**: Users can update certain fields of their own profile
4. **Admin-Update**: Admins can update any user profile

## Implementation Details

### Profile Images Storage

- Profile images are stored in the `profile-images` bucket
- Each user has a folder named with their user ID
- Images are stored with a timestamped filename to prevent caching issues
- The database stores the public URL to the image

### Special Considerations

- When an admin uploads a profile picture for another user, an RPC function (`upload_profile_picture`) is used to bypass RLS temporarily
- The system cleans up old profile images when a new one is uploaded to avoid storage clutter
- Image dimensions and quality are optimized before upload to reduce storage usage

## SQL Setup

The SQL setup for RLS policies is available in `lib/docs/supabase_rls_profiles.sql` and should be executed in the Supabase SQL editor to configure the proper security policies.
