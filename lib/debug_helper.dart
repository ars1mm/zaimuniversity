import 'package:logging/logging.dart';

class DebugHelper {
  static final _logger = Logger('DebugHelper');

  /// Logs details about route navigation for debugging purposes
  static void logRouteNavigation(String routeName, List<String> allowedRoles) {
    _logger.fine('Navigating to route: $routeName');
    _logger.fine('Allowed roles for route: $allowedRoles');
  }
}
