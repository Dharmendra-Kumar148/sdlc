import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:gal/gal.dart';
import '../../viewmodel/compression_viewmodel.dart';
import '../../viewmodel/media_viewmodel.dart';
import '../../viewmodel/post_viewmodel.dart';
import '../../model/media/media_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logging/logger_service.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  VideoPlayerController? _videoController;
  String? _lastPath;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initVideo(File file) {
    if (_lastPath == file.path) return;
    _lastPath = file.path;
    
    _videoController?.dispose();
    _videoController = null;
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (!mounted) return;
          _videoController!.setLooping(true);
          _videoController!.play();
          setState(() {});
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    final finalMedia = context.watch<CompressionViewModel>().finalMedia;
    final originalMedia = context.watch<MediaViewModel>().selectedMedia;

    if (finalMedia == null || originalMedia == null) {
      return const Scaffold(body: Center(child: Text("Error: No processed media")));
    }

    if (finalMedia.type == MediaType.video) {
      _initVideo(finalMedia.file);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("READY TO SHARE", style: TextStyle(letterSpacing: 2))),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: 'media_preview',
                child: finalMedia.type == MediaType.image
                    ? Image.file(finalMedia.file, fit: BoxFit.contain)
                    : _videoController?.value.isInitialized ?? false
                        ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))
                        : const CircularProgressIndicator(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: const BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusLarge)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow("Original", "${(originalMedia.size / 1024 / 1024).toStringAsFixed(2)} MB"),
                const SizedBox(height: 8),
                _buildStatRow("Optimized", "${(finalMedia.size / 1024 / 1024).toStringAsFixed(2)} MB", isHighlight: true),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _saveToGallery(finalMedia),
                        child: const Text("GALLERY"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<PostViewModel>(
                        builder: (context, postVM, _) => ElevatedButton(
                          onPressed: postVM.isUploading ? null : () => _sharePost(context, finalMedia),
                          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryBlue),
                          child: postVM.isUploading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("SHARE"),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isHighlight ? AppConstants.primaryBlue : Colors.white)),
      ],
    );
  }

  Future<void> _saveToGallery(MediaModel media) async {
    try {
      if (media.type == MediaType.image) {
        await Gal.putImage(media.file.path);
      } else {
        await Gal.putVideo(media.file.path);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved!")));
    } catch (e) {
      LoggerService.error(LoggerService.ui, "Failed to save", e);
    }
  }

  void _sharePost(BuildContext context, MediaModel media) async {
    final postVM = context.read<PostViewModel>();
    
    // Show a loading snackbar or indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading post..."), duration: Duration(seconds: 2)),
    );

    final success = await postVM.createPost(media);
    
    if (success && context.mounted) {
      // Free memory by clearing temporary selections
      context.read<MediaViewModel>().clear();
      context.read<CompressionViewModel>().clear();
      
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload failed. Check logs."), backgroundColor: Colors.redAccent),
      );
    }
  }
}
