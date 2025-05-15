import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/teacher_schedule_screen.dart';
import '../screens/student_schedule_screen.dart';
import '../screens/teacher_course_screen.dart';
import '../screens/teacher_grades_screen.dart';

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
      print('DEBUG ROUTE GUARD: User is not logged in, redirecting to login');
      return const LoginScreen();
    }

    // Get user information first to debug
    final user = await _authService.getCurrentUser();
    print('DEBUG ROUTE GUARD: Current user = $user');

    // Get user role
    final userRole = await _authService.getUserRole();
    print('DEBUG ROUTE GUARD: Retrieved user role = "$userRole"');

    if (userRole == null) {
      // If we can't determine role, redirect to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      print('DEBUG ROUTE GUARD: Role is null, redirecting to login');
      return const LoginScreen();
    } // Check if user role is allowed
    // Convert user role to lowercase for case-insensitive comparison
    final userRoleLower = userRole
        .toLowerCase(); // Convert all allowed roles to lowercase for case-insensitive comparison
    final allowedRolesLower = allowedRoles
        .map((role) => role.toLowerCase())
        .toList(); // Always allow teacher role for teacher schedule screen as a hard override
    if (userRoleLower == 'teacher' && targetWidget is TeacherScheduleScreen) {
      print(
          'DEBUG OVERRIDE: Teacher accessing Teacher Schedule Screen - ALLOWING ACCESS');
      return targetWidget;
    }
    // Always allow student role for student schedule screen
    if (userRoleLower == 'student' && targetWidget is StudentScheduleScreen) {
      print(
          'DEBUG OVERRIDE: Student accessing Student Schedule Screen - ALLOWING ACCESS');
      return targetWidget;
    }
    // Always route teachers to their courses screen when they try to access course management
    if (userRoleLower == 'teacher' &&
        targetWidget.runtimeType.toString() == 'CourseManagementScreen') {
      print(
          'DEBUG OVERRIDE: Teacher trying to access CourseManagementScreen - redirecting to TeacherCourseScreen');
      return const TeacherCourseScreen();
    }
    // Always allow teacher role for teacher grades screen
    if (userRoleLower == 'teacher' && targetWidget is TeacherGradesScreen) {
      print(
          'DEBUG OVERRIDE: Teacher accessing Teacher Grades Screen - ALLOWING ACCESS');
      return targetWidget;
    }
    final hasAccess = allowedRolesLower.contains(userRoleLower);

    print(
        'Role check: User role=$userRole (lowercase: $userRoleLower), Allowed roles=$allowedRoles (lowercase: $allowedRolesLower), Has access=$hasAccess'); // More detailed debug log
    print(
        'DEBUG ROUTE GUARD: Target widget type: ${targetWidget.runtimeType}'); // Debug the exact widget type

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
