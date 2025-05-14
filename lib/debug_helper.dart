import 'package:flutter/material.dart';

class DebugHelper {
  /// Logs details about route navigation for debugging purposes
  static void logRouteNavigation(String routeName, List<String> allowedRoles) {
    print('DEBUG NAVIGATION: Navigating to route: $routeName');
    print('DEBUG NAVIGATION: Allowed roles for route: $allowedRoles');
  }
}
