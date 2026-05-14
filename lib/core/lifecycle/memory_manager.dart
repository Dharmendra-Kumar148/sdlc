import '../logging/logger_service.dart';

class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final List<dynamic> _disposables = [];

  void register(dynamic controller) {
    LoggerService.log(LoggerService.memoryManager, "Registered for disposal: ${controller.runtimeType}");
    _disposables.add(controller);
  }

  void disposeAll() {
    LoggerService.log(LoggerService.memoryManager, "Starting aggressive disposal of ${_disposables.length} controllers.");
    for (var item in _disposables) {
      try {
        if (item is List) {
          for (var subItem in item) {
            _safeDispose(subItem);
          }
        } else {
          _safeDispose(item);
        }
      } catch (e) {
        LoggerService.warning(LoggerService.memoryManager, "Failed to dispose ${item.runtimeType}: $e");
      }
    }
    _disposables.clear();
    LoggerService.success(LoggerService.memoryManager, "Aggressive disposal complete.");
  }

  void _safeDispose(dynamic item) {
    if (item == null) return;
    
    // Explicit disposal for common Flutter controllers
    try {
      if (item is Sink) {
        item.close();
      } else if (item.runtimeType.toString().contains('Controller')) {
        item.dispose();
      } else if (item.runtimeType.toString().contains('Isolate')) {
        item.kill();
      }
    } catch (_) {
      // Some items might not have a dispose() method or are already closed
    }
  }
}
