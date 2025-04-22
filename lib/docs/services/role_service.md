# RoleService Documentation

## Overview
**File:** `lib/services/role_service.dart`

The RoleService extends BaseService and provides functionality for checking user roles in the system. It handles verification of user types such as admin, teacher, supervisor, and student based on their role stored in the database.

## Dependencies
- `../constants/app_constants.dart`: For role constants and table names
- `base_service.dart`: For inherited base functionality
- `logger_service.dart`: For logging operations

## Core Functionality

### Methods

#### isAdmin
```dart
Future<bool> isAdmin()
```
- Checks if the current authenticated user has admin role
- Queries the users table for the user's role
- Returns true if the role matches the admin constant
- Logs the checking process and result
- Returns false if no user is authenticated or an error occurs

#### isTeacher
```dart
Future<bool> isTeacher()
```
- Checks if the current authenticated user has teacher role
- Queries the users table for the user's role
- Returns true if the role matches the teacher constant
- Logs the checking process and result
- Returns false if no user is authenticated or an error occurs

#### isSupervisor
```dart
Future<bool> isSupervisor()
```
- Checks if the current authenticated user has supervisor role
- Queries the users table for the user's role
- Returns true if the role matches the supervisor constant
- Logs the checking process and result
- Returns false if no user is authenticated or an error occurs

#### isStudent
```dart
Future<bool> isStudent()
```
- Checks if the current authenticated user has student role
- Queries the users table for the user's role
- Returns true if the role matches the student constant
- Logs the checking process and result
- Returns false if no user is authenticated or an error occurs
