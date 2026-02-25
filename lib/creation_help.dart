import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CreationHelpScreen extends StatelessWidget {
  const CreationHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creation Help')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How to Create Widgets and Wallpapers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                '1. For Widgets:\n'
                '- Choose a layout and customize it with your favorite Kpop groups.\n'
                '- Add images, text, and colors to make it your own.\n'
                '- Save and add it to your home screen.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const TutorialVideoPlayer(videoAsset: 'assets/videos/widget_tutorial.mp4'),
              const Text(
                '\n2. For Wallpapers:\n'
                '- Select an image from your gallery or create one using the built-in tools.\n'
                '- Customize it with filters, stickers, and text.\n'
                '- Save and set it as your wallpaper.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                'Need more help? Contact our support team or check out our FAQ section.',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TutorialVideoPlayer extends StatefulWidget {
  final String videoAsset;
  final double height;
  const TutorialVideoPlayer({
    super.key,
    required this.videoAsset,
    this.height = 600,
  });

  @override
  State<TutorialVideoPlayer> createState() => _TutorialVideoPlayerState();
}

class _TutorialVideoPlayerState extends State<TutorialVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoAsset)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      height: widget.height,
      width: double.infinity,
      color: Colors.transparent,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}