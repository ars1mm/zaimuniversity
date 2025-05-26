import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../screens/teacher_course_screen.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'package:logging/logging.dart';

/// A utility class for diagnosing routing issues
class RoutingDiagnostics {
  static final Logger _logger = Logger('RoutingDiagnostics');
  static final AuthService _authService = AuthService();

  /// Logs comprehensive routing diagnostics information
  static Future<void> logRouteDiagnostics(
      String routeName, BuildContext context) async {
    print('');
    print('===== ROUTING DIAGNOSTICS =====');
    print('Route: $routeName');
    print('Context mounted: ${context.mounted}');

    // Auth/user information
    final isLoggedIn = await _authService.isLoggedIn();
    final userRole = await _authService.getUserRole();
    final currentUser = supabase.auth.currentUser;

    print('User logged in: $isLoggedIn');
    print('User role: $userRole');
    print('User ID: ${currentUser?.id}');
    print('User email: ${currentUser?.email}');
    // Route target
    if (routeName == TeacherCourseScreen.routeName) {
      print('Target widget: TeacherCourseScreen');
    } else {
      print('Unknown route name: $routeName');
    }

    // Role checks
    if (userRole != null) {
      final isTeacher =
          userRole.toLowerCase() == AppConstants.roleTeacher.toLowerCase();
      final canAccessTeacherRoutes = [
        AppConstants.roleTeacher.toLowerCase(),
        AppConstants.roleAdmin.toLowerCase(),
        AppConstants.roleSupervisor.toLowerCase()
      ].contains(userRole.toLowerCase());

      print('Is teacher: $isTeacher');
      print('Can access teacher routes: $canAccessTeacherRoutes');
    }

    // Specific route checks
    if (routeName == TeacherCourseScreen.routeName) {
      // Check if the user is a teacher
      final isTeacher = await _authService.isTeacher();
      final isAdmin = await _authService.isAdmin();
      final isSupervisor = await _authService.isSupervisor();
      print('User permissions:');
      print('- Is teacher: $isTeacher');
      print('- Is admin: $isAdmin');
      print('- Is supervisor: $isSupervisor');

      // Verify our route is accessible to current user
      final canAccessTeacherRoutes = isTeacher || isAdmin || isSupervisor;
      print('Can access teacher routes: $canAccessTeacherRoutes');

      // Check if on the current navigation route map
      final routes = Navigator.of(context).widget.onGenerateRoute != null;
      print('Has route generator: $routes');
    }

    /// Add helper for diagnosing course routing issues
    if (routeName.contains('course')) {
      _logger.info('COURSE ROUTING DIAGNOSTICS:');
      _logger.info('- Is teacher: ${await _authService.isTeacher()}');
      _logger.info(
          '- Should access TeacherCourseScreen: ${await _authService.isTeacher()}');
      _logger.info(
          '- Should access CourseManagementScreen: ${await _authService.isAdmin() || await _authService.isSupervisor()}');

      // Get current user data
      final userData = await _authService.getCurrentUser();
      if (userData != null) {
        _logger.info('User data:');
        _logger.info('- ID: ${userData['id']}');
        _logger.info('- Role: ${userData['role']}');
        _logger.info('- Full name: ${userData['full_name']}');
      }
    }

    print('==============================');
    print('');
  }
}
