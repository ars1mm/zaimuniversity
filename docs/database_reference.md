# Zaim University Database Schema Reference

## Overview

This document provides a comprehensive reference of the database schema used in the Zaim University Campus Information System. It details all tables, their key columns, relationships, and access patterns.

## Core Tables

### users
Primary user account information for all system users regardless of role.

| Column       | Type          | Description                               |
|--------------|---------------|-------------------------------------------|
| id           | UUID          | Primary key                               |
| email        | TEXT          | User email address (unique)               |
| full_name    | TEXT          | User's full name                          |
| role         | TEXT          | User role (student, teacher, admin, etc.) |
| status       | TEXT          | Account status (active, inactive, etc.)   |
| password_hash| TEXT          | Hashed password for local authentication  |
| created_at   | TIMESTAMPTZ   | Creation timestamp                        |
| updated_at   | TIMESTAMPTZ   | Last update timestamp                     |
| profile_picture_url | TEXT   | URL to profile picture                    |

### students
Extended information for student users.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key, references users.id       |
| student_id     | TEXT          | Student identification number          |
| department_id  | UUID          | References departments.id              |
| address        | TEXT          | Student's address                      |
| contact_info   | JSONB         | Contact information (phone, etc.)      |
| enrollment_date| DATE          | Date of enrollment                     |
| academic_standing | TEXT       | Academic standing (good, probation)    |
| preferences    | JSONB         | Student preferences                    |

### teachers
Extended information for teacher users.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key, references users.id       |
| department_id  | UUID          | References departments.id              |
| specialization | TEXT          | Teacher's area of specialization       |
| contact_info   | JSONB         | Contact information                    |
| bio            | TEXT          | Teacher biography                      |
| status         | TEXT          | Employment status (active, on leave)   |

### departments
Academic departments within the university.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key                            |
| name           | TEXT          | Department name                        |
| description    | TEXT          | Department description                 |
| supervisor_id  | UUID          | Department supervisor (references users.id) |
| created_at     | TIMESTAMPTZ   | Creation timestamp                     |

### supervisors
Extended information for supervisor users.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key, references users.id       |
| department_id  | UUID          | References departments.id              |
| specialization | TEXT          | Supervisor's area of specialization    |
| contact_info   | JSONB         | Contact information                    |
| bio            | TEXT          | Supervisor biography                   |
| created_at     | TIMESTAMPTZ   | Creation timestamp                     |
| updated_at     | TIMESTAMPTZ   | Last update timestamp                  |

## Course-Related Tables

### courses
Main course information.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key                            |
| course_code    | TEXT          | Course code                            |
| title          | TEXT          | Course title                           |
| description    | TEXT          | Course description                     |
| department_id  | UUID          | References departments.id              |
| instructor_id  | UUID          | References teachers.id                 |
| capacity       | INTEGER       | Maximum number of students             |
| schedule       | JSONB         | Course schedule information            |
| status         | TEXT          | Course status (active, cancelled)      |
| semester       | TEXT          | Academic semester                      |
| created_at     | TIMESTAMPTZ   | Creation timestamp                     |
| updated_at     | TIMESTAMPTZ   | Last update timestamp                  |
| created_by     | UUID          | References the user who created the course |

### course_enrollments
Maps students to courses they are enrolled in.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key                            |
| student_id     | UUID          | References students.id                 |
| course_id      | UUID          | References courses.id                  |
| enrollment_date| TIMESTAMPTZ   | Date of enrollment                     |
| status         | TEXT          | Enrollment status (active, withdrawn)  |
| final_grade    | DOUBLE PRECISION | Final numerical grade for the course  |

### course_schedules
Course timing and location information.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key                            |
| course_id      | UUID          | References courses.id                  |
| day_of_week    | TEXT          | Day of the week                        |
| start_time     | TIME          | Start time                             |
| end_time       | TIME          | End time                               |
| room           | TEXT          | Classroom location                     |
| building       | TEXT          | Building name                          |
| campus         | TEXT          | Campus location                        |
| created_at     | TIMESTAMPTZ   | Creation timestamp                     |
| updated_at     | TIMESTAMPTZ   | Last update timestamp                  |

### transcripts
Student academic transcripts.

| Column           | Type          | Description                          |
|------------------|---------------|--------------------------------------|
| id               | UUID          | Primary key                          |
| student_id       | UUID          | References students.id               |
| semester         | TEXT          | Academic semester (e.g., Fall 2024)  |
| credits_earned   | INTEGER       | Total credits earned in semester     |
| gpa              | DOUBLE PRECISION | Grade point average for semester  |
| academic_standing| TEXT          | Academic standing                    |
| generated_at     | TIMESTAMPTZ   | When the transcript was generated    |

