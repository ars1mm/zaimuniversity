-- Student Schedule Schema
-- This extends the teacher_schedule_schema.sql with student-specific functionality

-- Function to get a student's schedule based on their enrolled courses
CREATE OR REPLACE FUNCTION get_student_schedule(student_id UUID)
RETURNS TABLE (
  course_title TEXT,
  course_code TEXT,
  day_of_week TEXT,
  start_time TIME,
  end_time TIME,
  room TEXT,
  building TEXT,
  teacher_name TEXT
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
    cs.building,
    u.full_name as teacher_name
  FROM 
    course_enrollments ce
    JOIN courses c ON ce.course_id = c.id
    JOIN course_schedules cs ON c.id = cs.course_id
    LEFT JOIN teachers t ON c.instructor_id = t.id
    LEFT JOIN users u ON t.id = u.id
  WHERE 
    ce.student_id = student_id
    AND ce.status = 'active'  -- Only include active enrollments
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
GRANT EXECUTE ON FUNCTION get_student_schedule(UUID) TO authenticated;

-- Function to check for course schedule conflicts for a student
CREATE OR REPLACE FUNCTION check_student_schedule_conflicts(
  p_student_id UUID,
  p_potential_course_id UUID
) RETURNS TABLE (
  conflict_course_title TEXT,
  conflict_day TEXT,
  conflict_start_time TIME,
  conflict_end_time TIME
) AS $$
BEGIN
  RETURN QUERY
  WITH potential_schedules AS (
    SELECT 
      cs.day_of_week,
      cs.start_time,
      cs.end_time
    FROM
      course_schedules cs
    WHERE
      cs.course_id = p_potential_course_id
  ),
  current_schedules AS (
    SELECT 
      c.title,
      cs.day_of_week,
      cs.start_time,
      cs.end_time
    FROM 
      course_enrollments ce
      JOIN courses c ON ce.course_id = c.id
      JOIN course_schedules cs ON c.id = cs.course_id
    WHERE 
      ce.student_id = p_student_id
      AND ce.status = 'active'
  )
  SELECT 
    cs.title as conflict_course_title,
    cs.day_of_week as conflict_day,
    cs.start_time as conflict_start_time,
    cs.end_time as conflict_end_time
  FROM 
    current_schedules cs,
    potential_schedules ps
  WHERE
    cs.day_of_week = ps.day_of_week
    AND (
      -- Check if current course overlaps with potential course
      (cs.start_time <= ps.end_time AND cs.end_time >= ps.start_time)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION check_student_schedule_conflicts(UUID, UUID) TO authenticated;
