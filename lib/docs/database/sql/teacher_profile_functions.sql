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
CREATE POLICY teachers_select_policy ON teachers 
  FOR SELECT USING (
    -- Anyone can view teacher profiles
    auth.role() = 'authenticated'
  );

-- Policy for updating teacher profiles
CREATE POLICY teachers_update_policy ON teachers 
  FOR UPDATE USING (
    -- Only the teacher themself, admins, or supervisors can update
    auth.uid() = id OR
    auth.role() IN ('admin', 'supervisor')
  );

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