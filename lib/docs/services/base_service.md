# BaseService Documentation

## Overview
**File:** `lib/services/base_service.dart`

The BaseService is an abstract class that provides common functionality and resources for all service classes in the application. It maintains a central instance of the Supabase client and logging mechanisms to ensure consistent behavior across services.

## Dependencies
- `supabase_flutter`: For Supabase client functionality
- `logging`: For logging operations

## Core Functionality

### Properties
- `_logger`: A Logger instance for internal service logging
- `supabase`: The main SupabaseClient instance shared across all services
- `auth`: The GoTrueClient instance for authentication operations

### Methods

#### isValidEmail
```dart
bool isValidEmail(String email)
```
- Validates if an email string meets Supabase's basic requirements
- Checks if email is not empty and contains the '@' symbol
- Returns a boolean indicating if the email is valid

#### verifyUserExists
```dart
Future<bool> verifyUserExists(String userId)
```
- Verifies if a user with the given userId exists in the database
- Queries the 'users' table with the provided userId
- Returns true if the user exists, false otherwise
- Logs any errors during verification
