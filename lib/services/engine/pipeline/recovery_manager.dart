import '../../core/logging/logger_service.dart';

class RecoveryManager {
  static const int maxRetries = 3;

  Future<T?> runWithRetry<T>(Future<T> Function() action, String context) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        attempts++;
        LoggerService.log(LoggerService.mediaEngine, "Executing $context (Attempt $attempts)");
        return await action();
      } catch (e) {
        LoggerService.warning(LoggerService.mediaEngine, "$context failed (Attempt $attempts): $e");
        if (attempts >= maxRetries) {
          LoggerService.error(LoggerService.mediaEngine, "$context failed after $maxRetries attempts. Aborting.");
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempts)); // Exponential backoff
      }
    }
    return null;
  }

  void rollback(String path) {
    LoggerService.warning(LoggerService.mediaEngine, "Pipeline rollback initiated for: $path");
    // Cleanup temporary or corrupted files
  }
}
