import 'package:flutter/foundation.dart';

class LoggerService {
  // Engine Categories
  static const String mediaEngine = 'MEDIA_ENGINE';
  static const String mediaPicker = 'MEDIA_PICKER';
  static const String filterPipeline = 'FILTER_PIPELINE';
  static const String filterEngine = 'FILTER_ENGINE';
  static const String compressionEngine = 'COMPRESSION_ENGINE';
  static const String uploadEngine = 'UPLOAD_ENGINE';
  static const String memoryManager = 'MEMORY_MANAGER';
  static const String auth = 'AUTH';
  static const String ui = 'UI';

  static void log(String category, String message) {
    if (kDebugMode) {
      debugPrint('[$category]\n$message\n');
    }
  }

  static void success(String category, String message) {
    if (kDebugMode) {
      debugPrint('[$category] ✅ SUCCESS\n$message\n');
    }
  }

  static void info(String category, String message) {
    if (kDebugMode) {
      debugPrint('[$category] ℹ️ INFO\n$message\n');
    }
  }

  static void warning(String category, String message) {
    if (kDebugMode) {
      debugPrint('[$category] ⚠️ WARNING\n$message\n');
    }
  }

  static void error(String category, String message, [dynamic error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[$category] ❌ ERROR\n$message');
      if (error != null) debugPrint('Detail: $error');
      if (stack != null) debugPrint('Stack: $stack');
      debugPrint('');
    }
  }

  // Specialized structured logs for the engine
  static void logProcessing(String category, {
    required String action,
    required String duration,
    String? originalSize,
    String? finalSize,
    String? quality,
  }) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln('[$category] $action');
      buffer.writeln('Duration: $duration');
      if (originalSize != null) buffer.writeln('Original: $originalSize');
      if (finalSize != null) buffer.writeln('Final: $finalSize');
      if (quality != null) buffer.writeln('Quality: $quality');
      debugPrint('$buffer');
    }
  }
}
