/*
 * Istanbul Zaim University Campus Information System
 * Database Installation Script
 *
 * This script applies all necessary database functions and fixes to a Supabase database
 * Run this script in the SQL editor of your Supabase project
 */

-- =====================================
-- 1. Auth Functions
-- =====================================

-- Function to get the current user's role
CREATE OR REPLACE FUNCTION get_auth_user_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Get the role from the auth schema's role() function
    RETURN auth.role();
END;
$$;

-- Function to get a user's hash for secure operations
CREATE OR REPLACE FUNCTION get_auth_user_hash(user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_hash TEXT;
BEGIN
    -- Get the user's password hash or identifier from the auth.users table
    -- This should be used very carefully and only when absolutely necessary
    -- Most operations should use auth.uid() instead
    SELECT auth.uid()::text || '_' || extract(epoch from now())::text
    INTO user_hash;
    
    RETURN user_hash;
END;
$$;

-- Function to check if a user has a specific role
CREATE OR REPLACE FUNCTION user_has_role(user_id UUID, role_name TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role TEXT;
BEGIN
    -- Get the user's role from the users table
    SELECT role INTO user_role
    FROM users
    WHERE id = user_id;
    
    -- Check if the role matches
    RETURN user_role = role_name;
END;
$$;

-- Function to check if current user can access a specific course
CREATE OR REPLACE FUNCTION can_access_course(course_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_role TEXT;
    is_instructor BOOLEAN;
    is_enrolled BOOLEAN;
BEGIN
    -- Get current user's role
    user_role := auth.role();
    
    -- Admin and supervisor can access any course
    IF user_role IN ('admin', 'supervisor') THEN
        RETURN TRUE;
    END IF;
    
    -- Check if user is the instructor of the course
    IF user_role = 'teacher' THEN
        SELECT EXISTS (
            SELECT 1 FROM courses 
            WHERE id = course_id 
            AND instructor_id = auth.uid()
        ) INTO is_instructor;
        
        RETURN is_instructor;
    END IF;
    
    -- Check if user is enrolled in the course
    IF user_role = 'student' THEN
        SELECT EXISTS (
            SELECT 1 FROM course_enrollments 
            WHERE course_id = course_id 
            AND student_id = auth.uid()
        ) INTO is_enrolled;
        
        RETURN is_enrolled;
    END IF;
    
    -- Default to no access
    RETURN FALSE;
END;
$$;

-- =====================================
-- 2. Teacher Profile Functions
-- =====================================

-- Function to ensure the teacher_profiles bucket exists
CREATE OR REPLACE FUNCTION create_teacher_profiles_bucket()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Call the existing admin_ensure_bucket_exists function
    PERFORM admin_ensure_bucket_exists('teacher_profiles');
    
    -- Set storage bucket policies
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('teacher_profiles', 'teacher_profiles', false)
    ON CONFLICT (id) DO UPDATE SET public = false;
END;
$$;

-- Function to upload a teacher profile picture
CREATE OR REPLACE FUNCTION upload_teacher_profile_picture(teacher_id UUID, file_name TEXT, file_content BYTEA, content_type TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    file_path TEXT;
    result TEXT;
BEGIN
    -- Ensure the bucket exists
    PERFORM create_teacher_profiles_bucket();
    
    -- Create a sanitized path
    file_path := 'teachers/' || teacher_id::text || '/' || file_name;
    
    -- Use the admin_upload_profile_picture function that already exists
    result := admin_upload_profile_picture(teacher_id::text, file_path, file_content, content_type);
    
    -- Update the teacher profile with the new profile picture URL
    UPDATE teachers
    SET profile_picture_url = result
    WHERE id = teacher_id;
    
    RETURN result;
END;
$$;

-- Function to get teacher profile details with additional stats
CREATE OR REPLACE FUNCTION get_teacher_profile_details(p_teacher_id UUID)
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    email TEXT,
    department_name TEXT,
    specialization TEXT,
    profile_picture_url TEXT,
    active_courses BIGINT,
    total_students BIGINT,
    pending_assignments BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        u.full_name,
        u.email,
        d.name AS department_name,
        t.specialization,
        t.profile_picture_url,
        -- Count active courses
        (SELECT COUNT(*) FROM courses c WHERE c.instructor_id = t.id AND c.status = 'active') AS active_courses,
        -- Count total students
        (SELECT COUNT(DISTINCT ce.student_id) 
         FROM course_enrollments ce 
         JOIN courses c ON ce.course_id = c.id 
         WHERE c.instructor_id = t.id AND ce.status = 'active') AS total_students,
        -- Count pending assignments
        (SELECT COUNT(*) 
         FROM homework_assignments ha 
         JOIN courses c ON ha.course_id = c.id 
         WHERE c.instructor_id = t.id AND ha.due_date > NOW()) AS pending_assignments
    FROM teachers t
    JOIN users u ON t.id = u.id
    LEFT JOIN departments d ON t.department_id = d.id
    WHERE t.id = p_teacher_id;
END;
$$;

-- RLS policy for teachers table
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;

-- Policy for selecting teacher profiles
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'teachers' AND policyname = 'teachers_select_policy') THEN
        CREATE POLICY teachers_select_policy ON teachers 
        FOR SELECT USING (
            -- Anyone can view teacher profiles
            auth.role() = 'authenticated'
        );
    END IF;
END
$$;

-- Policy for updating teacher profiles
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'teachers' AND policyname = 'teachers_update_policy') THEN
        CREATE POLICY teachers_update_policy ON teachers 
        FOR UPDATE USING (
            -- Only the teacher themself, admins, or supervisors can update
            auth.uid() = id OR
            auth.role() IN ('admin', 'supervisor')
        );
    END IF;
END
$$;

-- Function to cleanly handle teacher schedule transfer during teacher replacement
CREATE OR REPLACE FUNCTION transfer_teacher_schedule(old_teacher_id UUID, new_teacher_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    transferred_count INTEGER;
BEGIN
    -- First, transfer all the courses to the new teacher
    UPDATE courses
    SET instructor_id = new_teacher_id
    WHERE instructor_id = old_teacher_id;
    
    -- Count how many were transferred
    GET DIAGNOSTICS transferred_count = ROW_COUNT;
    
    -- Return the number of transferred courses
    RETURN transferred_count;
END;
$$;

-- =====================================
-- 3. Schedule Functions
-- =====================================

-- Function to check for teacher schedule conflicts
CREATE OR REPLACE FUNCTION check_teacher_schedule_conflicts(
    p_course_ids UUID[],
    p_day_of_week TEXT,
    p_start_time TIME,
    p_end_time TIME,
    p_exclude_course_id UUID
)
RETURNS TABLE (
    course_id UUID,
    day_of_week TEXT,
    start_time TIME,
    end_time TIME
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cs.course_id,
        cs.day_of_week,
        cs.start_time::TIME,
        cs.end_time::TIME
    FROM 
        course_schedules cs
    WHERE 
        cs.course_id = ANY(p_course_ids)
        AND cs.course_id <> p_exclude_course_id
        AND cs.day_of_week = p_day_of_week
        AND (
            -- Check if the new schedule overlaps with existing schedules
            (cs.start_time <= p_end_time AND cs.end_time >= p_start_time)
        );
END;
$$;

-- Function to get a teacher's complete schedule
CREATE OR REPLACE FUNCTION get_teacher_schedule(teacher_id UUID)
RETURNS TABLE (
    id UUID,
    course_id UUID,
    course_title TEXT,
    day_of_week TEXT,
    start_time TIME,
    end_time TIME,
    room TEXT,
    building TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cs.id,
        cs.course_id,
        c.title as course_title,
        cs.day_of_week,
        cs.start_time::TIME,
        cs.end_time::TIME,
        cs.room,
        cs.building
    FROM 
        course_schedules cs
    JOIN 
        courses c ON cs.course_id = c.id
    WHERE 
        c.instructor_id = teacher_id
    ORDER BY
        CASE 
            WHEN cs.day_of_week = 'Monday' THEN 1
            WHEN cs.day_of_week = 'Tuesday' THEN 2
            WHEN cs.day_of_week = 'Wednesday' THEN 3
            WHEN cs.day_of_week = 'Thursday' THEN 4
            WHEN cs.day_of_week = 'Friday' THEN 5
            WHEN cs.day_of_week = 'Saturday' THEN 6
            WHEN cs.day_of_week = 'Sunday' THEN 7
            ELSE 8
        END,
        cs.start_time;
END;
$$;

-- RLS policy for course_schedules table
ALTER TABLE course_schedules ENABLE ROW LEVEL SECURITY;

-- Policy for selecting course schedules
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_schedules' AND policyname = 'course_schedules_select_policy') THEN
        CREATE POLICY course_schedules_select_policy ON course_schedules 
        FOR SELECT USING (
            -- Anyone can view schedules (could be further restricted if needed)
            auth.role() = 'authenticated'
        );
    END IF;
END
$$;

-- Policy for inserting course schedules
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_schedules' AND policyname = 'course_schedules_insert_policy') THEN
        CREATE POLICY course_schedules_insert_policy ON course_schedules 
        FOR INSERT WITH CHECK (
            -- Only admins and supervisors can insert
            auth.role() IN ('admin', 'supervisor')
        );
    END IF;
END
$$;

-- Policy for updating course schedules
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_schedules' AND policyname = 'course_schedules_update_policy') THEN
        CREATE POLICY course_schedules_update_policy ON course_schedules 
        FOR UPDATE USING (
            -- Only admins, supervisors, and the teacher of the course can update
            auth.role() IN ('admin', 'supervisor') OR
            (
                auth.role() = 'teacher' AND
                EXISTS (
                    SELECT 1 FROM courses c
                    WHERE c.id = course_schedules.course_id
                    AND c.instructor_id = auth.uid()
                )
            )
        );
    END IF;
END
$$;

-- Policy for deleting course schedules
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'course_schedules' AND policyname = 'course_schedules_delete_policy') THEN
        CREATE POLICY course_schedules_delete_policy ON course_schedules 
        FOR DELETE USING (
            -- Only admins and supervisors can delete schedules
            auth.role() IN ('admin', 'supervisor')
        );
    END IF;
END
$$;

-- =====================================
-- Log installation completion
-- =====================================
DO $$
BEGIN
    RAISE NOTICE 'Istanbul Zaim University Database Functions Installation Completed Successfully';
END
$$; 