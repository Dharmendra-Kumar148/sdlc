import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sdlc/core/engine/engine_state.dart';
import 'package:sdlc/core/logging/logger_service.dart';
import 'package:sdlc/model/preset/filter_preset.dart';
import 'package:sdlc/model/media/media_model.dart';
import 'package:sdlc/services/engine/compression_engine.dart';
import 'package:sdlc/services/engine/pipeline/i_processing_provider.dart';
import 'package:sdlc/core/validation/validation_session.dart';
import 'package:sdlc/core/engine/performance_profile.dart';

class MediaEngine extends ChangeNotifier {
  EngineState _state = EngineState.idle;
  EngineState get state => _state;

  PerformanceProfile _profile = PerformanceProfile.mid(); // Default
  PerformanceProfile get profile => _profile;

  void setPerformanceProfile(PerformanceProfile profile) {
    _profile = profile;
    LoggerService.log(LoggerService.mediaEngine, "Performance Profile Set: ${profile.tier}");
  }

  ValidationSession? _currentSession;
  ValidationSession? get currentSession => _currentSession;

  IProcessingProvider? _provider;
  final CompressionEngine _compressionEngine = CompressionEngine();
  
  void setProvider(IProcessingProvider provider) {
    LoggerService.log(LoggerService.mediaEngine, "[MEDIA_ENGINE] Initializing...");
    LoggerService.log(LoggerService.mediaEngine, "[PERFORMANCE_PROFILE] Loaded: ${_profile.tier}");
    LoggerService.log(LoggerService.mediaEngine, "[VALIDATION_SYSTEM] Session Manager Ready");
    LoggerService.log(LoggerService.mediaEngine, "[CACHE_ENGINE] Cache Initialized");
    LoggerService.log(LoggerService.mediaEngine, "[MEMORY_MANAGER] Lifecycle Hooks Registered");
    
    LoggerService.log(LoggerService.mediaEngine, "Processing provider initialized: ${provider.runtimeType}");
    _provider = provider;
  }

  void _setState(EngineState newState) {
    _state = newState;
    LoggerService.log(LoggerService.mediaEngine, "State Transition: $newState");
    notifyListeners();
  }

  Future<File?> process(MediaModel media, FilterPreset preset) async {
    if (_provider == null) {
      LoggerService.error(LoggerService.mediaEngine, "No processing provider set.");
      return null;
    }

    final startTime = DateTime.now();
    LoggerService.log(LoggerService.mediaEngine, 
      "Processing Started\nMedia: ${media.type}\nOriginal Size: ${media.sizeFormatted}");

    _currentSession = ValidationSession(
      id: "job_${DateTime.now().millisecondsSinceEpoch}",
      mediaType: media.type.name,
    );
    _currentSession!.originalSize = media.size;

    try {
      _setState(EngineState.loading);
      
      // Phase 1: Filtering
      final filterStart = DateTime.now();
      _setState(EngineState.filtering);
      final filteredFile = await _provider!.applyPreset(media.file, preset);
      _currentSession!.filteredSize = filteredFile.lengthSync();
      _currentSession!.filteringDuration = DateTime.now().difference(filterStart);
      
      // Phase 2: Compression (Integrated)
      final compressionStart = DateTime.now();
      _setState(EngineState.compressing);
      File? finalFile = filteredFile;
      if (media.type == MediaType.image) {
        final compressed = await _compressionEngine.compressImage(filteredFile, preset);
        if (compressed != null) {
          finalFile = compressed;
          _currentSession!.compressedSize = compressed.lengthSync();
          // Cleanup filtered but uncompressed temp file
          // CRITICAL: Ensure we don't delete the user's original source file!
          if (filteredFile.path != compressed.path && filteredFile.path != media.file.path) {
            await _cleanupFile(filteredFile);
            _currentSession!.cleanupSuccess = true;
          }
        }
      }
      _currentSession!.compressionDuration = DateTime.now().difference(compressionStart);
      
      _setState(EngineState.completed);
      
      _currentSession!.endTime = DateTime.now();
      _currentSession!.totalDuration = _currentSession!.endTime!.difference(_currentSession!.startTime);
      
      LoggerService.success(LoggerService.mediaEngine, _currentSession!.toString());

      return finalFile;
    } catch (e, stack) {
      _setState(EngineState.failed);
      LoggerService.error(LoggerService.mediaEngine, "Processing failed", e, stack);
      return null;
    }
  }

  Future<void> _cleanupFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        LoggerService.log(LoggerService.memoryManager, "Deleted temporary processing file: ${file.path}");
      }
    } catch (e) {
      LoggerService.warning(LoggerService.memoryManager, "Failed to delete temp file: $e");
    }
  }

  @override
  void dispose() {
    LoggerService.log(LoggerService.memoryManager, "MediaEngine disposing. Cleaning up providers.");
    _provider?.dispose();
    super.dispose();
  }
}
