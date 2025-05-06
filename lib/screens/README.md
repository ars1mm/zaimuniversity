# Screens Overview

This directory contains all the screens (pages) of the Zaim University Campus Information System application.

## Main Screens

- **`login_screen.dart`**: Authentication screen where users can sign in
- **`admin_dashboard.dart`**: Main dashboard for administrators
- **`profile_screen.dart`**: User profile screen for viewing/editing personal info
- **`profile_management_screen.dart`**: Admin screen for managing all user profiles

## Student Management

- **`add_student_screen.dart`**: Form for adding new students
- **`student_management_screen.dart`**: List and management of students

## Teacher Management

- **`add_teacher_screen.dart`**: Form for adding new teachers
- **`teacher_management_screen.dart`**: List and management of teachers
- **`create_supervisor_screen.dart`**: Form for creating supervisor accounts
- **`assign_supervisor_screen.dart`**: Assign supervisors to departments/courses

## Course Management

- **`course_management_screen.dart`**: Overall course management
- **`create_course_screen.dart`**: Form for creating new courses
- **`manage_courses_screen.dart`**: List and management of courses

## Department Management

- **`department_management_screen.dart`**: Department management
- **`create_department_screen.dart`**: Form for creating new departments

## Profile Management

The `profile_management_screen.dart` is a dedicated screen for managing user profiles. Key features:

- View and search all users (admin only)
- Upload and manage profile pictures
- Integration with Supabase storage bucket "profile-images"
- RLS (Row Level Security) policies enforcement:
  - Regular users can only manage their own profile
  - Admins can manage any user profile
  - Images are stored in user-specific folders in the bucket
  
For more details on the profile management implementation and RLS policies,
see the documentation in `/docs/profile_management.md` and the SQL setup in `/docs/supabase_rls_profiles.sql`.
