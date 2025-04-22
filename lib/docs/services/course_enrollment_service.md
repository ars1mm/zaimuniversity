# CourseEnrollmentService Documentation

## Overview
**File:** `lib/services/course_enrollment_service.dart`

The CourseEnrollmentService extends BaseService and handles operations related to course enrollments and materials. It provides functionality for managing student enrollments in courses with proper validation and status tracking.

## Dependencies
- `logging`: For logging operations
- `../constants/app_constants.dart`: For database table names
- `../main.dart`: For global Supabase instance
- `base_service.dart`: For inherited base functionality
- `role_service.dart`: For authorization checks

## Core Functionality

### Properties
- `_logger`: Logger instance for service-specific logging
- `_roleService`: RoleService instance for role-based authorization

### Methods

#### enrollStudent
```dart
Future<Map<String, dynamic>> enrollStudent({
  required String courseId,
  required String studentId,
})
```
- Enrolls a student in a specified course
- Checks if the student is already enrolled to prevent duplicates
- Creates an enrollment record with timestamp and active status
- Returns a response map with success status and message
- Logs the enrollment process and any issues
