# CourseService Documentation

## Overview
**File:** `lib/services/course_service.dart`

The CourseService class provides functionality for managing courses in the Zaim University application. It handles operations like retrieving course listings and adding new courses with proper authorization checks, department association, and data validation.

## Dependencies
- `supabase_flutter`: For Supabase client functionality
- `logging`: For logging operations
- `auth_service.dart`: For authentication and authorization checks

## Core Functionality

### Properties
- `_authService`: Instance of AuthService for authorization checks
- `_supabase`: Supabase client instance for database operations
- `_logger`: Logger instance for service-specific logging

### Methods

#### getCourses
```dart
Future<List<Map<String, dynamic>>> getCourses()
```
- Retrieves all courses from the database (admin only)
- Validates user has admin privileges
- Performs joined query with departments and instructor data
- Returns a list of course data including related information
- Throws exceptions for unauthorized access or retrieval errors
- Logs the retrieval process and results

#### addCourse
```dart
Future<Map<String, dynamic>> addCourse({
  required String title,
  required int capacity,
  required String department,
  String? instructorId,
  String? description,
  String? semester,
  String status = 'active',
  Map<String, dynamic>? schedule,
})
```
- Adds a new course to the system (admin only)
- Validates user has admin privileges
- Finds existing department or creates a new one if needed
- Creates course record with comprehensive data model
- Tracks creation metadata including timestamps and creator
- Returns a response map with success status and message
- Logs the course creation process and any issues
