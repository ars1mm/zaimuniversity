# CourseManagementScreen Documentation

## Overview

**File:** `lib/screens/course_management_screen.dart`

The `CourseManagementScreen` component provides a comprehensive interface for managing courses within the Zaim University Campus Information System. This screen enables administrators and authorized personnel to view, search, create, edit, and delete course records. It implements a responsive UI with advanced filtering capabilities and comprehensive CRUD operations for course management.

## Class Structure

### CourseManagementScreen (StatefulWidget)

A stateful widget that serves as the entry point for the course management interface.

**Properties:**
- None - The CourseManagementScreen takes no explicit parameters as it's designed to be a standalone management screen.

### _CourseManagementScreenState (State)

The state class that manages the course data, UI interactions, and CRUD operations.

**Properties:**
- `_courseService`: Instance of CourseService for course data operations.
- `_supabase`: SupabaseClient instance for direct database interactions.
- `_courses`: List of Map<String, dynamic> containing all course records.
- `_departments`: List of Map<String, dynamic> containing all department records for dropdown selection.
- `_isLoading`: Boolean flag to track asynchronous operations and display loading indicators.
- `_searchQuery`: String to store the current search query for filtering courses.
- `_formKey`: GlobalKey<FormState> for form validation in dialogs.
- Form field controllers:
  - `_courseNameController`: For course title.
  - `_courseCodeController`: For course code/semester.
  - `_creditController`: For course capacity.
  - `_departmentController`: For department name.
  - `_descriptionController`: For course description.
  - `_searchCodeController`: For additional search functionality.
- `_selectedDepartmentId`: String to track the currently selected department ID.
- `_logger`: Logger instance for debugging and error tracking.

## Lifecycle Methods

### initState()
- Initializes the component state.
- Calls `_loadCourses()` to populate the course list.
- Calls `_loadDepartments()` to populate the department dropdown options.

### dispose()
- Properly disposes of all TextEditingController instances to prevent memory leaks.
- Controllers disposed: `_courseNameController`, `_courseCodeController`, `_creditController`, `_departmentController`, `_descriptionController`, and `_searchCodeController`.

## Data Loading Methods

### _loadCourses()
- Asynchronous method that fetches all course data from the CourseService.
- Updates the `_courses` list with formatted course information.
- Sets `_isLoading` to appropriate values before and after the operation.
- Handles errors with appropriate UI feedback through SnackBar notifications.
- Ensures mounted check to prevent setState calls after widget disposal.

### _loadDepartments()
- Asynchronous method that fetches department data directly from Supabase.
- Uses the AppConstants.tableDepartments reference for consistency.
- Logs the loading process and response using structured logging.
- Transforms the response into a format suitable for dropdown selection.
- Sets each department record with 'id' and 'name' properties.
- Handles errors with appropriate UI feedback through SnackBar notifications.
- Implements mounted check to prevent setState calls after widget disposal.

## Data Filtering

### _filteredCourses (getter)
- Computed property that filters the `_courses` list based on the current `_searchQuery`.
- Returns the full list when no search query is present.
- When a search query exists, performs case-insensitive filtering on:
  - Course title
  - Department name
  - Semester information
- Returns a new list containing only courses that match the search criteria.

## Dialog Methods

### _showAddCourseDialog()
- Displays a modal dialog for adding a new course.
- Resets all form controllers to ensure a clean form.
- Contains a complex form with multiple validated fields:
  - Course code (required)
  - Course title (required)
  - Capacity (required, numeric validation)
  - Department (dropdown selection, required)
  - Description (optional, multiline)
- Implements form validation through the `_formKey`.
- On submission, calls the CourseService.addCourse method with all form data.
- Provides appropriate feedback based on the operation result.
- Updates the course list upon successful creation.
- Handles mounted state to prevent setState calls after widget disposal.

### _showEditCourseDialog(int index)
- Displays a modal dialog for editing an existing course.
- Pre-populates all form fields with the current course data.
- Handles special initialization for department selection:
  - Matches the department name to find the correct department ID
  - Provides fallback for missing departments
