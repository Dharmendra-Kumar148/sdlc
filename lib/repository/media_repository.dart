import '../model/media/media_model.dart';
import '../core/logging/logger_service.dart';

class MediaRepository {
  static final MediaRepository _instance = MediaRepository._internal();
  factory MediaRepository() => _instance;
  MediaRepository._internal();

  Future<void> savePostMetadata(MediaModel media, String? caption) async {
    LoggerService.log(LoggerService.uploadEngine, "Saving metadata for post: ${media.file.path}");
    // TODO: Firestore integration
    await Future.delayed(const Duration(milliseconds: 500));
    LoggerService.success(LoggerService.uploadEngine, "Metadata saved successfully.");
  }

  Future<String?> uploadMediaFile(MediaModel media) async {
    LoggerService.log(LoggerService.uploadEngine, "Uploading media file to cloud storage...");
    // TODO: Firebase Storage integration
    await Future.delayed(const Duration(seconds: 1));
    LoggerService.success(LoggerService.uploadEngine, "File uploaded to: https://storage.googleapis.com/gaongram/${media.file.path.split('/').last}");
    return "https://cloud.gaon.com/media/sample_id";
  }
}
