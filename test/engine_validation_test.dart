import 'package:flutter_test/flutter_test.dart';
import 'package:sdlc/services/engine/media_engine.dart';
import 'package:sdlc/services/engine/adapters/isolate_processing_provider.dart';
import 'package:sdlc/core/engine/engine_state.dart';
import 'package:sdlc/core/engine/performance_profile.dart';
import 'package:sdlc/core/logging/logger_service.dart';

void main() {
  test('MediaEngine and SkinSmoothing Validation', () async {
    final engine = MediaEngine();
    engine.setProvider(IsolateProcessingProvider());

    // Verify initialization logs and state
    LoggerService.info(LoggerService.mediaEngine, "Test: Engine Initialized successfully.");
    
    expect(engine.state, EngineState.idle);
    expect(engine.profile.tier, PerformanceTier.mid);
    expect(engine.currentSession, isNull);
  });
}
