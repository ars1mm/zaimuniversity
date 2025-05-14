# TeacherScheduleService Documentation

## Overview

**File:** `lib/services/teacher_schedule_service.dart`

The `TeacherScheduleService` provides a comprehensive API for managing teacher schedules within the Zaim University Campus Information System. This service abstracts database operations related to course schedules, providing methods for retrieving, adding, updating, and deleting schedule entries.

## Key Methods

### getTeacherSchedule()

- **Purpose:** Retrieves the current teacher's complete teaching schedule
- **Return Type:** `Future<Map<String, List<Map<String, dynamic>>>>`
- **Return Format:** Map with weekday keys and lists of course entries
- **Process:**
  1. Gets the current authenticated user's ID
  2. Retrieves the corresponding teacher profile
  3. Fetches all courses taught by this teacher, with their schedule information
  4. Organizes schedule data by day of the week
  5. Sorts each day's schedule by start time
- **Error Handling:** Throws exceptions with descriptive messages

### addScheduleEntry()

- **Purpose:** Creates a new course schedule entry
- **Parameters:**
  - `courseId`: ID of the course to schedule
  - `dayOfWeek`: Day of the week (Monday-Sunday)
  - `startTime`: Time the class starts (format: HH:MM)
  - `endTime`: Time the class ends (format: HH:MM)
  - `room`: Room number or identifier
  - `building`: (Optional) Building name or identifier
- **Return Type:** `Future<Map<String, dynamic>>`
- **Return Format:** Success status and created entry data
- **Error Handling:** Returns error information in the result map

### updateScheduleEntry()

- **Purpose:** Modifies an existing schedule entry
- **Parameters:**
  - `scheduleId`: ID of the schedule entry to update
  - `dayOfWeek`: Day of the week
  - `startTime`: Updated start time
  - `endTime`: Updated end time
  - `room`: Updated room
  - `building`: (Optional) Updated building
- **Return Type:** `Future<Map<String, dynamic>>`
- **Return Format:** Success status and error message if applicable
- **Error Handling:** Returns error information in the result map

### deleteScheduleEntry()

- **Purpose:** Removes a schedule entry
- **Parameters:**
  - `scheduleId`: ID of the schedule entry to delete
- **Return Type:** `Future<Map<String, dynamic>>`
- **Return Format:** Success status and error message if applicable
- **Error Handling:** Returns error information in the result map

### getTeacherCourses()

- **Purpose:** Retrieves all courses associated with the current teacher
- **Return Type:** `Future<List<Map<String, dynamic>>>`
- **Return Format:** List of course objects with their details
- **Error Handling:** Throws exceptions with descriptive messages

## Database Integration

The service interacts with two key database tables:
1. `teachers`: For identifying the current teacher's profile
2. `courses`: For accessing courses taught by the teacher
3. `course_schedules`: For managing schedule entries

## Authentication and Security

- Uses the authenticated Supabase client for all database operations
- Only allows teachers to access their own schedules and courses
- Respects row-level security policies defined in the database

## Error Handling

- Implements comprehensive logging through the Logger utility
- Provides detailed error messages with context
- Uses try-catch blocks to handle exceptions gracefully
- Returns structured error responses for client handling

## Usage Example

```dart
// Initialize the service
final scheduleService = TeacherScheduleService();

// Get the teacher's schedule
final schedule = await scheduleService.getTeacherSchedule();

// Add a new schedule entry
final result = await scheduleService.addScheduleEntry(
  courseId: 'course-123',
  dayOfWeek: 'Monday',
  startTime: '10:00',
  endTime: '11:30',
  room: 'A101',
  building: 'Engineering Building',
);

// Check result
if (result['success']) {
  // Schedule entry added successfully
} else {
  // Handle error
  print(result['message']);
}
```

## Last Updated

May 14, 2025
