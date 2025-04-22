# AuthServiceImpl Documentation

## Overview
**File:** `lib/services/auth_service_impl.dart`

The AuthServiceImpl class extends BaseService and provides concrete implementation of authentication operations using Supabase. It handles user signup, signin, signout operations with robust error handling and validation.

## Dependencies
- `supabase_flutter`: For authentication functionality
- `base_service.dart`: For base service functionality
- `logger_service.dart`: For logging operations

## Core Functionality

### Methods

#### signUp
```dart
Future<AuthResponse> signUp({required String email, required String password})
```
- Creates a new user account with the provided email and password
- Performs email validation and sanitization
- Creates fallback emails for invalid formats using @zaim.edu.tr domain
- Returns AuthResponse with user data
- Handles various authentication exceptions with detailed logging
- Stores original email in user metadata

#### signIn
```dart
Future<AuthResponse> signIn({required String email, required String password})
```
- Authenticates a user with email and password credentials
- Returns AuthResponse containing user data and session information
- Logs authentication attempts and results
- Throws exceptions on authentication failure for handling by caller

#### signOut
```dart
Future<void> signOut()
```
- Signs out the currently authenticated user
- Clears authentication session
- Logs the signout process
- Throws exceptions on signout failure

#### getCurrentUser
```dart
Future<User?> getCurrentUser()
```
- Retrieves the currently authenticated user
- Returns Supabase User object or null if no user is authenticated
- Logs user retrieval with email when available
- Handles and logs any exceptions
