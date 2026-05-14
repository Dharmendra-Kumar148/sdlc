import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../viewmodel/media_viewmodel.dart';
import '../../viewmodel/filter_viewmodel.dart';
import '../../viewmodel/compression_viewmodel.dart';
import '../../model/media/media_model.dart';
import '../../model/preset/filter_preset.dart';
import '../../utils/filter_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/logger_service.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  VideoPlayerController? _videoController;
  FilterCategory _currentCategory = FilterCategory.basic;

  @override
  void initState() {
    super.initState();
    final media = context.read<MediaViewModel>().selectedMedia;
    if (media != null) {
      // Defer initialization to after the first frame to avoid building while notifying
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<FilterViewModel>().init(media);
        }
      });

      if (media.type == MediaType.video) {
        _videoController = VideoPlayerController.file(media.file)
          ..initialize().then((_) {
            _videoController!.setLooping(true);
            _videoController!.play();
            setState(() {});
          });
      }
    }
  }

  @override
  void dispose() {
    debugPrint('[EDITOR] dispose called - cleaning up resources');
    _videoController?.dispose();
    _videoController = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    debugPrint('[EDITOR] image cache cleared');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterVM = context.watch<FilterViewModel>();
    final media = filterVM.processedMedia;

    if (media == null) return const Scaffold(body: Center(child: Text("Error: No media")));

    debugPrint('[PREVIEW_WIDGET] build triggered - Media: ${media.file.path}');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: () => _finishEditing(context, media),
            child: const Text("NEXT", style: TextStyle(color: AppConstants.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: 'media_preview',
                child: ColorFiltered(
                  colorFilter: filterVM.currentPreset.layers.isNotEmpty 
                      ? FilterUtils.getFilter(filterVM.currentPreset.layers.first)
                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: media.type == MediaType.image
                      ? Image.file(
                          media.file, 
                          fit: BoxFit.contain,
                          cacheWidth: 1080,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('[PREVIEW_ERROR] $error');
                            return Center(child: Text("Preview Error: $error"));
                          },
                        )
                      : _videoController?.value.isInitialized ?? false
                          ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))
                          : const CircularProgressIndicator(),
                ),
              ),
            ),
          ),
          _buildControls(filterVM),
        ],
      ),
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
          if (filterVM.currentPreset.layers.isNotEmpty)
            Slider(
              value: filterVM.currentPreset.layers.first.intensity,
              onChanged: (v) => filterVM.applyFilter(filterVM.currentPreset.layers.first.type, v),
              activeColor: AppConstants.primaryBlue,
            ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: FilterCategory.values.map((cat) {
                final isSelected = _currentCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _currentCategory = cat),
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
              itemCount: FilterType.values.length,
              itemBuilder: (context, index) {
                final type = FilterType.values[index];
                final isSelected = filterVM.currentPreset.layers.any((l) => l.type == type);
                return GestureDetector(
                  onTap: () => filterVM.applyFilter(type, 0.5),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? AppConstants.primaryBlue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppConstants.primaryBlue : Colors.white12),
                    ),
                    child: Center(child: Text(type.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<CompressionViewModel>(
        builder: (context, vm, child) => AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          title: const Text("Processing Media", style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: vm.progress, color: AppConstants.primaryBlue, backgroundColor: Colors.white10),
              const SizedBox(height: 12),
              Text("${(vm.progress * 100).toInt()}%", style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                vm.cancel();
                Navigator.pop(context);
              },
              child: const Text("CANCEL", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );

    await compressionVM.compress(media, filterVM.currentPreset);
    
    if (context.mounted) {
      Navigator.pop(context); // Close dialog
      if (compressionVM.finalMedia != null) {
        Navigator.pushNamed(context, '/preview');
      }
    }
  }
}
