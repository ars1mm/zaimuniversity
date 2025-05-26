-- Safe course announcements migration script
-- This script adds course_id to announcements table and updates functions
-- Run this in your Supabase SQL editor

-- Step 1: Add course_id field to announcements table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'announcements' AND column_name = 'course_id'
    ) THEN
        ALTER TABLE announcements 
        ADD COLUMN course_id UUID REFERENCES courses(id);
    END IF;
END $$;

-- Step 2: Create index for course_id
CREATE INDEX IF NOT EXISTS announcements_course_id_idx ON announcements(course_id);

-- Step 3: Drop existing policies and functions
DROP POLICY IF EXISTS users_view_announcements ON announcements;
DROP FUNCTION IF EXISTS create_announcement;
DROP FUNCTION IF EXISTS update_announcement;

-- Step 4: Create updated create_announcement function that supports course_id
CREATE OR REPLACE FUNCTION create_announcement(
    p_title TEXT,
    p_content TEXT,
    p_department_id UUID,
    p_course_id UUID DEFAULT NULL,
    p_target_roles TEXT[] DEFAULT '{student,teacher,supervisor,admin}'::TEXT[],
    p_importance TEXT DEFAULT 'medium',
    p_valid_until TIMESTAMPTZ DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_announcement_id UUID;
    v_user_role TEXT;
BEGIN
    -- Get the user's role
    SELECT role INTO v_user_role
    FROM users WHERE id = auth.uid();

    -- Verify user has permission (admin, supervisor, or teacher)
    IF v_user_role NOT IN ('admin', 'supervisor', 'teacher') THEN
        RAISE EXCEPTION 'Only administrators, supervisors, and teachers can create announcements';
    END IF;

    -- If department_id is provided and user is supervisor, verify they manage that department
    IF p_department_id IS NOT NULL AND v_user_role = 'supervisor' THEN
        IF NOT EXISTS (
            SELECT 1 
            FROM departments d
            WHERE d.id = p_department_id 
            AND d.supervisor_id = auth.uid()
        ) THEN
            RAISE EXCEPTION 'Supervisors can only create announcements for their own departments';
        END IF;
    END IF;
    
    -- If course_id is provided and user is teacher, verify they teach that course
    IF p_course_id IS NOT NULL AND v_user_role = 'teacher' THEN
        IF NOT EXISTS (
            SELECT 1 
            FROM courses c
            WHERE c.id = p_course_id 
            AND c.instructor_id = auth.uid()
        ) THEN
            RAISE EXCEPTION 'Teachers can only create announcements for courses they teach';
        END IF;
    END IF;

    -- Create the announcement
    INSERT INTO announcements (
        title,
        content,
        department_id,
        course_id,
        created_by,
        target_roles,
        importance,
        valid_until
    ) VALUES (
        p_title,
        p_content,
        p_department_id,
        p_course_id,
        auth.uid(),
        p_target_roles,
        p_importance,
        p_valid_until
    ) RETURNING id INTO v_announcement_id;

    RETURN v_announcement_id;
END;
$$;

-- Step 5: Create updated update_announcement function
CREATE OR REPLACE FUNCTION update_announcement(
    p_announcement_id UUID,
    p_title TEXT,
    p_content TEXT,
    p_target_roles TEXT[],
    p_importance TEXT,
    p_valid_until TIMESTAMPTZ
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verify user has permission and owns the announcement or is admin
    IF NOT EXISTS (
        SELECT 1 FROM announcements a
        WHERE a.id = p_announcement_id
        AND (
            a.created_by = auth.uid()
            OR EXISTS (
                SELECT 1 FROM users
                WHERE id = auth.uid()
                AND role = 'admin'
            )
        )
    ) THEN
        RAISE EXCEPTION 'You do not have permission to update this announcement';
    END IF;

    -- Update the announcement
    UPDATE announcements
    SET 
        title = p_title,
        content = p_content,
        target_roles = p_target_roles,
        importance = p_importance,
        valid_until = p_valid_until,
        updated_at = NOW()
    WHERE id = p_announcement_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Announcement not found';
    END IF;
END;
$$;

-- Step 6: Create updated RLS policy
CREATE POLICY users_view_announcements ON announcements
    FOR SELECT
    TO authenticated
    USING (
        (
            -- User's role is in the target_roles array
            auth.uid() IN (
                SELECT id FROM users 
                WHERE role = ANY(announcements.target_roles)
            )
            -- If department-specific, user must be in that department
            AND (
                announcements.department_id IS NULL 
                OR EXISTS (
                    SELECT 1 FROM users u
                    LEFT JOIN students s ON s.id = u.id
                    LEFT JOIN teachers t ON t.id = u.id
                    LEFT JOIN supervisors sup ON sup.id = u.id
                    WHERE u.id = auth.uid()
                    AND (
                        s.department_id = announcements.department_id
                        OR t.department_id = announcements.department_id
                        OR sup.department_id = announcements.department_id
                    )
                )
            )
            -- If course-specific, student must be enrolled in that course
            AND (
                announcements.course_id IS NULL
                OR EXISTS (
                    SELECT 1 FROM course_enrollments ce
                    WHERE ce.student_id = auth.uid()
                    AND ce.course_id = announcements.course_id
                    AND ce.status = 'active'
                )
                -- Teachers can see announcements for courses they teach
                OR EXISTS (
                    SELECT 1 FROM courses c
                    WHERE c.instructor_id = auth.uid()
                    AND c.id = announcements.course_id
                )
                -- Admins and Supervisors can see all course announcements
                OR EXISTS (
                    SELECT 1 FROM users u
                    WHERE u.id = auth.uid()
                    AND u.role IN ('admin', 'supervisor')
                )
            )
            -- Announcement must be active and not expired
            AND announcements.status = 'active'
            AND (
                announcements.valid_until IS NULL 
                OR announcements.valid_until > NOW()
            )
        )
    );
