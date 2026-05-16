import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../admin/models/admin_models.dart';
import '../models/library_data.dart';
import 'app_theme.dart';
import 'topic_detail_page.dart';

class BookDetailPage extends StatelessWidget {
  final BookData book;

  const BookDetailPage({required this.book, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Book Detail')),
      body: FutureBuilder<List<AdminTopic>>(
        future: _loadTopics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final firestoreTopics = snapshot.data ?? const <AdminTopic>[];
          final topics = firestoreTopics.isNotEmpty
              ? firestoreTopics
              : book.topics
                    .map(
                      (topic) => AdminTopic(
                        id: topic.title,
                        title: topic.title,
                        notes: topic.notes,
                        knowledgeMapImage: '',
                        videoUrl: topic.youtubeUrl,
                        createdAt: null,
                      ),
                    )
                    .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 84,
                        height: 118,
                        decoration: BoxDecoration(
                          color: book.coverColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(book.icon, color: Colors.white, size: 38),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book.author,
                              style: const TextStyle(
                                color: kHintGrey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Color(0xFFF6B000),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  book.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              book.summary,
                              style: const TextStyle(
                                color: kHintGrey,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _BookBasicsCard(book: book, topics: topics),
              const SizedBox(height: 16),
              const Text(
                'Knowledge Map',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (topics.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No topics added for this book yet.'),
                  ),
                )
              else
                SizedBox(
                  height: 420,
                  child: _KnowledgeMapView(book: book, topics: topics),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<List<AdminTopic>> _loadTopics() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .doc(book.id)
        .collection('topics')
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map(AdminTopic.fromSnapshot).toList();
  }
}

class _BookBasicsCard extends StatelessWidget {
  final BookData book;
  final List<AdminTopic> topics;

  const _BookBasicsCard({required this.book, required this.topics});

  @override
  Widget build(BuildContext context) {
    final topicCount = topics.length;
    final topTopic = topicCount > 0 ? topics.first.title : 'No topics yet';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Basics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _InfoRow(label: 'What is this book for?', value: book.summary),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Current focus / future topics',
              value: topicCount > 0
                  ? 'This book currently has $topicCount topic${topicCount == 1 ? '' : 's'} to follow, starting with $topTopic.'
                  : 'No knowledge map topics have been added yet.',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Other things you will learn',
              value: topicCount > 0
                  ? 'Open each topic from the map to watch a video and view the topic details.'
                  : 'Once the admin adds topics, the knowledge map will appear here.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: kHintGrey, fontSize: 13, height: 1.45),
        ),
      ],
    );
  }
}

class _KnowledgeMapView extends StatelessWidget {
  final BookData book;
  final List<AdminTopic> topics;

  const _KnowledgeMapView({required this.book, required this.topics});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 420,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final mapWidth = math.max(width, 760.0);
            final mapHeight = 420.0;

            final nodeCount = topics.length;
            final center = Offset(mapWidth / 2, mapHeight / 2);
            final radiusX = mapWidth * 0.30;
            final radiusY = mapHeight * 0.30;

            final nodeWidths = List<double>.generate(nodeCount, (i) {
              final estimated = (topics[i].title.length * 7.4) + 52;
              return estimated.clamp(132.0, 220.0).toDouble();
            });

            final positions = List<Offset>.generate(nodeCount, (i) {
              final t = topics[i];
              if (t.posX != null && t.posY != null) {
                return Offset(
                  (t.posX!.clamp(0.0, 1.0) * mapWidth),
                  (t.posY!.clamp(0.0, 1.0) * mapHeight),
                );
              }

              final angle = (i / nodeCount) * math.pi * 2;
              final wave = (i.isEven ? 1 : -1) * (8 + (i % 3) * 6);
              final x = center.dx + radiusX * math.cos(angle);
              final y = center.dy + radiusY * math.sin(angle) + wave;
              return Offset(x, y);
            });

            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFEFF4FF),
                          Colors.white,
                          const Color(0xFFF8F3FF),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -40,
                  top: -50,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B53D6).withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -40,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF17A36B).withValues(alpha: 0.08),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: mapWidth,
                      height: mapHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _KnowledgeLinkPainter(
                                center: center,
                                points: positions,
                              ),
                            ),
                          ),
                          Positioned(
                            left: center.dx - 84,
                            top: center.dy - 28,
                            child: Container(
                              width: 168,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3B53D6),
                                    Color(0xFF5C6DF2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x403B53D6),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Text(
                                book.title,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          for (var i = 0; i < topics.length; i++)
                            Positioned(
                              left: (positions[i].dx - (nodeWidths[i] / 2))
                                  .clamp(8.0, mapWidth - nodeWidths[i] - 8)
                                  .toDouble(),
                              top: (positions[i].dy - 28)
                                  .clamp(8.0, mapHeight - 64)
                                  .toDouble(),
                              child: _TopicNode(
                                topic: topics[i],
                                width: nodeWidths[i],
                                onOpen: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TopicDetailPage(
                                        book: book,
                                        topic: TopicData(
                                          title: topics[i].title,
                                          youtubeUrl: topics[i].videoUrl,
                                          notes: topics[i].notes,
                                          knowledgeMapImage:
                                              topics[i].knowledgeMapImage,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 12,
                  top: 10,
                  child: Row(
                    children: [
                      Icon(Icons.touch_app_rounded, size: 16, color: kHintGrey),
                      SizedBox(width: 6),
                      Text(
                        'Tap any topic node to open details',
                        style: TextStyle(
                          color: kHintGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopicNode extends StatelessWidget {
  final AdminTopic topic;
  final double width;
  final VoidCallback onOpen;

  const _TopicNode({
    required this.topic,
    required this.width,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Ink(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE2F7)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A101828),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B53D6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  topic.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowledgeLinkPainter extends CustomPainter {
  final Offset center;
  final List<Offset> points;

  const _KnowledgeLinkPainter({required this.center, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length; i++) {
      final target = points[i];
      final t = i / math.max(1, points.length - 1);
      paint.color = Color.lerp(
        const Color(0xFF7A8BFF),
        const Color(0xFF42C0A8),
        t,
      )!.withValues(alpha: 0.75);

      final control = Offset(
        (center.dx + target.dx) / 2,
        (center.dy + target.dy) / 2 + (i.isEven ? -18 : 18),
      );

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(control.dx, control.dy, target.dx, target.dy);

      canvas.drawPath(path, paint);
      canvas.drawCircle(target, 3.5, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant _KnowledgeLinkPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.points != points;
  }
}
