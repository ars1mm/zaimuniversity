-- Add the missing course_code column to courses table
ALTER TABLE courses ADD COLUMN IF NOT EXISTS course_code TEXT;

-- Create an index on the course_code column for faster queries
CREATE INDEX IF NOT EXISTS courses_course_code_idx ON courses (course_code);

-- For better organization, update the get_teacher_schedule function to use the correct column
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
    c.course_code as course_code, -- Updated from c.code to c.course_code
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

-- Grant execution permissions to the updated function
GRANT EXECUTE ON FUNCTION get_teacher_schedule(UUID) TO authenticated;

-- Add a comment to document the change
COMMENT ON COLUMN courses.course_code IS 'Course code for identification purposes (e.g., CS101, MATH202)'; 