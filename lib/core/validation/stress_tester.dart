import 'dart:io';
import '../../services/engine/media_engine.dart';
import '../../model/media/media_model.dart';
import '../../model/preset/filter_preset.dart';
import '../logging/logger_service.dart';

class StressTester {
  final MediaEngine engine;

  StressTester(this.engine);

  Future<void> runStressTest(File testFile, int cycles) async {
    LoggerService.log(LoggerService.mediaEngine, "=== STARTING STRESS TEST: $cycles CYCLES ===");
    
    final media = MediaModel(
      file: testFile,
      type: MediaType.image,
      size: await testFile.length(),
    );

    final preset = FilterPreset(
      id: 'stress_preset',
      name: 'Stress Test',
      layers: [
        EffectLayer(id: '1', type: FilterType.cinematicWarm, intensity: 0.8),
        EffectLayer(id: '2', type: FilterType.glow, intensity: 0.5),
      ],
    );

    for (int i = 1; i <= cycles; i++) {
      LoggerService.info(LoggerService.mediaEngine, "Cycle $i/$cycles starting...");
      final result = await engine.process(media, preset);
      
      if (result == null) {
        LoggerService.error(LoggerService.mediaEngine, "Cycle $i FAILED. Aborting stress test.");
        return;
      }
      
      LoggerService.success(LoggerService.mediaEngine, "Cycle $i COMPLETE.");
      
      // Artificial delay to simulate user behavior and allow for GC
      await Future.delayed(const Duration(seconds: 2));
    }

    LoggerService.success(LoggerService.mediaEngine, "=== STRESS TEST COMPLETE: ALL CYCLES SUCCESSFUL ===");
  }
}
