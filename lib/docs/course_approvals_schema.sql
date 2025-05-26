-- Course Approvals Schema SQL
-- This file contains the SQL for creating and managing the course_approvals table

-- Create course_approvals table
CREATE TABLE IF NOT EXISTS course_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    supervisor_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')),
    feedback TEXT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS course_approvals_course_id_idx ON course_approvals(course_id);
CREATE INDEX IF NOT EXISTS course_approvals_supervisor_id_idx ON course_approvals(supervisor_id);
CREATE INDEX IF NOT EXISTS course_approvals_status_idx ON course_approvals(status);

-- Row Level Security (RLS) for course_approvals table
ALTER TABLE course_approvals ENABLE ROW LEVEL SECURITY;

-- Policy: Supervisors can view all course approvals in their department
CREATE POLICY supervisor_view_course_approvals ON course_approvals 
FOR SELECT TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM users u 
        JOIN supervisors s ON s.id = u.id
        JOIN departments d ON d.id = s.department_id
        JOIN courses c ON c.department_id = d.id
        WHERE u.id = auth.uid() 
        AND u.role = 'supervisor'
        AND course_approvals.course_id = c.id
    )
    OR 
    supervisor_id = auth.uid()
);

-- Policy: Only the assigned supervisor can update course approvals
CREATE POLICY supervisor_update_course_approvals ON course_approvals 
FOR UPDATE TO authenticated 
USING (supervisor_id = auth.uid())
WITH CHECK (supervisor_id = auth.uid());

-- Policy: Admins can view all course approvals
CREATE POLICY admin_view_course_approvals ON course_approvals 
FOR SELECT TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Policy: Admins can modify course approvals
CREATE POLICY admin_modify_course_approvals ON course_approvals 
FOR ALL TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Policy: Teachers can view approvals for their own courses
CREATE POLICY teacher_view_course_approvals ON course_approvals 
FOR SELECT TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM users u
        JOIN teachers t ON t.id = u.id
        JOIN courses c ON c.instructor_id = t.id
        WHERE u.id = auth.uid()
        AND u.role = 'teacher'
        AND course_approvals.course_id = c.id
    )
);

-- Function: Submit course for approval
CREATE OR REPLACE FUNCTION submit_course_for_approval(
    p_course_id UUID
) RETURNS UUID AS $$
DECLARE
    department_supervisor_id UUID;
    new_approval_id UUID;
BEGIN
    -- Get the supervisor for the department this course belongs to
    SELECT d.supervisor_id INTO department_supervisor_id
    FROM courses c
    JOIN departments d ON d.id = c.department_id
    WHERE c.id = p_course_id;
    
    -- Check if we found a supervisor
    IF department_supervisor_id IS NULL THEN
        RAISE EXCEPTION 'No supervisor found for the department';
    END IF;
    
    -- Create a new course approval record
    INSERT INTO course_approvals (
        course_id,
        supervisor_id,
        status,
        feedback,
        reviewed_at
    ) VALUES (
        p_course_id,
        department_supervisor_id,
        'pending',
        NULL,
        NULL
    ) RETURNING id INTO new_approval_id;
    
    -- Update the course status to pending
    UPDATE courses
    SET status = 'pending'
    WHERE id = p_course_id;
    
    RETURN new_approval_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Review course approval
CREATE OR REPLACE FUNCTION review_course_approval(
    p_approval_id UUID,
    p_status TEXT,
    p_feedback TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_course_id UUID;
BEGIN
    -- Validate status
    IF p_status NOT IN ('approved', 'rejected') THEN
        RAISE EXCEPTION 'Invalid status. Must be "approved" or "rejected"';
    END IF;
    
    -- Get the course ID
    SELECT course_id INTO v_course_id
    FROM course_approvals
    WHERE id = p_approval_id;
    
    -- Update the approval
    UPDATE course_approvals
    SET 
        status = p_status,
        feedback = p_feedback,
        reviewed_at = NOW()
    WHERE id = p_approval_id;
    
    -- Update the course status
    UPDATE courses
    SET status = p_status
    WHERE id = v_course_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Update course status when approval status changes
CREATE OR REPLACE FUNCTION update_course_on_approval_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only execute if the status has changed
    IF OLD.status <> NEW.status THEN
        UPDATE courses
        SET status = NEW.status
        WHERE id = NEW.course_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_approval_status_change
    AFTER UPDATE OF status ON course_approvals
    FOR EACH ROW
    EXECUTE FUNCTION update_course_on_approval_change();

-- View: Courses with approval status
CREATE OR REPLACE VIEW courses_with_approval_status AS
SELECT 
    c.*,
    ca.id AS approval_id,
    ca.status AS approval_status,
    ca.feedback AS approval_feedback,
    ca.reviewed_at AS approval_reviewed_at,
    u.full_name AS supervisor_name
FROM 
    courses c
LEFT JOIN 
    course_approvals ca ON c.id = ca.course_id
LEFT JOIN
    users u ON ca.supervisor_id = u.id;
