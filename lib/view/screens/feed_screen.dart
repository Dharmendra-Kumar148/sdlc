import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../viewmodel/post_viewmodel.dart';
import '../../model/post_model.dart';
import '../../model/media/media_model.dart';
import '../../core/constants/app_constants.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postVM = context.watch<PostViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("GAONGRAM", style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Icon(Icons.send_rounded), onPressed: () {}),
        ],
      ),
      body: postVM.posts.isEmpty
          ? const Center(child: Text("No posts yet. Start creating!"))
          : ListView.builder(
              itemCount: postVM.posts.length,
              itemBuilder: (context, index) => PostCard(post: postVM.posts[index]),
            ),
    );
  }
}

class PostCard extends StatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.post.media.type == MediaType.video) {
      _videoController = VideoPlayerController.file(widget.post.media.file)
        ..initialize().then((_) {
          _videoController!.setLooping(true);
          _videoController!.play();
          _videoController!.setVolume(0);
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const CircleAvatar(radius: 16, backgroundColor: AppConstants.primaryBlue, child: Icon(Icons.person, size: 18)),
              const SizedBox(width: 10),
              Text(widget.post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 500),
          width: double.infinity,
          color: AppConstants.surfaceColor,
          child: widget.post.media.type == MediaType.image
              ? Image.file(widget.post.media.file, fit: BoxFit.cover)
              : _videoController?.value.isInitialized ?? false
                  ? AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!))
                  : const Center(child: CircularProgressIndicator()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.favorite_border_rounded), onPressed: () {}),
              IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded), onPressed: () {}),
              IconButton(icon: const Icon(Icons.send_rounded), onPressed: () {}),
            ],
          ),
        ),
        if (widget.post.caption != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: "${widget.post.authorName} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: widget.post.caption),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