## Academic Content Tables

### course_materials
Learning resources associated with courses.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key                            |
| course_id      | UUID          | References courses.id                  |
| title          | TEXT          | Material title                         |
| description    | TEXT          | Material description                   |
| file_url       | TEXT          | URL to the material file               |
| file_type      | TEXT          | Type of file (pdf, doc, video, etc.)   |
| uploaded_by    | UUID          | References users.id                    |
| uploaded_at    | TIMESTAMPTZ   | Date of upload                         |

### exams_schedule
Examination schedule information.

| Column       | Type                        | Description                       |
|-------------|------------------------------|-----------------------------------|
| id          | UUID                         | Primary key                       |
| course_id   | UUID                         | References courses.id             |
| exam_date   | TIMESTAMP WITHOUT TIME ZONE  | Date and time of the exam         |
| duration    | INTEGER                      | Duration of the exam in minutes   |

### exams_score
Student examination scores.

| Column       | Type                        | Description                       |
|-------------|------------------------------|-----------------------------------|
| id          | UUID                         | Primary key                       |
| exam_id     | UUID                         | References exams_schedule.id      |
| student_id  | UUID                         | References students.id            |
| score       | DOUBLE PRECISION             | Exam score/points                 |
| graded_at   | TIMESTAMP WITHOUT TIME ZONE  | When the exam was graded          |

### homework_assignments
Assignments given to students.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key                            |
| course_id      | UUID          | References courses.id                  |
| title          | TEXT          | Assignment title                       |
| description    | TEXT          | Assignment description                 |
| due_date       | TIMESTAMPTZ   | Submission deadline                    |
| total_points   | DOUBLE PRECISION | Maximum points possible             |
| created_by     | UUID          | References users.id                    |
| created_at     | TIMESTAMPTZ   | Creation timestamp                     |
| updated_at     | TIMESTAMPTZ   | Last update timestamp                  |

### homework_submissions
Student submissions for assignments.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key                            |
| homework_id    | UUID          | References homework_assignments.id     |
| student_id     | UUID          | References students.id                 |
| submission_url | TEXT          | URL to submission file                 |
| submitted_at   | TIMESTAMPTZ   | Date of submission                     |
| score          | DOUBLE PRECISION | Points/score awarded                |
| feedback       | TEXT          | Teacher feedback                       |
| graded_by      | UUID          | References the user who graded         |
| graded_at      | TIMESTAMPTZ   | When the submission was graded         |

### course_approvals
Tracks approval workflow for courses by supervisors.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key                            |
| course_id      | UUID          | References courses.id                  |
| supervisor_id  | UUID          | References users.id (supervisor)       |
| status         | TEXT          | Approval status (pending, approved, rejected) |
| feedback       | TEXT          | Feedback from supervisor               |
| reviewed_at    | TIMESTAMPTZ   | When the review was completed          |

### news
Campus news and announcements.

| Column         | Type                        | Description                     |
|----------------|-----------------------------|---------------------------------|
| id             | UUID                        | Primary key                     |
| title          | TEXT                        | News title                      |
| content        | TEXT                        | News content                    |
| created_at     | TIMESTAMP WITHOUT TIME ZONE | Creation timestamp              |
| updated_at     | TIMESTAMP WITHOUT TIME ZONE | Last update timestamp           |

### profiles
User profile information and additional user details.

| Column         | Type          | Description                            |
|----------------|---------------|----------------------------------------|
| id             | UUID          | Primary key, references users.id       |
| bio            | TEXT          | User biography or description          |
| profile_picture| TEXT          | Profile picture URL                    |
| social_links   | JSON          | Social media links and identifiers     |

## Row-Level Security (RLS) Policies

The database implements Row-Level Security to control access to data:

### Examples:

**students table:**
- Students can only access their own information
- Teachers can access information for students in their courses
- Admins and supervisors have full access

**courses table:**
- Anyone can view course information
- Only teachers, admins, and supervisors can modify courses

**course_enrollments table:**
- Students can view their own enrollments
- Teachers can view enrollments for courses they teach
- Admins and supervisors have full access

## Authentication Flow

1. Users authenticate through Supabase Auth
2. Their role is determined from the users table
3. RLS policies restrict data access based on role and relationships

## Notes

- All tables use UUID primary keys for security
- Timestamps track creation and updates for audit purposes
- JSONB columns provide flexible schema for evolving requirements
- Foreign keys maintain referential integrity

For implementation details, refer to the SQL scripts in `lib/docs/database/sql/`.
