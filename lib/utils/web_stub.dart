// This file provides stub implementations for dart:io classes when running on the web
// It allows us to use a single codebase for both web and mobile platforms
import 'dart:typed_data';

class File {
  final String path;

  File(this.path);

  // Stub implementation that will never be called on web
  // (the actual implementation uses conditional imports)
  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('Cannot use File.readAsBytes() on the web.');
  }
}

// Add other stub classes as needed
