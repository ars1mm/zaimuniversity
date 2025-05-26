-- Course Enrollments RLS Policies and Helper Functions

-- Drop existing policies if they exist
DROP POLICY IF EXISTS admin_manage_enrollments ON course_enrollments;
DROP POLICY IF EXISTS supervisor_manage_dept_enrollments ON course_enrollments;
DROP POLICY IF EXISTS teacher_view_course_enrollments ON course_enrollments;
DROP POLICY IF EXISTS student_view_own_enrollments ON course_enrollments;

-- Enable Row Level Security
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;

-- Policy: Admins have full access
CREATE POLICY admin_manage_enrollments ON course_enrollments
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.role = 'admin'
        )
    );

-- Policy: Supervisors can view and modify enrollments for their department's courses
CREATE POLICY supervisor_manage_dept_enrollments ON course_enrollments
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 
            FROM users u
            JOIN supervisors s ON s.id = u.id
            JOIN departments d ON d.supervisor_id = s.id
            JOIN courses c ON c.department_id = d.id
            WHERE u.id = auth.uid()
            AND u.role = 'supervisor'
            AND course_enrollments.course_id = c.id
        )
    );

-- Policy: Teachers can view enrollments for their courses
CREATE POLICY teacher_view_course_enrollments ON course_enrollments
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM users u
            JOIN courses c ON c.instructor_id = u.id
            WHERE u.id = auth.uid()
            AND u.role = 'teacher'
            AND course_enrollments.course_id = c.id
        )
    );

-- Policy: Students can view their own enrollments
CREATE POLICY student_view_own_enrollments ON course_enrollments
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() = student_id
    );

-- Function to safely enroll a student in a course
CREATE OR REPLACE FUNCTION enroll_student(
    p_student_id UUID,
    p_course_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_enrollment_id UUID;
BEGIN
    -- Check if the user has permission (admin or supervisor)
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'supervisor')
    ) THEN
        RAISE EXCEPTION 'Only administrators and supervisors can enroll students';
    END IF;

    -- Check if the student exists and is active
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = p_student_id 
        AND role = 'student'
        AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Invalid or inactive student';
    END IF;

    -- Check if the course exists and is active
    IF NOT EXISTS (
        SELECT 1 FROM courses 
        WHERE id = p_course_id 
        AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Invalid or inactive course';
    END IF;

    -- Create the enrollment
    INSERT INTO course_enrollments (
        student_id,
        course_id,
        enrollment_date,
        status
    ) VALUES (
        p_student_id,
        p_course_id,
        NOW(),
        'active'
    ) RETURNING id INTO v_enrollment_id;

    RETURN v_enrollment_id;
END;
$$;

-- Function to update enrollment status
CREATE OR REPLACE FUNCTION update_enrollment_status(
    p_enrollment_id UUID,
    p_status TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if the user has permission (admin or supervisor)
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'supervisor')
    ) THEN
        RAISE EXCEPTION 'Only administrators and supervisors can update enrollment status';
    END IF;

    -- Validate status
    IF p_status NOT IN ('active', 'withdrawn', 'completed') THEN
        RAISE EXCEPTION 'Invalid status value';
    END IF;

    -- Update the enrollment
    UPDATE course_enrollments
    SET 
        status = p_status
    WHERE id = p_enrollment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Enrollment not found';
    END IF;
END;
$$;

-- Comment on table and columns
COMMENT ON TABLE course_enrollments IS 'Stores student course enrollment records';
COMMENT ON COLUMN course_enrollments.id IS 'Unique identifier for the enrollment record';
COMMENT ON COLUMN course_enrollments.student_id IS 'Reference to the enrolled student''s user ID';
COMMENT ON COLUMN course_enrollments.course_id IS 'Reference to the course being enrolled in';
COMMENT ON COLUMN course_enrollments.enrollment_date IS 'Date and time when the enrollment was created';
COMMENT ON COLUMN course_enrollments.status IS 'Current status of the enrollment (active, withdrawn, completed)';
COMMENT ON COLUMN course_enrollments.final_grade IS 'Final numerical grade for the course (0-100)';
