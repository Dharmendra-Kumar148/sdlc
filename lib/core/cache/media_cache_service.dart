import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../logging/logger_service.dart';

class MediaCacheService {
  static final MediaCacheService _instance = MediaCacheService._internal();
  factory MediaCacheService() => _instance;
  MediaCacheService._internal();

  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB

  Future<void> init() async {
    LoggerService.log(LoggerService.memoryManager, "Initializing MediaCacheService...");
    await cleanupOldCache();
  }

  Future<void> cleanupOldCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final List<FileSystemEntity> files = tempDir.listSync();
        int totalSize = 0;
        
        for (var file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }

        LoggerService.info(LoggerService.memoryManager, "Current Cache Size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB");

        if (totalSize > maxCacheSize) {
          LoggerService.warning(LoggerService.memoryManager, "Cache limit exceeded. Starting aggressive cleanup.");
          for (var file in files) {
            await file.delete();
          }
          LoggerService.success(LoggerService.memoryManager, "Cache cleanup complete.");
        }
      }
    } catch (e) {
      LoggerService.error(LoggerService.memoryManager, "Cache cleanup failed", e);
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        LoggerService.log(LoggerService.memoryManager, "Deleted cache file: $path");
      }
    } catch (_) {}
  }
}
