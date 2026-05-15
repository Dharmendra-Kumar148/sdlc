import 'package:firebase_storage/firebase_storage.dart';
import '../model/media/media_model.dart';
import '../core/logging/logger_service.dart';

class MediaRepository {
  static final MediaRepository _instance = MediaRepository._internal();
  factory MediaRepository() => _instance;
  MediaRepository._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> savePostMetadata(MediaModel media, String? caption) async {
    LoggerService.log(LoggerService.uploadEngine, "Saving metadata for post: ${media.file.path}");
    // TODO: Firestore integration in the next step
    await Future.delayed(const Duration(milliseconds: 500));
    LoggerService.success(LoggerService.uploadEngine, "Metadata saved successfully.");
  }

  Future<String?> uploadMediaFile(MediaModel media) async {
    LoggerService.log(LoggerService.uploadEngine, "MOCK: Bypassing Firebase Storage. Using local path.");
    
    // Simulate network latency
    await Future.delayed(const Duration(seconds: 1));
    
    LoggerService.success(LoggerService.uploadEngine, "MOCK: Upload complete.");
    
    // Return the local file path as a reference
    return media.file.path;
  }
}
