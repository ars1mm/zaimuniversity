// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// A service that handles logging throughout the application.
/// It configures a hierarchical logging system with different levels
/// and supports both console output and file logging.
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  static Logger? _rootLogger;
  static File? _logFile;
  static IOSink? _logSink;

  // Singleton pattern
  factory LoggerService() => _instance;

  LoggerService._internal();

  /// Initializes the logging system with the specified level.
  /// Should be called once at app startup.
  static Future<void> init({
    Level logLevel = Level.INFO,
    bool enableFileLogging = true,
  }) async {
    // Initialize the root logger
    _rootLogger = Logger.root;
    _rootLogger!.level = logLevel;

    // Set up hierarchical logging
    hierarchicalLoggingEnabled = true;

    // Format log entries
    Logger.root.onRecord.listen((record) async {
      final logMessage = _formatLogRecord(record);

      // Print to console in debug mode
      if (kDebugMode) {
        _printToConsole(record, logMessage);
      }

      // Write to log file if enabled and not on web platform
      if (enableFileLogging && !kIsWeb) {
        await _writeToLogFile(logMessage);
      }
    });

    // Set up file logging if enabled and not on web platform
    if (enableFileLogging && !kIsWeb) {
      try {
        await _setupFileLogging();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to set up file logging: $e');
        }
      }
    }

    // Log initialization complete
    info('Logger', 'Logging initialized at level ${logLevel.name}');
  }

  /// Creates a named logger that inherits from the root logger.
  static Logger getLogger(String name) {
    if (_rootLogger == null) {
      throw StateError(
          'Logger is not initialized. Call LoggerService.init() first.');
    }
    return Logger(name);
  }

  /// Logs a message at INFO level.
  static void info(String tag, String message) {
    getLogger(tag).info(message);
  }

  /// Logs a message at WARNING level.
  static void warning(String tag, String message) {
    getLogger(tag).warning(message);
  }

  /// Logs a message at SEVERE (ERROR) level.
  static void error(String tag, String message,
      [Object? error, StackTrace? stackTrace]) {
    getLogger(tag).severe(message, error, stackTrace);
  }

  /// Logs a message at FINE (DEBUG) level.
  static void debug(String tag, String message) {
    getLogger(tag).fine(message);
  }

  /// Sets up file logging.
  static Future<void> _setupFileLogging() async {
    if (kIsWeb) {
      // File logging is not available on web platform
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDirectory = Directory('${directory.path}/logs');

      if (!await logDirectory.exists()) {
        await logDirectory.create(recursive: true);
      }

      final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logDirectory.path}/app_log_$now.log');
      _logSink = _logFile!.openWrite(mode: FileMode.append);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set up file logging: $e');
      }
    }
  }

  /// Formats a log record for output.
  static String _formatLogRecord(LogRecord record) {
    final time = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(record.time);
    final level = record.level.name.padRight(7);
    final message = record.message;
    final loggerName = record.loggerName;

    String logMessage = '[$time] $level [$loggerName] $message';

    if (record.error != null) {
      logMessage += '\nERROR: ${record.error}';
    }

    if (record.stackTrace != null) {
      logMessage += '\nSTACKTRACE:\n${record.stackTrace}';
    }

    return logMessage;
  }

  /// Prints a log record to the console with appropriate formatting.
  static void _printToConsole(LogRecord record, String formattedMessage) {
    var color = '';
    var resetColor = '';

    // Only apply colors if not on web platform
    if (!kIsWeb) {
      switch (record.level) {
        case Level.SEVERE:
          color = '\x1B[31m'; // Red
          break;
        case Level.WARNING:
          color = '\x1B[33m'; // Yellow
          break;
        case Level.INFO:
          color = '\x1B[36m'; // Cyan
          break;
        case Level.FINE:
          color = '\x1B[32m'; // Green
          break;
        default:
          color = '\x1B[37m'; // White
      }
      resetColor = '\x1B[0m'; // Reset
    }

    print('$color$formattedMessage$resetColor');
  }

  /// Writes a log message to the log file.
  static Future<void> _writeToLogFile(String logMessage) async {
    if (kIsWeb) {
      // File logging is not available on web platform
      return;
    }

    if (_logSink != null) {
      _logSink!.writeln(logMessage);
      await _logSink!.flush();
    }
  }

  /// Closes the logging resources.
  static Future<void> dispose() async {
    await _logSink?.flush();
    await _logSink?.close();
  }
}
