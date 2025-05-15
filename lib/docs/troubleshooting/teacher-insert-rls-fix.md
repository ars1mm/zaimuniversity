# Teachers Table RLS Policy Fix

## Issue

The application was encountering a PostgreSQL error when trying to add a new teacher:
```
PostgrestException(message: new row violates row-level security policy for table "teachers", code: 42501)
```

This error occurred in the `add_teacher_screen.dart` file when trying to insert a new record into the `teachers` table.

## Root Cause

After analysis, we found that:

1. The teachers table had Row Level Security (RLS) enabled
2. There were policies for SELECT, UPDATE, and DELETE operations
3. However, there was no policy for INSERT operations
4. Even though the admin was authenticated, they couldn't insert new records due to the missing policy

## Fix

The solution involved two parts:

### 1. Database Changes

Created a new policy to allow admins and supervisors to insert teachers:

```sql
CREATE POLICY teachers_insert_policy ON teachers 
FOR INSERT WITH CHECK (
    -- Only admins and supervisors can insert new teachers
    auth.role() IN ('admin', 'supervisor')
);
```

Additionally, created a secure function to bypass RLS when needed:

```sql
CREATE OR REPLACE FUNCTION admin_insert_teacher(
    teacher_id UUID,
    department_id UUID,
    specialization TEXT,
    bio TEXT, 
    status TEXT,
    contact_info JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if the user is an admin
    IF NOT EXISTS (
        SELECT 1 FROM auth.users u 
        JOIN public.users pu ON u.id = pu.id 
        WHERE u.id = auth.uid() AND pu.role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Permission denied: Only admins can insert teachers';
    END IF;

    -- Insert the teacher record bypassing RLS
    INSERT INTO teachers (id, department_id, specialization, bio, status, contact_info)
    VALUES (teacher_id, department_id, specialization, bio, status, contact_info);

    RETURN teacher_id;
END;
$$;
```

### 2. Application Changes

Modified `add_teacher_screen.dart` to use the new RPC function instead of direct insertion:

```dart
// Now create the teacher record with admin privileges by using the admin_insert_teacher RPC function
final contactInfo = {
  'email': _emailController.text,
  'phone': _phoneController.text,
};

// Call the admin function that bypasses RLS
await supabase.rpc('admin_insert_teacher', params: {
  'teacher_id': userId,
  'department_id': _departmentController.text,
  'specialization': _specializationController.text,
  'bio': _bioController.text,
  'status': _selectedStatus,
  'contact_info': contactInfo
});
```

## Deployment

Run the `deploy_teachers_rls_fix.ps1` script to deploy this fix:

```powershell
./deploy_teachers_rls_fix.ps1
```

## Similar Issues

This fix follows the pattern used for other RLS policy issues in the application. Similar issues could exist in other tables if they have RLS enabled but are missing the appropriate policies for all operations (SELECT, INSERT, UPDATE, DELETE).

## Date Fixed

May 15, 2025
