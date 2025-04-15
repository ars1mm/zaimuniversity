# Base Service Documentation

## Overview
**File:** `lib/services/base_service.dart`

The BaseService is an abstract class that serves as the foundation for all service classes in the application. It provides common functionality and shared resources that other services can utilize.

## Dependencies
- `supabase_flutter`: For database and authentication operations
- `app_constants.dart`: Application-wide constants
- `logger_service.dart`: Logging functionality

## Core Functionality

### Fields
- `supabase`: SupabaseClient instance for database operations
- `auth`: GoTrueClient instance for authentication operations

### Methods

#### Email Validation
```dart
bool isValidEmail(String email)
```
- Validates email format using regex
- Returns true if email is valid, false otherwise
- Used across services for user input validation

#### User Verification
```dart
Future<bool> verifyUserExists(String userId)
```
- Checks if a user exists in the database
- Returns true if user exists, false otherwise
- Used for authorization checks

## Usage
All service classes should extend BaseService to inherit:
- Database connection handling
- Authentication client access
- Common utility methods
- Error handling patterns

## Error Handling
- Implements standard error catching
- Logs errors through LoggerService
- Provides consistent error response format

## Security Considerations
- Validates all input data
- Implements proper error handling
- Maintains secure connection handling 