import 'package:flutter/material.dart';
import '../model/post_model.dart';
import '../model/media/media_model.dart';
import '../core/logging/logger_service.dart';
import '../repository/media_repository.dart';

class PostViewModel extends ChangeNotifier {
  final MediaRepository _mediaRepository = MediaRepository();
  final List<PostModel> _posts = [];
  List<PostModel> get posts => List.unmodifiable(_posts);

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  Future<bool> createPost(MediaModel media, {String? caption}) async {
    _isUploading = true;
    notifyListeners();

    try {
      // 1. Upload file to Firebase Storage
      final downloadUrl = await _mediaRepository.uploadMediaFile(media);
      
      if (downloadUrl != null) {
        // 2. Save metadata to Firestore (Next controlled step)
        await _mediaRepository.savePostMetadata(media, caption);

        // 3. Update local feed
        final newPost = PostModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          media: media,
          caption: caption,
          postedAt: DateTime.now(),
        );
        _posts.insert(0, newPost);
        
        LoggerService.success(LoggerService.ui, "Post created successfully in cloud.");
        return true;
      }
      return false;
    } catch (e, stack) {
      LoggerService.error(LoggerService.ui, "Failed to create post", e, stack);
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> removePost(String id) async {
    final post = _posts.firstWhere((p) => p.id == id);
    
    // session-only cleanup: Delete the physical file from disk
    try {
      if (await post.media.file.exists()) {
        await post.media.file.delete();
        LoggerService.log(LoggerService.ui, "Freed memory: Deleted temporary file ${post.media.file.path}");
      }
    } catch (e) {
      LoggerService.warning(LoggerService.ui, "Failed to delete file on post removal: $e");
    }

    _posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Clears all posts and frees disk space
  Future<void> clearAll() async {
    for (final post in _posts) {
      try {
        if (await post.media.file.exists()) {
          await post.media.file.delete();
        }
      } catch (_) {}
    }
    _posts.clear();
    notifyListeners();
  }
}
