# SupabaseService Documentation

## Overview
**File:** `lib/services/supabase_service.dart`

The SupabaseService extends BaseService and provides role-based access control checks and authentication functionality using Supabase. It handles user roles verification, authentication operations, and user management.

## Dependencies
- `supabase_flutter`: For Supabase client functionality
- `../constants/app_constants.dart`: For application constants including roles and table names
- `base_service.dart`: For inherited base functionality
- `logger_service.dart`: For logging operations

## Core Functionality

### Role Management

#### _getUserRole
```dart
Future<String?> _getUserRole()
```
- Private method to retrieve the current user's role from the database
- Queries the users table for the role field of the authenticated user
- Returns a String representing the user role or null if no user is authenticated
- Logs any errors during the operation

#### isAdmin
```dart
Future<bool> isAdmin()
```
- Checks if the current user has admin role
- Returns true if the user role matches AppConstants.roleAdmin, false otherwise

#### isTeacher
```dart
Future<bool> isTeacher()
```
- Checks if the current user has teacher role
- Returns true if the user role matches AppConstants.roleTeacher, false otherwise

#### isSupervisor
```dart
Future<bool> isSupervisor()
```
- Checks if the current user has supervisor role
- Returns true if the user role matches AppConstants.roleSupervisor, false otherwise

#### isStudent
```dart
Future<bool> isStudent()
```
- Checks if the current user has student role
- Returns true if the user role matches AppConstants.roleStudent, false otherwise

### User Management

#### getCurrentUser
```dart
Future<User?> getCurrentUser()
```
- Retrieves the currently authenticated Supabase user
- Returns User object or null if no user is authenticated
- Logs any errors that occur during retrieval

### Authentication

#### signUp
```dart
Future<AuthResponse> signUp({required String email, required String password})
```
- Creates a new user account with the provided email and password
- Formats and validates email address
- Adds @zaim.edu.tr domain to usernames without @ symbol
- Returns AuthResponse with user data and session
- Handles authentication exceptions with detailed logging
