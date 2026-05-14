import 'package:flutter/material.dart';
import '../model/post_model.dart';
import '../model/media/media_model.dart';
import '../core/logging/logger_service.dart';

class PostViewModel extends ChangeNotifier {
  final List<PostModel> _posts = [];
  List<PostModel> get posts => List.unmodifiable(_posts);

  void addPost(MediaModel media, {String? caption}) {
    LoggerService.log(LoggerService.ui, "Adding new post to local feed.");
    final newPost = PostModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      media: media,
      caption: caption,
      postedAt: DateTime.now(),
    );
    _posts.insert(0, newPost);
    notifyListeners();
  }

  void removePost(String id) {
    _posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
