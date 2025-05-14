import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/teacher_schedule_screen.dart';
import '../screens/teacher_course_screen.dart';

/// A utility class that protects routes based on user roles
class RouteGuard {
  static final AuthService _authService = AuthService();

  /// Checks if the user has the required role to access a route
  /// Returns the appropriate widget based on authorization
  static Future<Widget> protectRoute({
    required Widget targetWidget,
    required BuildContext context,
    required List<String> allowedRoles,
  }) async {
    print('DEBUG ROUTE GUARD: Called for widget: ${targetWidget.runtimeType}');
    print('DEBUG ROUTE GUARD: Allowed roles: $allowedRoles');

    // Check if user is logged in
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      return const LoginScreen();
    }

    // Get user role
    final userRole = await _authService.getUserRole();
    if (userRole == null) {
      // If we can't determine role, redirect to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return const LoginScreen();
    } 
    
    // Check if user role is allowed
    // Convert user role to lowercase for case-insensitive comparison
    final userRoleLower = userRole.toLowerCase();
    // Convert all allowed roles to lowercase for case-insensitive comparison
    final allowedRolesLower = allowedRoles
        .map((role) => role.toLowerCase())
        .toList(); 
    
    // Special handling for teacher screens
    if (userRoleLower == 'teacher') {
      // Always allow teacher to access TeacherScheduleScreen
      if (targetWidget is TeacherScheduleScreen) {
        print('DEBUG OVERRIDE: Teacher accessing Teacher Schedule Screen - ALLOWING ACCESS');
        return targetWidget;
      }
      
      // Always allow teacher to access TeacherCourseScreen
      if (targetWidget is TeacherCourseScreen) {
        print('DEBUG OVERRIDE: Teacher accessing Teacher Course Screen - ALLOWING ACCESS');
        return targetWidget;
      }
    }

    final hasAccess = allowedRolesLower.contains(userRoleLower);

    print('Role check: User role=$userRole (lowercase: $userRoleLower), ' +
          'Allowed roles=$allowedRoles (lowercase: $allowedRolesLower), ' +
          'Has access=$hasAccess, ' +
          'Widget=${targetWidget.runtimeType}');

    if (hasAccess) {
      return targetWidget;
    } else {
      // User doesn't have access, show unauthorized page or snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Access denied. Your role ($userRole) does not have permission to access this page.'),
          backgroundColor: Colors.red,
        ),
      );
      // Return to previous page
      Navigator.of(context).pop();
      return const LoginScreen();
    }
  }
}
