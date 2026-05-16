import 'package:flutter/material.dart';

import '../models/library_data.dart';
import 'app_theme.dart';
import 'youtube_video_page.dart';

class TopicDetailPage extends StatelessWidget {
  final BookData book;
  final TopicData topic;

  const TopicDetailPage({required this.book, required this.topic, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Topic Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(color: kHintGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topic.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (topic.knowledgeMapImage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 160),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD6E0FF)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          topic.knowledgeMapImage,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Knowledge map image could not be loaded.',
                                style: TextStyle(color: kHintGrey),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    topic.notes,
                    style: const TextStyle(
                      color: kHintGrey,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => YoutubeVideoPage(
                    title: topic.title,
                    youtubeUrl: topic.youtubeUrl,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Watch Video'),
          ),
        ],
      ),
    );
  }
}
