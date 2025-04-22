# StudentServiceImpl Documentation

## Overview
**File:** `lib/services/student_service_impl.dart`

The StudentServiceImpl class extends BaseService and handles student-specific database operations. It provides low-level implementation for student management operations including creating student records and retrieving student data with related information.

## Dependencies
- `../constants/app_constants.dart`: For application constants and table names
- `../main.dart`: For global Supabase instance
- `base_service.dart`: For inherited base functionality
- `logger_service.dart`: For logging operations

## Core Functionality

### Methods

#### addStudent
```dart
Future<Map<String, dynamic>> addStudent({
  required String name,
  required String email,
  required String studentId,
  required String departmentId,
  required String userId,
  String? address,
  Map<String, dynamic>? contactInfo,
  DateTime? enrollmentDate,
})
```
- Creates a student record in the database
- Verifies that the user record exists in the users table and creates it if needed
- Creates linked student record with department association and academic information
- Sets default academic standing to 'good'
- Returns a response map with success status, message, and student data
- Includes comprehensive logging throughout the process

#### getAllStudents
```dart
Future<Map<String, dynamic>> getAllStudents()
```
- Retrieves all student records from the database
- Performs a complex join query across users, students, and departments tables
- Returns structured student data including related department information
- Includes logging for the retrieval process and any errors
