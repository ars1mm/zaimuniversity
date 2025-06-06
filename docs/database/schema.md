# Zaim University Database Schema

This document outlines the database schema for the Istanbul Zaim University Campus Information System. The database is implemented in Supabase and consists of several interconnected tables that manage various aspects of the university's operations.

## Tables

### 1. Users
This table will store all user accounts across different roles.
- `id` (UUID, primary key)
- `email` (string, unique)
- `password_hash` (string) - Supabase handles this automatically
- `full_name` (string)
- `role` (enum: 'admin', 'supervisor', 'teacher', 'student')
- `status` (enum: 'active', 'inactive', 'suspended')
- `created_at` (timestamp)
- `updated_at` (timestamp)

### 2. Students
This table extends the Users table with student-specific information.
- `id` (UUID, primary key, references users.id)
- `student_id` (string, unique)
- `department_id` (UUID, foreign key)
- `address` (string)
- `contact_info` (JSON)
- `enrollment_date` (date)
- `academic_standing` (string)
- `preferences` (JSON)

### 3. Supervisors
This table extends the Users table with supervisor-specific information.
- `id` (UUID, primary key, references users.id)
- `department_id` (UUID, foreign key)
- `specialization` (string)
- `bio` (text)
- `contact_info` (JSON)
- `created_at` (timestamp)

### 4. Teachers
This table extends the Users table with teacher-specific information.
- `id` (UUID, primary key, references users.id)
- `department_id` (UUID, foreign key)
- `specialization` (string)
- `contact_info` (JSON)
- `bio` (text)
- `status` (enum: 'active', 'on_leave', 'retired')

### 5. Departments
This table stores university departments.
- `id` (UUID, primary key)
- `name` (string)
- `description` (text)
- `supervisor_id` (UUID, foreign key to users.id)

### 6. Courses
This table stores information about university courses.
- `id` (UUID, primary key)
- `title` (string)
- `description` (text)
- `schedule` (JSON)
- `capacity` (integer)
- `instructor_id` (UUID, foreign key to teachers.id)
- `department_id` (UUID, foreign key to departments.id)
- `status` (enum: 'active', 'pending', 'rejected', 'completed', 'cancelled')
- `semester` (string)
- `created_at` (timestamp)
- `updated_at` (timestamp)
- `created_by` (UUID, foreign key to users.id)

### 7. Course_Enrollments
This junction table tracks which students are enrolled in which courses.
- `id` (UUID, primary key)
- `student_id` (UUID, foreign key to students.id)
- `course_id` (UUID, foreign key to courses.id)
- `enrollment_date` (timestamp)
- `status` (enum: 'active', 'withdrawn', 'completed')
- `final_grade` (float, nullable)

### 8. Course_Materials
This table stores materials/resources for courses.
- `id` (UUID, primary key)
- `course_id` (UUID, foreign key to courses.id)
- `title` (string)
- `description` (text)
- `file_url` (string)
- `file_type` (string)
- `uploaded_by` (UUID, foreign key to users.id)
- `uploaded_at` (timestamp)

### 9. Homework_Assignments
This table stores homework assignments for courses.
- `id` (UUID, primary key)
- `course_id` (UUID, foreign key to courses.id)
- `title` (string)
- `description` (text)
- `due_date` (timestamp)
- `total_points` (float)
- `created_by` (UUID, foreign key to teachers.id)
- `created_at` (timestamp)
- `updated_at` (timestamp)

### 10. Homework_Submissions
This table tracks student submissions for homework.
- `id` (UUID, primary key)
- `homework_id` (UUID, foreign key to homework_assignments.id)
- `student_id` (UUID, foreign key to students.id)
- `submission_url` (string)
- `submitted_at` (timestamp)
- `score` (float, nullable)
- `feedback` (text)
- `graded_by` (UUID, foreign key to teachers.id)
- `graded_at` (timestamp)

### 11. Transcripts
This table stores student academic records.
- `id` (UUID, primary key)
- `student_id` (UUID, foreign key to students.id)
- `semester` (string)
- `gpa` (float)
- `credits_earned` (integer)
- `academic_standing` (string)
- `generated_at` (timestamp)

### 12. Course_Approvals
This table tracks the course approval process by supervisors.
- `id` (UUID, primary key)
- `course_id` (UUID, foreign key to courses.id)
- `supervisor_id` (UUID, foreign key to users.id with role='supervisor')
- `status` (text) - Possible values: 'approved', 'rejected', 'pending'
- `feedback` (text) - Supervisor's comments or feedback about the course
- `reviewed_at` (timestamptz) - When the supervisor reviewed the course

## Database Relationships

1. **One-to-one relationship between Users and Students/Teachers/Supervisors**
   - Each student/teacher/supervisor record is associated with exactly one user record

2. **One-to-many relationship between Supervisors and Departments**
   - A supervisor can manage multiple departments
   - Each department has one assigned supervisor

3. **One-to-many relationship between Departments and Courses**
   - A department offers multiple courses
   - Each course belongs to one department

4. **One-to-many relationship between Teachers and Courses**
   - A teacher can instruct multiple courses
   - Each course has one primary instructor

5. **Many-to-many relationship between Students and Courses (via Course_Enrollments)**
   - A student can enroll in multiple courses
   - A course can have multiple students enrolled

6. **One-to-many relationship between Courses and Course_Materials**
   - A course can have multiple materials/resources
   - Each material belongs to one specific course

7. **One-to-many relationship between Courses and Homework_Assignments**
   - A course can have multiple homework assignments
   - Each assignment belongs to one specific course

8. **One-to-many relationship between Homework_Assignments and Homework_Submissions**
   - An assignment can have multiple student submissions
   - Each submission is for one specific assignment

9. **One-to-many relationship between Students and Transcripts**
   - A student can have multiple transcript records (typically one per semester)
   - Each transcript belongs to one specific student

10. **One-to-many relationship between Supervisors and Course_Approvals**
    - A supervisor can review multiple course proposals
    - Each course approval is handled by one supervisor 