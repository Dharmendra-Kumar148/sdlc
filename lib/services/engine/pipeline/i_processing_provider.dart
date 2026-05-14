import 'dart:io';
import '../../../model/preset/filter_preset.dart';

abstract class IProcessingProvider {
  Future<File> applyPreset(File inputFile, FilterPreset preset);
  Future<void> dispose();
}
