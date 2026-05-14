import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/media_picker_service.dart';
import '../model/media/media_model.dart';
import '../core/logging/logger_service.dart';

class MediaViewModel extends ChangeNotifier {
  final MediaPickerService _pickerService = MediaPickerService();
  
  MediaModel? _selectedMedia;
  MediaModel? get selectedMedia => _selectedMedia;

  bool _isPicking = false;
  bool get isPicking => _isPicking;

  Future<void> pick(MediaType type, ImageSource source) async {
    LoggerService.log(LoggerService.ui, "User initiating pick: $type from $source");
    _isPicking = true;
    notifyListeners();

    try {
      final media = type == MediaType.image 
          ? await _pickerService.pickImage(source)
          : await _pickerService.pickVideo(source);

      if (media != null) {
        debugPrint('[PIPELINE] Step 1: assigning media');
        _selectedMedia = MediaModel(
          file: media.file,
          type: media.type,
          size: media.size,
        );
        debugPrint('[PIPELINE] Step 2: media assigned');
        
        LoggerService.success(LoggerService.ui, "Media selected and ready.");
        
        debugPrint('[PIPELINE] Step 3: notifying listeners');
        notifyListeners();
        debugPrint('[PIPELINE] Step 4: listeners notified');
      }
    } catch (e, st) {
      debugPrint('[PIPELINE_ERROR] $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isPicking = false;
      notifyListeners();
    }
  }

  void clear() {
    _selectedMedia = null;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('[VIEWMODEL_MEDIA] dispose called');
    super.dispose();
  }
}
