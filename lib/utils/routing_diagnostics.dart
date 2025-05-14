import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../screens/teacher_course_screen.dart';
import '../services/auth_service.dart';
import '../main.dart';

/// A utility class for diagnosing routing issues
class RoutingDiagnostics {
  static final AuthService _authService = AuthService();
  
  /// Logs comprehensive routing diagnostics information
  static Future<void> logRouteDiagnostics(String routeName, BuildContext context) async {
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
    Widget? targetWidget;
    if (routeName == TeacherCourseScreen.routeName) {
      targetWidget = const TeacherCourseScreen();
      print('Target widget: TeacherCourseScreen');
    } else {
      print('Unknown route name: $routeName');
    }
    
    // Role checks
    if (userRole != null) {
      final isTeacher = userRole.toLowerCase() == AppConstants.roleTeacher.toLowerCase();
      final canAccessTeacherRoutes = [
        AppConstants.roleTeacher.toLowerCase(),
        AppConstants.roleAdmin.toLowerCase(),
        AppConstants.roleSupervisor.toLowerCase()
      ].contains(userRole.toLowerCase());
      
      print('Is teacher: $isTeacher');
      print('Can access teacher routes: $canAccessTeacherRoutes');
    }
    
    print('==============================');
    print('');
  }
} 