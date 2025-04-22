# CourseServiceImpl Documentation

## Overview
**File:** `lib/services/course_service_impl.dart`

The CourseServiceImpl class extends BaseService and provides concrete implementation for course-related database operations. It handles retrieving course listings and adding new courses with proper authorization checks, department management, and data validation.

## Dependencies
- `logging`: For logging operations
- `../constants/app_constants.dart`: For database table names and constants
- `../main.dart`: For global Supabase instance
- `base_service.dart`: For inherited base functionality
- `role_service.dart`: For authorization checks

## Core Functionality

### Properties
- `_logger`: Logger instance for service-specific logging
- `_roleService`: RoleService instance for role-based authorization

### Methods

#### getCourses
```dart
Future<List<Map<String, dynamic>>> getCourses()
```
- Retrieves all courses from the database (admin only)
- Validates user has admin privileges using RoleService
- Performs joined query to include department and instructor information
- Returns a list of course data with related information
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
- Validates user has admin privileges using RoleService
- Finds existing department or creates a new one if needed
- Creates course record with comprehensive data model
- Includes metadata like creation timestamp and creator ID
- Returns a response map with success status and message
- Logs the course creation process and any issues
