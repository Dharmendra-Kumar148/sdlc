import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sdlc/services/engine/media_engine.dart';
import 'package:sdlc/core/constants/app_constants.dart';
import 'package:sdlc/core/engine/engine_state.dart';
import 'package:sdlc/core/cache/media_cache_service.dart';

class EngineDebugger extends StatelessWidget {
  const EngineDebugger({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaEngine>(
      builder: (context, engine, child) {
        final session = engine.currentSession;
        return Container(
          padding: const EdgeInsets.all(12),
          width: 220,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.primaryBlue.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ENGINE DEBUG", style: TextStyle(color: AppConstants.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: engine.state == EngineState.idle ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DebugRow("STATE", engine.state.toString().split('.').last.toUpperCase(), isHighlight: true),
              _DebugRow("SESSION", session?.id.substring(0, 8) ?? "NONE"),
              const Divider(color: Colors.white10, height: 16),
              if (session != null) ...[
                _DebugRow("DUR", "${session.totalDuration?.inMilliseconds ?? 0}ms"),
                _DebugRow("RATIO", "${session.compressionRatio.toStringAsFixed(1)}%"),
                _DebugRow("CLEANUP", session.cleanupSuccess ? "PASS" : "WAIT"),
              ],
              _DebugRow("CACHE", "...", isFuture: true, future: _getCacheSize()),
            ],
          ),
        );
      },
    );
  }

  Widget _DebugRow(String label, String value, {bool isHighlight = false, bool isFuture = false, Future<String>? future}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          isFuture 
            ? FutureBuilder<String>(
                future: future,
                builder: (context, snapshot) => Text(snapshot.data ?? "...", style: const TextStyle(color: Colors.white, fontSize: 10)),
              )
            : Text(value, style: TextStyle(color: isHighlight ? AppConstants.primaryBlue : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<String> _getCacheSize() async {
    // This will be linked to MediaCacheService in next iteration
    return "12.4 MB"; 
  }
}
