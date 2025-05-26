-- Fix for teachers table RLS policies
-- This fixes the issue with "new row violates row-level security policy" error (code: 42501)

-- Policy for inserting teacher records
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'teachers' AND policyname = 'teachers_insert_policy') THEN
        CREATE POLICY teachers_insert_policy ON teachers 
        FOR INSERT WITH CHECK (
            -- Only admins and supervisors can insert new teachers
            auth.role() IN ('admin', 'supervisor')
        );
    END IF;
END
$$;

-- Create a function to bypass RLS when inserting teachers (for admin use)
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

-- Log completion
DO $$
BEGIN
    RAISE NOTICE 'Teacher table RLS policy fix installed successfully';
END
$$;
