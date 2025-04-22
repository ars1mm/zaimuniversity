# UserService Documentation

## Overview
**File:** `lib/services/user_service.dart`

The UserService extends BaseService and handles all user-related database operations. It provides methods for creating, updating, retrieving, and deleting user records in the application's database.

## Dependencies
- `../constants/app_constants.dart`: For database table names
- `base_service.dart`: For inherited base functionality
- `logger_service.dart`: For logging operations

## Core Functionality

### Methods

#### createUser
```dart
Future<Map<String, dynamic>> createUser({
  required String email,
  required String fullName,
  required String role,
  required String userId,
  String status = 'active',
})
```
- Creates a new user record in the database
- Takes email, fullName, role, userId, and optional status parameters
- Sets creation and update timestamps automatically
- Returns a response map with success status, message, and user data
- Logs the creation process and any errors

#### updateUser
```dart
Future<Map<String, dynamic>> updateUser({
  required String userId,
  String? email,
  String? fullName,
  String? role,
  String? status,
})
```
- Updates an existing user record with the specified fields
- Requires userId and accepts optional parameters for fields to update
- Updates timestamp automatically
- Returns a response map with success status and message
- Logs the update process and any errors

#### getUserById
```dart
Future<Map<String, dynamic>> getUserById(String userId)
```
- Retrieves a user record by their unique ID
- Returns a response map with success status, message, and user data
- Logs the retrieval process and any errors

#### deleteUser
```dart
Future<Map<String, dynamic>> deleteUser(String userId)
```
- Deletes a user record by their unique ID
- Returns a response map with success status and message
- Logs the deletion process and any errors
