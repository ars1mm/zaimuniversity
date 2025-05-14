# TeacherScheduleScreen Documentation

## Overview

**File:** `lib/screens/teacher_schedule_screen.dart`

The `TeacherScheduleScreen` component provides a comprehensive interface for teachers to view their teaching schedule within the Zaim University Campus Information System. This screen displays a day-by-day view of all courses the teacher is scheduled to teach, including course details, time slots, and room information.

## Class Structure

### TeacherScheduleScreen (StatefulWidget)

A stateful widget that serves as the entry point for viewing teacher schedules.

**Properties:**
- Static `routeName`: Constant string '/teacher_schedule' for routing

### _TeacherScheduleScreenState (State)

The state class that manages schedule data and UI.

**Properties:**
- `_logger`: Logger instance for structured logging
- `_isLoading`: Boolean flag to track data loading status
- `_scheduleByDay`: Map organizing course schedules by day of the week
- `_weekdays`: List containing all days of the week in order

## Lifecycle Methods

### initState()
- Initializes the component state
- Calls `_loadTeacherSchedule()` to retrieve schedule data

### dispose()
- Performs cleanup when the widget is removed

## Data Loading Methods

### _loadTeacherSchedule()
- Asynchronous method that fetches the teacher's schedule from the database
- Gets the current user ID and corresponding teacher profile
- Retrieves course data with associated schedule information
- Organizes courses by day of the week
- Sorts each day's schedule by start time
- Updates state with structured schedule data
- Handles errors with appropriate UI feedback

## UI Components

### AppBar
- Title: "My Teaching Schedule"
- Refresh button for reloading schedule data

### Schedule Content
- Day-by-day cards with course listings
- Each day clearly labeled with a header
- Empty state messaging for days with no classes
- Detailed course information including:
  - Course title
  - Course code
  - Time slot (start and end times)
  - Room number

## Helper Methods

### _buildScheduleContent()
- Creates the main schedule display as a scrollable list
- Iterates through weekdays to build individual day sections

### _buildDaySchedule()
- Generates a card for a specific day's schedule
- Handles both populated schedules and empty days
- Creates a clean list view of courses with time-based ordering

## Database Integration

The screen relies on two key database tables:
1. `courses`: Contains course information and instructor assignments
2. `course_schedules`: Contains schedule information linked to courses

The relationship between these tables allows for:
- Filtering courses by the current teacher
- Extracting detailed scheduling information
- Organizing data by day and time

## Error Handling

- Try-catch blocks around all database operations
- User feedback through SnackBar notifications when errors occur
- Loading indicators during data retrieval
- Mounted checks to prevent setState calls on unmounted widgets

## Responsive Design

- Scrollable content view for all screen sizes
- Cards and list items that adapt to available width
- Proper spacing and typography for readability
- Clear visual hierarchy for schedule information

## Security Considerations

- Uses authenticated Supabase client for data operations
- Respects row-level security policies on the database
- Only loads data for the currently authenticated teacher

## Dependencies

- Flutter material components
- Supabase client for database operations
- Logger for structured logging
- AppConstants for consistent styling and database references
