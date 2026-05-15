import 'dart:io';

enum MediaType { image, video }

class MediaModel {
  final File file;
  final MediaType type;
  final int size;
  final int? width;
  final int? height;
  final File? thumbnail;
  final Duration? duration;

  MediaModel({
    required this.file,
    required this.type,
    required this.size,
    this.width,
    this.height,
    this.thumbnail,
    this.duration,
  });

  String get sizeFormatted => "${(size / 1024 / 1024).toStringAsFixed(2)} MB";
}
