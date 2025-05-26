# Zaim University Database Schema

This document outlines the database schema used in the Zaim University Campus Information System.

## Tables Overview

As of May 16, 2025, the following tables exist in the database:

| Table Name            | Description |
|-----------------------|-------------|
| course_approvals      | Stores course approval workflows |
| course_materials      | Contains learning materials associated with courses |
| courses               | Main table for course information |
| exams_schedule        | Schedule information for exams |
| exams_score           | Student scores for various exams |
| homework_submissions  | Student homework submissions |
| news                  | Campus news and announcements |
| profiles              | User profile information |
| course_enrollments    | Maps students to courses they are enrolled in |
| departments           | Academic departments |
| homework_assignments  | Homework assignments for courses |
| students              | Student-specific information |
| supervisors           | Supervisor-specific information |
| teachers              | Teacher-specific information |
| transcripts           | Student academic transcripts |
| users                 | Main user account information |
| course_schedules      | Course timing and location information |

## Relationships

### User-Related Tables
- `users` is the main table that stores authentication information
- `profiles` contains extended user information
  - Columns: id (UUID), bio (TEXT), profile_picture (TEXT), social_links (JSON)
- `students`, `teachers`, and `supervisors` extend the users table with role-specific information

### Course-Related Tables
- `courses` is the main table for course information
- `course_enrollments` connects students to courses
- `course_materials` stores learning resources for courses
  - Columns: id (UUID), course_id (UUID), title (TEXT), description (TEXT), file_url (TEXT), file_type (TEXT), uploaded_by (UUID), uploaded_at (TIMESTAMPTZ)
- `course_schedules` contains timing and location information
- `course_approvals` manages the approval workflow for courses

### Academic Assessment Tables
- `homework_assignments` stores assignments given to students
- `homework_submissions` tracks student submissions for assignments
  - Columns: id (UUID), homework_id (UUID), student_id (UUID), submission_url (TEXT), submitted_at (TIMESTAMPTZ), score (DOUBLE PRECISION), feedback (TEXT), graded_by (UUID), graded_at (TIMESTAMPTZ)
- `exams_schedule` contains information on examination timing
  - Columns: id (UUID), course_id (UUID), exam_date (TIMESTAMP), duration (INTEGER)
- `exams_score` records student performance on exams
  - Columns: id (UUID), exam_id (UUID), student_id (UUID), score (DOUBLE PRECISION), graded_at (TIMESTAMP)
- `transcripts` maintains official academic records
- `news` stores campus news and announcements
  - Columns: id (UUID), title (TEXT), content (TEXT), created_at (TIMESTAMP), updated_at (TIMESTAMP)

## Row-Level Security (RLS)

Several tables implement Row-Level Security policies:
- `users`: Limited access based on user role
- `students`: Students can only access their own information
- `teachers`: Teachers can access their own information and information related to courses they teach
- `courses`: Access varies based on role and relationship to the course

## Functions

The database includes several functions that support these tables:
- User role and access management functions
- Schedule management functions
- Data insertion/update functions with proper security checks

## Notes

- All tables have appropriate timestamps for tracking creation and updates
- Many tables use UUID as primary keys for security
- JSON/JSONB columns are used for flexible data storage in several tables

---

For detailed SQL implementations, please refer to the installation scripts in `lib/docs/database/sql/`.
