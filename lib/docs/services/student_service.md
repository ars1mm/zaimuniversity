# StudentService Documentation

## Overview
**File:** `lib/services/student_service.dart`

The StudentService class handles all student-related operations in the application, including adding new students, generating default passwords, and retrieving student records. It implements role-based access control to ensure only authorized users can perform these operations.

## Dependencies
- `../constants/app_constants.dart`: For application constants
- `../main.dart`: For global Supabase instance
- `../models/user.dart`: For User model
- `auth_service.dart`: For authentication and authorization
- `logger_service.dart`: For logging operations
- `supabase_service.dart`: For underlying Supabase operations

## Core Functionality

### Methods

#### addStudent
```dart
Future<Map<String, dynamic>> addStudent({
  required String name,
  required String email,
  required String studentId,
  required String department,
  required int enrollmentYear,
  String? password,
})
```
- Adds a new student to the system (admin only)
- Performs several steps:
  1. Verifies admin privileges
  2. Creates auth account with email and password (default if not provided)
  3. Creates user record with student role
  4. Finds or creates department
  5. Adds student details with enrollment information
- Returns a response map with success status, message, and data
- Includes comprehensive logging throughout the process

#### generateDefaultPassword
```dart
String generateDefaultPassword(String studentId)
```
- Generates a default password for new students based on their student ID
- Uses a pattern of 'IZU' + first 4 characters of student ID + '!'
- Logs the password generation (but not the password itself)

#### getAllStudents
```dart
Future<Map<String, dynamic>> getAllStudents()
```
- Retrieves a list of all students in the system (admin only)
- Verifies admin privileges
- Delegates to SupabaseService for database operations
- Processes student data to combine with user data
- Returns a response map with success status, message, and list of User objects
- Includes logging for the operation and any errors
