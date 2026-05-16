import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/library_data.dart';
import 'app_theme.dart';
import 'book_detail_page.dart';

class ReadingHistoryPage extends StatelessWidget {
  const ReadingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('Please sign in to view reading history.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Reading History')),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('reading_history')
                .orderBy('lastReadAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Center(child: Text('No reading history yet.'));
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    'Recently Read',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...docs.map((doc) {
                    final data = doc.data();
                    final bookId = data['bookId']?.toString() ?? doc.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child:
                          FutureBuilder<
                            List<DocumentSnapshot<Map<String, dynamic>>>
                          >(
                            future: Future.wait([
                              FirebaseFirestore.instance
                                  .collection('books')
                                  .doc(bookId)
                                  .get(),
                              FirebaseFirestore.instance
                                  .collection('mybooks')
                                  .doc('${user.uid}_$bookId')
                                  .get(),
                            ]),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 110,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final bookDoc = snap.data?[0];
                              final mybookDoc = snap.data?[1];

                              BookData book;
                              if (bookDoc != null && bookDoc.exists) {
                                try {
                                  final bdata = bookDoc.data();
                                  if (bdata != null) {
                                    final title =
                                        (bdata['title'] ??
                                                data['title'] ??
                                                'Unknown')
                                            .toString();
                                    final category =
                                        (bdata['category'] ??
                                                data['category'] ??
                                                'General')
                                            .toString();
                                    final description =
                                        (bdata['description'] ?? '').toString();
                                    final author =
                                        (bdata['author'] ??
                                                data['author'] ??
                                                'Author')
                                            .toString();
                                    book = BookData(
                                      id: bookDoc.id,
                                      title: title,
                                      author: author,
                                      category: category,
                                      rating: 4.5,
                                      summary: description,
                                      coverColor: categoryDataFromName(
                                        category,
                                      ).color,
                                      icon: categoryDataFromName(category).icon,
                                      topics: const [],
                                    );
                                  } else {
                                    book = _fallbackFromHistory(data);
                                  }
                                } catch (_) {
                                  book = _fallbackFromHistory(data);
                                }
                              } else {
                                book = _fallbackFromHistory(data);
                              }

                              final progress =
                                  (mybookDoc?.data()?['progress'] ??
                                          data['progress'] ??
                                          0)
                                      as num? ??
                                  0;
                              final lastReadTs =
                                  data['lastReadAt'] as Timestamp?;
                              final lastReadStr = _formatDate(lastReadTs);

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: book.coverColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          book.icon,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book.title,
                                              style: const TextStyle(
                                                fontSize: 15,
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
                                            Text(
                                              'Last read: $lastReadStr',
                                              style: const TextStyle(
                                                color: kHintGrey,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            LinearProgressIndicator(
                                              value:
                                                  progress.clamp(0, 100) /
                                                  100.0,
                                              backgroundColor: const Color(
                                                0xFFEDEEF8,
                                              ),
                                              color: kPrimaryBlue,
                                              minHeight: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BookDetailPage(book: book),
                                            ),
                                          );
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: kPrimaryBlue,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        child: const Text('Resume'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static BookData _fallbackFromHistory(Map<String, dynamic> data) {
    final colorVal = data['coverColor'] as int?;
    final color = colorVal != null
        ? Color(colorVal)
        : categoryDataFromName(
            (data['category'] ?? 'General').toString(),
          ).color;
    return BookData(
      id: data['bookId']?.toString() ?? 'unknown',
      title: data['title']?.toString() ?? 'Unknown',
      author: data['author']?.toString() ?? 'Author',
      category: data['category']?.toString() ?? 'General',
      rating: 4.5,
      summary: data['summary']?.toString() ?? '',
      coverColor: color,
      icon: categoryDataFromName(
        (data['category'] ?? 'General').toString(),
      ).icon,
      topics: const [],
    );
  }

  static String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Unknown';
    final dt = ts.toDate().toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
