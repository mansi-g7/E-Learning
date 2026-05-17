import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  WebViewController? _controller;
  bool _loading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final watchUrl = buildYoutubeMobileWatchUrl(widget.youtubeUrl);
    if (watchUrl == null) {
      _loading = false;
      _errorText = 'Invalid YouTube URL';
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _loading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
            _hideYoutubeChrome();
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _loading = false;
                _errorText = 'Could not open the video inside the app.';
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) {
              return NavigationDecision.navigate;
            }

            final host = uri.host.toLowerCase();
            if (host.contains('youtube.com') || host.contains('youtu.be')) {
              return NavigationDecision.navigate;
            }

            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(watchUrl));
  }

  Future<void> _hideYoutubeChrome() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    try {
      await controller.runJavaScript('''
        (function () {
          const styleId = 'copilot-youtube-player-only-style';
          let style = document.getElementById(styleId);
          if (!style) {
            style = document.createElement('style');
            style.id = styleId;
            document.head.appendChild(style);
          }

          style.textContent = `
            html, body {
              margin: 0 !important;
              padding: 0 !important;
              width: 100% !important;
              height: 100% !important;
              overflow: hidden !important;
              background: #000 !important;
            }

            body > *:not(#player):not(#player-container):not(#movie_player) {
              display: none !important;
            }

            #masthead-container,
            #header,
            #below,
            #secondary,
            #comments,
            #related,
            #meta,
            #chat,
            #playlist,
            #tabs,
            #chipbar,
            #menu,
            ytd-comments,
            ytd-watch-next-secondary-results-renderer,
            ytd-engagement-panel-section-list-renderer,
            ytm-single-column-watch-next-results-renderer,
            ytm-comments-entry-point-header-renderer,
            ytm-engagement-panel-section-list-renderer {
              display: none !important;
            }

            #player,
            #player-container,
            #movie_player {
              position: fixed !important;
              inset: 0 !important;
              width: 100vw !important;
              height: 100vh !important;
              z-index: 9999 !important;
              background: #000 !important;
            }

            video {
              object-fit: contain !important;
            }
          `;

          document.body.style.margin = '0';
          document.body.style.padding = '0';
          document.body.style.overflow = 'hidden';
        })();
      ''');
    } catch (_) {
      // If the page blocks injection, the video still remains playable.
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final webViewController = _controller;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Stack(
          children: [
            if (webViewController != null)
              Positioned.fill(
                child: WebViewWidget(controller: webViewController),
              )
            else
              Center(
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
                        style: const TextStyle(color: Color(0xFF667085)),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_errorText != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 44,
                        color: Color(0xFF3B53D6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
