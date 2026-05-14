enum PerformanceTier { low, mid, high }

class PerformanceProfile {
  final PerformanceTier tier;
  final int maxIsolates;
  final int maxCacheSize;
  final bool throttlePreviews;
  final int compressionQualityAdjustment;

  PerformanceProfile({
    required this.tier,
    this.maxIsolates = 1,
    this.maxCacheSize = 250 * 1024 * 1024, // 250MB for low-end
    this.throttlePreviews = true,
    this.compressionQualityAdjustment = 0,
  });

  factory PerformanceProfile.lowEnd() => PerformanceProfile(
    tier: PerformanceTier.low,
    maxIsolates: 1,
    maxCacheSize: 150 * 1024 * 1024,
    throttlePreviews: true,
    compressionQualityAdjustment: -5, // Slightly lower quality to save memory/time
  );

  factory PerformanceProfile.mid() => PerformanceProfile(
    tier: PerformanceTier.mid,
    maxIsolates: 1,
    maxCacheSize: 500 * 1024 * 1024,
    throttlePreviews: true,
    compressionQualityAdjustment: 0,
  );

  factory PerformanceProfile.flagship() => PerformanceProfile(
    tier: PerformanceTier.high,
    maxIsolates: 2,
    maxCacheSize: 1000 * 1024 * 1024,
    throttlePreviews: false,
    compressionQualityAdjustment: 5, // Higher quality on flagships
  );
}
