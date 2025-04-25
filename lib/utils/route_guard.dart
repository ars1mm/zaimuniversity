import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

/// A utility class that protects routes based on user roles
class RouteGuard {
  static final AuthService _authService = AuthService();

  /// Checks if the user has the required role to access a route
  /// Returns the appropriate widget based on authorization
  static Future<Widget> protectRoute({
    required Widget targetWidget,
    required BuildContext context,
    List<String> allowedRoles = const ['admin'],
  }) async {
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
    if (allowedRoles.contains(userRole)) {
      return targetWidget;
    } else {
      // User doesn't have access, show unauthorized page or snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You don\'t have permission to access this page'),
          backgroundColor: Colors.red,
        ),
      );
      // Return to previous page
      Navigator.of(context).pop();
      return const LoginScreen();
    }
  }
}
