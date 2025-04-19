import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';

class AuthMiddleware {
  static final AuthService _authService = AuthService();
  static final _logger = LoggerService();
  static const String _tag = 'AuthMiddleware';

  /// Checks if the current user has admin access
  /// Returns true if the user is logged in and has admin role
  static Future<bool> isAdmin(BuildContext context) async {
    _logger.debug('Checking admin access', tag: _tag);
    final hasAccess = await _authService.isAdmin();

    // Only proceed with context operations if access is denied and context is still mounted
    if (!hasAccess && context.mounted) {
      _logger.warning('Unauthorized admin access attempt', tag: _tag);
      // Show unauthorized access message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unauthorized access. Admin privileges required.'),
          backgroundColor: Colors.red,
        ),
      );

      // Navigate back or to login page
      Navigator.of(context).pop();
    }

    return hasAccess;
  }

  /// Function to wrap an admin-only widget
  /// If user is not admin, displays an unauthorized message
  static Widget adminOnly({
    required Widget child,
    Widget? unauthorizedFallback,
  }) {
    return FutureBuilder<bool>(
      future: _authService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final isAdmin = snapshot.data ?? false;

        if (isAdmin) {
          return child;
        } else {
          return unauthorizedFallback ??
              const Center(
                child: Text(
                  'Unauthorized: Admin access required',
                  style: TextStyle(color: Colors.red),
                ),
              );
        }
      },
    );
  }
}
