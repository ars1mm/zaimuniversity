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