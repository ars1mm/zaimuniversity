import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/teacher_schedule_screen.dart';
import '../screens/student_schedule_screen.dart';
import '../screens/teacher_course_screen.dart';
import '../screens/teacher_grades_screen.dart';
import '../services/logger_service.dart';

/// A utility class that protects routes based on user roles
class RouteGuard {
  static final AuthService _authService = AuthService();
  static final _logger = LoggerService.getLoggerForName('RouteGuard');

  /// Checks if the user has the required role to access a route
  /// Returns the appropriate widget based on authorization
  static Future<Widget> protectRoute({
    required Widget targetWidget,
    required BuildContext context,
    required List<String> allowedRoles,
  }) async {
    _logger.fine('Called for widget: ${targetWidget.runtimeType}');
    _logger.fine('Allowed roles: $allowedRoles');

    // Check if user is logged in
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      _logger.fine('User is not logged in, redirecting to login');
      return const LoginScreen();
    }

    // Get user information first to debug
    final user = await _authService.getCurrentUser();
    _logger.fine('Current user = $user');

    // Get user role
    final userRole = await _authService.getUserRole();
    _logger.fine('Retrieved user role = "$userRole"');

    if (userRole == null) {
      // If we can't determine role, redirect to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      _logger.warning('Role is null, redirecting to login');
      return const LoginScreen();
    } // Check if user role is allowed
    // Convert user role to lowercase for case-insensitive comparison
    final userRoleLower = userRole
        .toLowerCase(); // Convert all allowed roles to lowercase for case-insensitive comparison
    final allowedRolesLower = allowedRoles
        .map((role) => role.toLowerCase())
        .toList(); // Always allow teacher role for teacher schedule screen as a hard override
    if (userRoleLower == 'teacher' && targetWidget is TeacherScheduleScreen) {
      _logger
          .fine('Teacher accessing Teacher Schedule Screen - ALLOWING ACCESS');
      return targetWidget;
    }
    // Always allow student role for student schedule screen
    if (userRoleLower == 'student' && targetWidget is StudentScheduleScreen) {
      _logger
          .fine('Student accessing Student Schedule Screen - ALLOWING ACCESS');
      return targetWidget;
    }
    // Always route teachers to their courses screen when they try to access course management
    if (userRoleLower == 'teacher' &&
        targetWidget.runtimeType.toString() == 'CourseManagementScreen') {
      _logger.fine(
          'Teacher trying to access CourseManagementScreen - redirecting to TeacherCourseScreen');
      return const TeacherCourseScreen();
    }
    // Always allow teacher role for teacher grades screen
    if (userRoleLower == 'teacher' && targetWidget is TeacherGradesScreen) {
      _logger.fine('Teacher accessing Teacher Grades Screen - ALLOWING ACCESS');
      return targetWidget;
    }
    final hasAccess = allowedRolesLower.contains(userRoleLower);

    _logger.fine(
        'Role check: User role=$userRole (lowercase: $userRoleLower), Allowed roles=$allowedRoles (lowercase: $allowedRolesLower), Has access=$hasAccess'); // More detailed debug log
    _logger.fine(
        'Target widget type: ${targetWidget.runtimeType}'); // Debug the exact widget type

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
