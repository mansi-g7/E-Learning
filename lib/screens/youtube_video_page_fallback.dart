import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _launching = false;
  String? _launchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openVideo();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _openVideo() async {
    if (_launching) {
      return;
    }

    setState(() {
      _launching = true;
      _launchError = null;
    });

    final normalizedUrl = normalizeYoutubeWatchUrl(widget.youtubeUrl);
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      setState(() {
        _launching = false;
        _launchError = 'Invalid YouTube link.';
      });
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        setState(() {
          _launching = false;
          _launchError = 'Could not open the video on this device.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _launching = false;
          _launchError = 'Could not open the video on this device.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 48,
                  color: Color(0xFF3B53D6),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _launching ? 'Opening YouTube...' : 'Open video on your phone',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _launchError ??
                    'This video will open in the YouTube app or browser, which works reliably on mobile.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _openVideo,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Video'),
              ),
              const SizedBox(height: 10),
              Text(
                normalizeYoutubeWatchUrl(widget.youtubeUrl),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
