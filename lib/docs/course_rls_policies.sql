-- Enable RLS on courses table
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Policy for teachers to view their own courses
CREATE POLICY teacher_view_own_courses ON courses
FOR SELECT TO authenticated
USING (
  instructor_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role IN ('admin', 'supervisor')
  )
);

-- Policy for teachers to update their own courses
CREATE POLICY teacher_update_own_courses ON courses
FOR UPDATE TO authenticated
USING (
  instructor_id = auth.uid()
  AND status != 'completed'
)
WITH CHECK (
  instructor_id = auth.uid()
  AND status != 'completed'
);

-- Policy for admins to manage all courses
CREATE POLICY admin_manage_courses ON courses
FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'admin'
  )
);

-- Policy for supervisors to view and manage department courses
CREATE POLICY supervisor_manage_department_courses ON courses
FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users u
    JOIN supervisors s ON s.id = u.id
    JOIN departments d ON d.supervisor_id = s.id
    WHERE u.id = auth.uid()
    AND u.role = 'supervisor'
    AND courses.department_id = d.id
  )
); 