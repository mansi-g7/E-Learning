import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../admin/utils/youtube_utils.dart';

class YoutubeVideoPage extends StatefulWidget {
  final String title;
  final String youtubeUrl;

  const YoutubeVideoPage({
    required this.title,
    required this.youtubeUrl,
    super.key,
  });

  @override
  State<YoutubeVideoPage> createState() => _YoutubeVideoPageState();
}

class _YoutubeVideoPageState extends State<YoutubeVideoPage> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = extractYoutubeVideoId(widget.youtubeUrl);
    if (videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth > 980
              ? 980.0
              : constraints.maxWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: contentWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: controller == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 56,
                                  color: Color(0xFF3B53D6),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Invalid YouTube URL',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.youtubeUrl,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF667085),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: YoutubePlayer(
                                  controller: controller,
                                  aspectRatio: 16 / 9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.youtubeUrl,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
