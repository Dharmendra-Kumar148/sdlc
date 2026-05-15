import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../viewmodel/media_viewmodel.dart';
import '../../viewmodel/filter_viewmodel.dart';
import '../../viewmodel/compression_viewmodel.dart';
import '../../model/media/media_model.dart';
import '../../model/preset/filter_preset.dart';
import '../../utils/filter_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/logger_service.dart';
import '../../viewmodel/makeup_viewmodel.dart';
import '../../services/engine/effects/glitch_gif_service.dart';
import '../widgets/face_overlay_painter.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  VideoPlayerController? _videoController;
  VideoPreviewController? _gpuController;
  FilterCategory _currentCategory = FilterCategory.basic;
  bool _isComparing = false;
  Timer? _glitchTimer;

  @override
  void initState() {
    super.initState();
    // Optimize memory for low-end devices
    PaintingBinding.instance.imageCache.maximumSize = 20;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
    
    final media = context.read<MediaViewModel>().selectedMedia;
    if (media != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FilterViewModel>().init(media);
        if (media.type == MediaType.image) {
          context.read<MakeupViewModel>().detectFaces(media.file);
        } else if (media.type == MediaType.video && media.thumbnail != null) {
          context.read<MakeupViewModel>().detectFaces(media.thumbnail!);
        }
        if (media.type == MediaType.video) {
          _initVideo(media.file);
        }
      });
    }
  }

  void _initVideo(File file) async {
    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        _videoController!.setLooping(true);
        _videoController!.play();
        if (mounted) setState(() {});
      });
    
    final controller = await GPUVideoPreviewController.initialize();
    await controller.setVideoSource(FileInputSource(file));
    if (mounted) {
      setState(() {
        _gpuController = controller;
      });
    }
  }

  void _ensureGlitchAnimation(FilterViewModel filterVM) {
    final hasGlitch = filterVM.currentPreset.layers.any((l) => l.type == FilterType.glitch);
    if (hasGlitch && (_glitchTimer == null || !_glitchTimer!.isActive)) {
      _glitchTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (mounted && filterVM.currentPreset.layers.any((l) => l.type == FilterType.glitch) && !_isComparing) {
          setState(() {});
        } else {
          timer.cancel();
          _glitchTimer = null;
        }
      });
    }
  }

  @override
  void dispose() {
    debugPrint('[EDITOR] dispose called - cleaning up resources');
    _glitchTimer?.cancel();
    _videoController?.dispose();
    _gpuController?.dispose();
    _videoController = null;
    _gpuController = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterVM = context.watch<FilterViewModel>();
    final media = context.watch<MediaViewModel>().selectedMedia;

    if (media == null) return const Scaffold(body: Center(child: Text("Error: No media")));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: () async {
              LoggerService.log(LoggerService.ui, "Next button clicked - triggering export...");
              _finishEditing(context, media);
            },
            child: const Text("NEXT", style: TextStyle(color: AppConstants.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Center(
                      child: Hero(
                        tag: 'media_preview',
                        child: GestureDetector(
                          onLongPressStart: (_) => setState(() => _isComparing = true),
                          onLongPressEnd: (_) => setState(() => _isComparing = false),
                          child: Consumer<MakeupViewModel>(
                            builder: (context, makeupVM, child) {
                              return Stack(
                                children: [
                                  ColorFiltered(
                                    colorFilter: (filterVM.currentPreset.layers.isNotEmpty && !_isComparing)
                                        ? FilterUtils.getFilter(filterVM.currentPreset.layers.first)
                                        : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                                    child: media.type == MediaType.image
                                        ? Builder(builder: (context) {
                                            final isGlitch = filterVM.currentPreset.layers.any((l) => l.type == FilterType.glitch);
                                            if (isGlitch && !_isComparing) {
                                              _ensureGlitchAnimation(filterVM);
                                            }
                                            return Image.file(
                                              media.file, 
                                              fit: BoxFit.contain,
                                              cacheWidth: 1080,
                                              filterQuality: FilterQuality.medium,
                                            );
                                          })
                                        : _videoController?.value.isInitialized ?? false
                                            ? _gpuController != null
                                                ? Builder(
                                                    builder: (context) {
                                                      final gpuController = _gpuController!;
                                                      final config = filterVM.currentGPUConfig;
                                                      
                                                      if (config is GPUBulgeDistortionConfiguration && !_isComparing) {
                                                        final firstLayer = filterVM.currentPreset.layers.first;
                                                        final type = firstLayer.type;

                                                        if (type == FilterType.glitch) {
                                                          final rand = Random();
                                                          config.center = const Point<double>(0.5, 0.5);
                                                          config.radius = 0.4 + rand.nextDouble() * 0.3;
                                                          config.scale = (rand.nextBool() ? 1.0 : -1.0) * (firstLayer.intensity * 0.5);
                                                          _ensureGlitchAnimation(filterVM);
                                                        } else if (makeupVM.detectedFaces.isNotEmpty) {
                                                          final face = makeupVM.detectedFaces.first;
                                                          Point<int>? targetPos;
                                                          
                                                          if (type == FilterType.eyeEnlargement) {
                                                            final left = face.landmarks[FaceLandmarkType.leftEye]?.position;
                                                            final right = face.landmarks[FaceLandmarkType.rightEye]?.position;
                                                            if (left != null && right != null) {
                                                              targetPos = Point<int>((left.x + right.x) ~/ 2, (left.y + right.y) ~/ 2);
                                                            } else {
                                                              targetPos = left ?? right;
                                                            }
                                                          } else if (type == FilterType.faceSlimming) {
                                                            targetPos = face.landmarks[FaceLandmarkType.bottomMouth]?.position;
                                                          }

                                                          if (targetPos != null) {
                                                            config.center = Point<double>(
                                                              targetPos.x.toDouble() / (media.width ?? 1080),
                                                              targetPos.y.toDouble() / (media.height ?? 1920),
                                                            );
                                                          }
                                                        }
                                                      }
                                                      
                                                      gpuController.connect(config ?? FilterUtils.identityConfig);

                                                      return RepaintBoundary(
                                                        child: AspectRatio(
                                                          aspectRatio: _videoController!.value.aspectRatio, 
                                                          child: VideoPreview(controller: gpuController),
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : const CircularProgressIndicator()
                                            : const CircularProgressIndicator(),
                                  ),
                                  if (filterVM.currentPreset.layers.any((l) => l.type == FilterType.glitch) && !_isComparing)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: GlitchOverlayPainter(
                                          intensity: filterVM.currentPreset.layers.first.intensity,
                                        ),
                                      ),
                                    ),
                                  if (makeupVM.detectedFaces.isNotEmpty)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: FaceOverlayPainter(
                                          faces: makeupVM.detectedFaces,
                                          absoluteImageSize: Size(
                                            (media.width ?? 1080).toDouble(), 
                                            (media.height ?? 1920).toDouble()
                                          ), 
                                          lipstickColor: makeupVM.lipstickColor,
                                          lipstickIntensity: makeupVM.lipstickIntensity,
                                          blushColor: Colors.pinkAccent,
                                          blushIntensity: _currentCategory == FilterCategory.makeup ? 0.3 : 0.0,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (_isComparing)
                      Positioned(
                        top: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("ORIGINAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        ),
                      ),
                  ],
                ),
              ),
              _buildControls(filterVM),
            ],
          ),
          // Persistent Progress Overlay
          Consumer<CompressionViewModel>(
            builder: (context, vm, child) {
              if (!vm.isProcessing) return const SizedBox.shrink();
              return Container(
                color: Colors.black87,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("PROCESSING MEDIA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: vm.progress, 
                            color: AppConstants.primaryBlue, 
                            backgroundColor: Colors.white10,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text("${(vm.progress * 100).toInt()}%", style: const TextStyle(color: AppConstants.primaryBlue, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () => vm.cancel(),
                          child: const Text("CANCEL", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<FilterType> _getFilteredTypes() {
    switch (_currentCategory) {
      case FilterCategory.basic:
        return [FilterType.brightness, FilterType.contrast, FilterType.grayscale, FilterType.sepia];
      case FilterCategory.cinematic:
        return [FilterType.vintage, FilterType.cinematicWarm, FilterType.cinematicCool];
      case FilterCategory.beauty:
        return [FilterType.skinSmoothing, FilterType.glow];
      case FilterCategory.reshape:
        return [FilterType.eyeEnlargement, FilterType.faceSlimming];
      case FilterCategory.makeup:
        return [FilterType.lipstick, FilterType.blush, FilterType.eyeliner];
      case FilterCategory.effects:
        return [FilterType.glitch];
      default:
        return [];
    }
  }

  Widget _buildMakeupControls(BuildContext context) {
    final makeupVM = context.watch<MakeupViewModel>();
    final colors = [Colors.red, Colors.pink, Colors.deepOrange, Colors.purple, Colors.brown];
    
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: colors.map((color) {
              final isSelected = makeupVM.lipstickColor == color;
              return GestureDetector(
                onTap: () => makeupVM.updateLipstick(color, 0.5),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Slider(
          value: makeupVM.lipstickIntensity,
          onChanged: (v) => makeupVM.updateLipstick(makeupVM.lipstickColor, v),
          activeColor: AppConstants.primaryBlue,
        ),
      ],
    );
  }

  Widget _buildControls(FilterViewModel filterVM) {
    return Container(
      padding: const EdgeInsets.only(bottom: 40, top: 20),
      decoration: const BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusLarge)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentCategory == FilterCategory.makeup)
            _buildMakeupControls(context),
          if (filterVM.currentPreset.layers.isNotEmpty && _currentCategory != FilterCategory.makeup)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(filterVM.currentPreset.layers.first.type.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white54)),
                      Text("${(filterVM.currentPreset.layers.first.intensity * 100).toInt()}%", style: const TextStyle(fontSize: 10, color: AppConstants.primaryBlue)),
                    ],
                  ),
                ),
                Slider(
                  value: filterVM.currentPreset.layers.first.intensity,
                  onChanged: (v) => filterVM.applyFilter(filterVM.currentPreset.layers.first.type, v),
                  activeColor: AppConstants.primaryBlue,
                ),
              ],
            ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: FilterCategory.values.map((cat) {
                final isSelected = _currentCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentCategory = cat);
                    final types = _getFilteredTypes();
                    if (types.isNotEmpty) {
                      filterVM.applyFilter(types.first, 0.5);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppConstants.primaryBlue : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(cat.toString().split('.').last.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _getFilteredTypes().length,
              itemBuilder: (context, index) {
                final type = _getFilteredTypes()[index];
                final isSelected = filterVM.currentPreset.layers.any((l) => l.type == type);
                return GestureDetector(
                  onTap: () => filterVM.applyFilter(type, 0.5),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? AppConstants.primaryBlue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppConstants.primaryBlue : Colors.white12),
                    ),
                    child: Center(
                      child: Text(
                        type.name.toUpperCase(), 
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)
                      )
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishEditing(BuildContext context, MediaModel media) async {
    final compressionVM = context.read<CompressionViewModel>();
    final filterVM = context.read<FilterViewModel>();

    // CRITICAL: Stop and release preview resources to free up MediaCodec buffers
    LoggerService.log(LoggerService.ui, "Releasing preview resources for export...");
    
    // 1. Pause video playback
    _videoController?.pause();
    
    // 2. Dispose GPU controller to release textures/buffers
    final oldGpuController = _gpuController;
    _gpuController = null;
    if (mounted) setState(() {}); // Remove Preview widget from tree
    
    await Future.delayed(const Duration(milliseconds: 100)); // Wait for UI update
    await oldGpuController?.dispose();

    // Start processing - the UI will now show the built-in Overlay automatically
    await compressionVM.compress(media, filterVM.currentPreset);
    
    if (context.mounted && compressionVM.finalMedia != null) {
      Navigator.pushNamed(context, '/preview');
    }
  }
}

class GlitchOverlayPainter extends CustomPainter {
  final double intensity;
  
  GlitchOverlayPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    
    final rand = Random();
    final blockCount = (15 * intensity).toInt().clamp(5, 30);
    
    for (int i = 0; i < blockCount; i++) {
      final paint = Paint()
        ..color = [
          Colors.cyan.withOpacity(0.4),
          Colors.pinkAccent.withOpacity(0.4),
          Colors.greenAccent.withOpacity(0.3),
          Colors.white.withOpacity(0.2),
        ][rand.nextInt(4)]
        ..style = PaintingStyle.fill;
        
      final rect = Rect.fromLTWH(
        rand.nextDouble() * size.width,
        rand.nextDouble() * size.height,
        rand.nextDouble() * size.width * 0.3,
        rand.nextDouble() * 15.0,
      );
      
      canvas.drawRect(rect, paint);
    }

    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.05 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 8.0) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), scanlinePaint);
    }
  }

  @override
  bool shouldRepaint(GlitchOverlayPainter oldDelegate) => true;
}
