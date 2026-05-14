import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../viewmodel/media_viewmodel.dart';
import '../../model/media/media_model.dart';

class PickerScreen extends StatelessWidget {
  const PickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: const BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusLarge)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("CREATE NEW", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PickerItem(
                icon: Icons.image_outlined,
                label: "Image",
                onTap: () => _handlePick(context, MediaType.image, ImageSource.gallery),
              ),
              _PickerItem(
                icon: Icons.videocam_outlined,
                label: "Video",
                onTap: () => _handlePick(context, MediaType.video, ImageSource.gallery),
              ),
              _PickerItem(
                icon: Icons.camera_alt_outlined,
                label: "Camera",
                onTap: () => _handlePick(context, MediaType.image, ImageSource.camera),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handlePick(BuildContext context, MediaType type, ImageSource source) async {
    final mediaVM = context.read<MediaViewModel>();
    Navigator.pop(context); // Close sheet
    
    await mediaVM.pick(type, source);
    if (mediaVM.selectedMedia != null && context.mounted) {
      Navigator.pushNamed(context, '/editor');
    }
  }
}

class _PickerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
