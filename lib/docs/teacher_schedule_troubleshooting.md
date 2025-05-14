# Teacher Schedule Troubleshooting Guide

## Common Issues and Solutions

### Issue: "My Schedule" Button in Teacher Dashboard Not Working

#### Symptoms
- Clicking the "My Schedule" button on the teacher dashboard does nothing
- You get a navigation error or an empty screen

#### Solution
1. **Check Route Configuration**
   - Ensure the `/teacher_schedule` route is properly defined in `main.dart`
   - Verify that `TeacherScheduleScreen` is imported in `main.dart`

2. **Check Role Permissions**
   - Confirm that your user account has the 'teacher' role
   - The route should allow the roles: 'teacher', 'supervisor', 'admin'

3. **Restart the Application**
   - Sometimes a full restart is required for route changes to take effect

### Issue: No Schedule Data Appears

#### Symptoms
- The schedule screen loads but shows "No classes scheduled" for all days
- The schedule screen shows a loading indicator indefinitely
- Error "Teacher profile not found" appears in logs

#### Solution
1. **Check Database Tables**
   - Verify that the `course_schedules` table exists in your Supabase database
   - Run the following SQL to create it if missing:
   ```sql
   CREATE TABLE IF NOT EXISTS course_schedules (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
     day_of_week TEXT NOT NULL,
     start_time TIME NOT NULL,
     end_time TIME NOT NULL,
     room TEXT NOT NULL,
     building TEXT,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

2. **Check Course Assignments**
   - Verify that you have courses assigned to your teacher profile
   - Run this SQL to check your course assignments:
   ```sql
   SELECT c.*
   FROM courses c
   JOIN teachers t ON c.instructor_id = t.id
   JOIN auth.users u ON t.user_id = u.id
   WHERE u.id = 'YOUR_USER_ID';
   ```

3. **Add Schedule Entries**
   - Use the "+" button in the schedule screen to add new entries
   - Ensure you're selecting valid courses that you teach

### Issue: Error When Adding Schedule Entries

#### Symptoms
- Error message appears when trying to add a new schedule entry
- The form submits but no entry appears in the schedule
- Error message `ERROR: 42703: column "user_id" does not exist`

#### Solution
1. **Fix Column References in RLS Policies**
   - If you see the error `column "user_id" does not exist`, it means the RLS policies are using the wrong column name
   - The users table uses `id` as the primary key, not `user_id`
   - Update all RLS policies as follows:
   ```sql
   ALTER TABLE course_schedules ENABLE ROW LEVEL SECURITY;

   CREATE POLICY course_schedules_select_policy ON course_schedules 
     FOR SELECT USING (auth.role() = 'authenticated');

   CREATE POLICY course_schedules_insert_policy ON course_schedules 
     FOR INSERT WITH CHECK (
       auth.uid() IN (
         SELECT id FROM users 
         WHERE role IN ('admin', 'supervisor')
       )
     );

   CREATE POLICY course_schedules_update_policy ON course_schedules 
     FOR UPDATE USING (
       auth.uid() IN (
         SELECT u.id FROM users u
         JOIN teachers t ON u.id = t.id
         JOIN courses c ON t.id = c.instructor_id
         WHERE c.id = course_schedules.course_id
         AND u.role IN ('admin', 'supervisor', 'teacher')
       )
     );

   CREATE POLICY course_schedules_delete_policy ON course_schedules 
     FOR DELETE USING (
       auth.uid() IN (
         SELECT id FROM users 
         WHERE role IN ('admin', 'supervisor')
       )
     );
   ```

2. **Log Full Error Messages**
   - Check the application logs for detailed error information
   - Temporary enable debug-level logging in the app

3. **Validate Time Format**
   - Ensure start_time is before end_time
   - Use the 24-hour format for time entries (HH:MM)

### Issue: Schedule Entries Showing for Wrong Teacher

#### Symptoms
- You see schedule entries for courses you don't teach
- Other teachers report seeing your schedule entries

#### Solution
1. **Check Query Filters**
   - Verify the TeacherScheduleService is filtering by the correct teacher ID
   - Confirm that your teacher profile is correctly linked to your user account

2. **Review Database Relationships**
   - Check that courses are properly associated with teacher IDs
   - Ensure each course has only one instructor_id assigned

3. **Update Course Assignments**
   - If needed, correct course assignments in the database:
   ```sql
   UPDATE courses
   SET instructor_id = 'CORRECT_TEACHER_ID'
   WHERE id = 'COURSE_ID';
   ```

### Issue: "Teacher profile not found" Error

#### Symptoms
- Error message "Teacher profile not found" appears in logs
- Schedule screen doesn't load or shows no data
- Error occurs when trying to fetch teacher information from database

#### Solution
1. **Check Column Reference**
   - The issue might be in the query that tries to get teacher profile information
   - In `teacher_schedule_service.dart`, check the query that fetches the teacher profile:

   **Original incorrect code**:
   ```dart
   final teacherProfileResponse = await supabase
       .from(AppConstants.tableTeachers)
       .select('id')
       .eq('user_id', user.id);  // This line has the error
   ```

   **Corrected code**:
   ```dart
   final teacherProfileResponse = await supabase
       .from(AppConstants.tableTeachers)
       .select('id')
       .eq('id', user.id);  // Changed from 'user_id' to 'id'
   ```
   
   This is because the teachers table uses the same ID as the users table, not a separate 'user_id' column.

2. **Check Database Relationships**
   - Verify that the teacher's ID in the teachers table matches their user ID in the users table
   - Make sure the correct column names are used in both queries and RLS policies

## Advanced Troubleshooting

If the above solutions don't resolve your issue, try these more advanced steps:

1. **Check Browser Console for JavaScript Errors**
   - Open developer tools (F12) and look for errors in the console
   - Note any API-related errors or authentication issues

2. **Verify Authentication Status**
   - Confirm that your authentication token is valid
   - Check that RLS policies are correctly using auth.uid() and auth.role()

3. **Database Schema Validation**
   - Run this SQL to verify foreign key relationships are intact:
   ```sql
   SELECT
     tc.table_schema, 
     tc.constraint_name, 
     tc.table_name, 
     kcu.column_name, 
     ccu.table_schema AS foreign_table_schema,
     ccu.table_name AS foreign_table_name,
     ccu.column_name AS foreign_column_name 
   FROM 
     information_schema.table_constraints AS tc 
     JOIN information_schema.key_column_usage AS kcu
       ON tc.constraint_name = kcu.constraint_name
       AND tc.table_schema = kcu.table_schema
     JOIN information_schema.constraint_column_usage AS ccu
       ON ccu.constraint_name = tc.constraint_name
       AND ccu.table_schema = tc.table_schema
   WHERE tc.constraint_type = 'FOREIGN KEY' 
   AND tc.table_name='course_schedules';
   ```

## Still Having Issues?

If you're still experiencing problems with the teacher schedule feature:

1. Log the issue in the project's issue tracker
2. Include detailed steps to reproduce the problem
3. Attach relevant error messages and screenshots
4. Note your browser/device information

## Last Updated

May 14, 2025
