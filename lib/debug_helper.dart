import 'dart:developer';

class DebugHelper {
  /// Logs details about route navigation for debugging purposes
  static void logRouteNavigation(String routeName, List<String> allowedRoles) {
    log('DEBUG NAVIGATION: Navigating to route: $routeName');
    log('DEBUG NAVIGATION: Allowed roles for route: $allowedRoles');
  }
}
