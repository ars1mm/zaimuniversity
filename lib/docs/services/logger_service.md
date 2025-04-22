# LoggerService Documentation

## Overview
**File:** `lib/services/logger_service.dart`

The LoggerService is a singleton class that provides centralized logging functionality across the application using Flutter's logging framework. It ensures consistent logging behavior and formatting throughout the application.

## Dependencies
- `logging`: For logging functionality

## Core Functionality

### Initialization

#### LoggerService._internal()
- Private constructor that initializes the root logger
- Sets up logging level and listening for log records
- Configures console output for logs, errors, and stack traces

#### init
```dart
static Future<void> init({Level logLevel = Level.ALL, bool enableFileLogging = false})
```
- Static initialization method for the logging system
- Sets global log level
- Configures optional file logging feature

### Logger Management

#### getLoggerForName
```dart
static Logger getLoggerForName(String name)
```
- Static method to obtain a logger instance by name
- Delegates to the singleton instance

#### getLogger
```dart
Logger getLogger(String name)
```
- Creates or retrieves a named logger instance
- Maintains a cache of loggers to avoid duplicates

### Logging Methods

#### info
```dart
void info(String message, {String? tag})
```
- Logs an informational message
- Optional tag parameter to specify source component

#### warning
```dart
void warning(String message, {String? tag})
```
- Logs a warning message
- Optional tag parameter to specify source component

#### error
```dart
void error(String message, {String? tag, Object? error, StackTrace? stackTrace})
```
- Logs an error message with additional context
- Supports capturing the original error object and stack trace
- Optional tag parameter to specify source component

#### debug
```dart
void debug(String message, {String? tag})
```
- Logs a debug message (fine level)
- Optional tag parameter to specify source component
