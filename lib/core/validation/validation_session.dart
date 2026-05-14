class ValidationSession {
  final String id;
  final String mediaType;
  final DateTime startTime;
  DateTime? endTime;
  
  int originalSize = 0;
  int filteredSize = 0;
  int compressedSize = 0;
  
  Duration? filteringDuration;
  Duration? compressionDuration;
  Duration? totalDuration;

  bool cleanupSuccess = false;
  bool visualAuditPass = false;

  ValidationSession({
    required this.id,
    required this.mediaType,
  }) : startTime = DateTime.now();

  double get compressionRatio => originalSize > 0 ? (1 - (compressedSize / originalSize)) * 100 : 0;

  @override
  String toString() {
    return '''
[VALIDATION_SESSION: $id]
Type: $mediaType
Duration: ${totalDuration?.inMilliseconds}ms
Original Size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB
Compressed Size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB
Reduction: ${compressionRatio.toStringAsFixed(1)}%
Cleanup: ${cleanupSuccess ? "PASS" : "FAIL"}
''';
  }
}
