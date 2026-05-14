import 'media/media_model.dart';

class PostModel {
  final String id;
  final MediaModel media;
  final String? caption;
  final DateTime postedAt;
  final String authorName;
  final int likesCount;

  PostModel({
    required this.id,
    required this.media,
    this.caption,
    required this.postedAt,
    this.authorName = "Creator",
    this.likesCount = 0,
  });
}
