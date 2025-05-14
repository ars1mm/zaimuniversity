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
CREATE POLICY course_schedules_select_policy ON course_schedules 
  FOR SELECT USING (
    -- Anyone can view schedules (could be further restricted if needed)
    auth.role() = 'authenticated'
  );

-- Policy for inserting course schedules
CREATE POLICY course_schedules_insert_policy ON course_schedules 
  FOR INSERT WITH CHECK (
    -- Only admins and supervisors can insert
    auth.role() IN ('admin', 'supervisor')
  );

-- Policy for updating course schedules
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

-- Policy for deleting course schedules
CREATE POLICY course_schedules_delete_policy ON course_schedules 
  FOR DELETE USING (
    -- Only admins and supervisors can delete schedules
    auth.role() IN ('admin', 'supervisor')
  ); 