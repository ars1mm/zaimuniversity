# Troubleshooting Guides

This directory contains troubleshooting guides for common issues with the Istanbul Zaim University Campus Information System.

## Available Guides

- [Teacher Schedule Troubleshooting](teacher-schedule.md) - Solving issues with the teacher scheduling feature
- [Supabase Storage Troubleshooting](supabase-storage.md) - Resolving Supabase storage related problems
- [Authentication Issues](authentication.md) - Fixing login and authentication problems
- [Database Connectivity](database-connectivity.md) - Resolving database connection issues

## Common Issues

### 1. Authentication Failures

If users are experiencing authentication issues:
- Verify Supabase connection string in the environment variables
- Check user roles in the database
- Ensure proper RLS policies are in place

### 2. Missing Permissions

If users report access denied errors:
- Check the user's role in the `users` table
- Verify RLS policies for the relevant tables
- Look for error logs with permission-related messages

### 3. Data Not Displaying

If data isn't appearing as expected:
- Check network requests in browser dev tools
- Verify the query parameters being sent
- Check for errors in the response
- Ensure the user has permissions to view the data 