- Includes status selection dropdown with predefined options:
  - active
  - pending
  - rejected
  - completed
  - cancelled
- Implements detailed form validation for all fields.
- On submission, calls CourseService.updateCourse with all form data.
- Provides appropriate feedback based on the operation result.
- Updates the course list upon successful update.
- Includes comprehensive error handling.

### _confirmDeleteCourse(int index)
- Displays a confirmation dialog before course deletion.
- Shows warning message with course name to prevent accidental deletions.
- Implements a red-colored delete button to indicate destructive action.
- On confirmation, calls CourseService.deleteCourse with the course ID.
- Updates the local course list upon successful deletion.
- Provides appropriate feedback through SnackBar notifications.
- Implements proper error handling and loading state management.

## UI Components

### AppBar
- Title: "Course Management"
- Back button for navigation to previous screen
- Refresh button with tooltip for reloading course data

### Search and Add Section
- Search text field with icon and debounced filtering
- "Add Course" button with icon for quick course creation
- Responsive row layout for proper spacing

### Course Listing
- Responsive layout with loading indicator when data is being fetched
- Empty state message when no courses match the search criteria
- ListView.builder for efficient rendering of potentially large lists
- Card-based design for each course with:
  - Course title in bold
  - Department information
  - Capacity information
  - Semester information
  - Truncated description (limited to 2 lines)
  - Edit and Delete action buttons with color-coding and tooltips

### FloatingActionButton
- Provides an additional access point for creating new courses
- Consistent with Material Design guidelines
- Displays add icon with tooltip

## Input Validation Logic

### Course Code/Semester
- Required field
- No specific format restriction to allow flexible semester naming

### Course Title
- Required field
- No specific length restriction

### Capacity
- Required field
- Must be a valid integer (uses int.tryParse validation)

### Department
- Required field
- Must be selected from the provided dropdown

### Description
- Optional field
- Supports multiline input
- No specific length restriction

## CRUD Operations

### Create (Add Course)
- Validates all required fields
- Collects form data and passes to CourseService.addCourse
- Provides success or error feedback
- Reloads course list upon success

### Read (View Courses)
- Loads courses on initialization
- Implements search functionality
- Displays course details in a clean, readable format
- Shows loading indicator during data fetching

### Update (Edit Course)
- Pre-populates form with existing course data
- Validates all required fields
- Passes updated data to CourseService.updateCourse
- Provides success or error feedback
- Reloads course list upon successful update

### Delete (Delete Course)
- Requires confirmation through dialog
- Provides clear warning about the irreversible action
- Calls CourseService.deleteCourse on confirmation
- Updates UI immediately on successful deletion
- Shows appropriate feedback messages

## Error Handling

The screen implements comprehensive error handling:
- Try-catch blocks around all asynchronous operations
- Mounted checks to prevent setState calls on unmounted widgets
- User feedback through SnackBar notifications
- Logging of both informational events and errors
- Form validation to prevent submission of invalid data
- Fallback values for missing or null data in course records

## Responsive Design

The interface adapts to various screen sizes through:
- Flexible row layouts for search and buttons
- Expanded widgets to utilize available space
- Scrollable content for overflow management
- Card-based design that works on various screen widths
- ScrollView wrappers for forms in dialogs to handle keyboard display

## Performance Considerations

- Efficient use of ListView.builder for rendering only visible items
- Proper disposal of controllers to prevent memory leaks
- State updates limited to necessary components
- Computed filteredCourses property to avoid redundant filtering

## Security Considerations

- Uses CourseService abstraction for data operations
- No direct exposure of database structure in UI
- Proper validation of input data
- Confirmation required for destructive operations

## Code Organization

- Clear separation of UI and data operations
- Logical grouping of methods by functionality
- Consistent naming conventions
- Comprehensive comments and type annotations
- Proper state management through setState

## Dependencies

- Flutter material components for UI
- CourseService for course data operations
- Supabase client for department data
- Logger for structured logging
- AppConstants for consistent styling and database references
