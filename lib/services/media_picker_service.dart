import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../model/media/media_model.dart';
import '../core/logging/logger_service.dart';

class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<MediaModel?> pickImage(ImageSource source) async {
    try {
      LoggerService.log(LoggerService.mediaPicker, "Opening gallery/camera for image...");
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null) {
        final file = File(image.path);
        final size = await file.length();
        LoggerService.success(LoggerService.mediaPicker, "Image Selected: ${file.path} ($size bytes)");
        
        return MediaModel(
          file: file,
          type: MediaType.image,
          size: size,
        );
      }
      LoggerService.info(LoggerService.mediaPicker, "Image picking cancelled.");
      return null;
    } catch (e, stack) {
      LoggerService.error(LoggerService.mediaPicker, "Failed to pick image", e, stack);
      return null;
    }
  }

  Future<MediaModel?> pickVideo(ImageSource source) async {
    try {
      LoggerService.log(LoggerService.mediaPicker, "Opening gallery/camera for video...");
      final XFile? video = await _picker.pickVideo(source: source);

      if (video != null) {
        final file = File(video.path);
        final size = await file.length();
        LoggerService.success(LoggerService.mediaPicker, "Video Selected: ${file.path} ($size bytes)");

        return MediaModel(
          file: file,
          type: MediaType.video,
          size: size,
        );
      }
      LoggerService.info(LoggerService.mediaPicker, "Video picking cancelled.");
      return null;
    } catch (e, stack) {
      LoggerService.error(LoggerService.mediaPicker, "Failed to pick video", e, stack);
      return null;
    }
  }
}
