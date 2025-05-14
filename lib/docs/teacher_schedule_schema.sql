-- Course Schedule Schema for Teacher Schedule Feature

-- Create course_schedules table if it doesn't exist
CREATE TABLE IF NOT EXISTS course_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  day_of_week TEXT NOT NULL CHECK (day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  room TEXT NOT NULL,
  building TEXT,
  campus TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure end time is after start time
  CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

-- Add RLS policies
ALTER TABLE course_schedules ENABLE ROW LEVEL SECURITY;

-- Create policy for viewing course schedules (public for authenticated users)
CREATE POLICY course_schedules_select_policy ON course_schedules 
  FOR SELECT USING (auth.role() = 'authenticated');

-- Create policy for inserting course schedules (admin, supervisor)
CREATE POLICY course_schedules_insert_policy ON course_schedules 
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT id FROM users 
      WHERE role IN ('admin', 'supervisor')
    )
  );

-- Create policy for updating course schedules (admin, supervisor, course instructor)
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

-- Create policy for deleting course schedules (admin, supervisor only)
CREATE POLICY course_schedules_delete_policy ON course_schedules 
  FOR DELETE USING (
    auth.uid() IN (
      SELECT id FROM users 
      WHERE role IN ('admin', 'supervisor')
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS course_schedules_course_id_idx ON course_schedules (course_id);
CREATE INDEX IF NOT EXISTS course_schedules_day_idx ON course_schedules (day_of_week);

-- Function to get a teacher's schedule
CREATE OR REPLACE FUNCTION get_teacher_schedule(teacher_id UUID)
RETURNS TABLE (
  course_title TEXT,
  course_code TEXT,
  day_of_week TEXT,
  start_time TIME,
  end_time TIME,
  room TEXT,
  building TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.title as course_title,
    c.code as course_code,
    cs.day_of_week,
    cs.start_time,
    cs.end_time,
    cs.room,
    cs.building
  FROM 
    courses c
    JOIN course_schedules cs ON c.id = cs.course_id
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
    END,
    cs.start_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION get_teacher_schedule(UUID) TO authenticated;
