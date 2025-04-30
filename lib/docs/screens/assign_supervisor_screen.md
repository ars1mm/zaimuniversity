# AssignSupervisorScreen Documentation

## Overview

**File:** `lib/screens/assign_supervisor_screen.dart`

The `AssignSupervisorScreen` component provides an interface for administrators to create supervisor accounts in the Zaim University Campus Information System. This screen implements a form-based interface for collecting supervisor information and handles the creation of supervisor records in the database.

## Class Structure

### AssignSupervisorScreen (StatefulWidget)

A stateful widget that serves as the entry point for supervisor creation.

**Properties:**
- `routeName`: Static constant string (`/assign_supervisor`) used for navigation.

### _AssignSupervisorScreenState (State)

The state class that manages the form data, validation, and submission process.

**Properties:**
- `_formKey`: GlobalKey for form validation.
- Form field controllers:
  - `_fullNameController`: For supervisor's full name.
  - `_emailController`: For supervisor's email.
  - `_passwordController`: For initial password.
  - `_confirmPasswordController`: For password confirmation.
- `_supabase`: Instance of Supabase client for database operations.
- `_authService`: Instance of AuthService for authentication-related operations.
- `_logger`: Logger instance for debugging and error tracking.
- `_isLoading`: Boolean to track async operations.
- `_obscurePassword` and `_obscureConfirmPassword`: Booleans to toggle password visibility.

## Key Methods

### dispose()
- Properly disposes of all TextEditingController instances to prevent memory leaks.

### _createSupervisor()
- Core method that handles supervisor account creation.
- Validates form input before proceeding.
- Verifies the current user has administrative privileges before allowing supervisor creation.
- Creates a supervisor record in the users table with:
  - Temporary ID (milliseconds timestamp)
  - Email address
  - Full name
  - Supervisor role
  - Pending status
  - Creation timestamp
- Provides feedback to the user through SnackBar notifications.
- Resets the form on successful submission.
- Implements comprehensive error handling.

### build()
- Renders the UI component with a form for supervisor creation.
- Implements detailed field validation logic.
- Provides visual feedback during loading states.
- Includes form fields for:
  - Full Name (required, min 3 characters)
  - Email (required, regex validation)
  - Password (required, min 6 characters)
  - Password Confirmation (must match password)

## User Interface

The screen presents a clean, form-based interface with:
- Clear heading and subheading explaining the purpose
- Properly labeled input fields with icons
- Password visibility toggles
- Field-level validation with helpful error messages
- Full-width submit button with loading indicator
- Success/error feedback via SnackBar

## Form Validation

Implements detailed validation rules for each field:
- Full Name: Required, minimum 3 characters
- Email: Required, regex validation to ensure proper email format
- Password: Required, minimum 6 characters
- Password Confirmation: Required, must match the password field

## Security Considerations

- Verifies administrative privileges before allowing supervisor creation
- Stores temporary ID until proper authentication
- Sets status as 'pending' until account activation
- Password fields have visibility toggles for user convenience while maintaining privacy

## Current Limitations

- The password is collected but not properly stored or sent to the supervisor
- The supervisor needs to use the "Sign Up" flow later to activate their account
- No email notification system is implemented yet
- Uses a timestamp as a temporary ID instead of a proper UUID

## Error Handling

The screen implements comprehensive error handling:
- Form validation to prevent submission of invalid data
- Permission checking to ensure only admins can create supervisors
- Try-catch blocks around Supabase operations
- User feedback through SnackBar notifications

## Dependencies

- Flutter material components
- Supabase Flutter client
- Logger for error tracking
- AuthService for permission verification
- AppConstants for consistent styling
