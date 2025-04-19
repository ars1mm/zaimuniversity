import 'package:logging/logging.dart';

/// A service class that provides logging functionality using Flutter's logging framework.
/// This is a singleton class to ensure consistent logging across the application.
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  final Map<String, Logger> _loggers = {};

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal() {
    // Initialize the root logger
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('Stack trace: ${record.stackTrace}');
      }
    });
  }

  /// Get a logger instance for a specific class or component
  Logger getLogger(String name) {
    if (!_loggers.containsKey(name)) {
      _loggers[name] = Logger(name);
    }
    return _loggers[name]!;
  }

  /// Log an info message
  void info(String message, {String? tag}) {
    final logger = tag != null ? getLogger(tag) : Logger.root;
    logger.info(message);
  }

  /// Log a warning message
  void warning(String message, {String? tag}) {
    final logger = tag != null ? getLogger(tag) : Logger.root;
    logger.warning(message);
  }

  /// Log an error message
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logger = tag != null ? getLogger(tag) : Logger.root;
    logger.severe(message, error, stackTrace);
  }

  /// Log a debug message
  void debug(String message, {String? tag}) {
    final logger = tag != null ? getLogger(tag) : Logger.root;
    logger.fine(message);
  }
} 