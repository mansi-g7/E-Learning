import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/models/admin_models.dart';
import '../models/library_data.dart';
import 'app_theme.dart';
import 'book_detail_page.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting &&
            authSnapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (authSnapshot.data == null) {
          return const Center(
            child: Text('Please sign in to view saved books.'),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('mybooks')
              .where('userId', isEqualTo: authSnapshot.data!.uid)
              .snapshots(),
          builder: (context, savedSnapshot) {
            final savedBookIds = (savedSnapshot.data?.docs ?? const [])
                .map((doc) => (doc.data()['bookId'] ?? doc.id).toString())
                .toSet();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final allBooks = (snapshot.data?.docs ?? const [])
                    .map(AdminBook.fromSnapshot)
                    .map(_mapAdminBookToBookData)
                    .toList();

                final savedBooks = allBooks
                    .where((book) => savedBookIds.contains(book.id))
                    .toList();

                if (savedBooks.isEmpty) {
                  return _EmptyState(
                    onBrowse: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Open Categories to save your first book',
                          ),
                        ),
                      );
                    },
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    const _SectionHeader(
                      title: 'Saved books',
                      subtitle: 'Books you liked and saved for later.',
                    ),
                    const SizedBox(height: 12),
                    ...savedBooks.map(
                      (book) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 58,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: book.coverColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    book.icon,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
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
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 16,
                                            color: Color(0xFFF6B000),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(book.rating.toStringAsFixed(1)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    FilledButton(
                                      onPressed: () async {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user != null) {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user.uid)
                                                .collection('reading_history')
                                                .doc(book.id)
                                                .set({
                                                  'bookId': book.id,
                                                  'title': book.title,
                                                  'author': book.author,
                                                  'category': book.category,
                                                  'lastReadAt':
                                                      FieldValue.serverTimestamp(),
                                                  'coverColor': book
                                                      .coverColor
                                                      .value, // ignore: deprecated_member_use
                                                }, SetOptions(merge: true));
                                          } catch (_) {}
                                        }

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
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                      ),
                                      child: const Text('Open'),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => _toggleSaved(book.id),
                                      icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Unsave'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  BookData _mapAdminBookToBookData(AdminBook adminBook) {
    final categoryData = categoryDataFromName(adminBook.category);
    return BookData(
      id: adminBook.id,
      title: adminBook.title,
      author: 'Author',
      category: adminBook.category,
      rating: 4.5,
      summary: adminBook.description,
      coverColor: categoryData.color,
      icon: categoryData.icon,
      topics: const [],
    );
  }

  Future<void> _toggleSaved(String bookId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('mybooks')
        .doc('${user.uid}_$bookId')
        .delete();
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBrowse;

  const _EmptyState({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E8FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: kPrimaryBlue,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No saved books yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Go to Categories and save a book to show it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kHintGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onBrowse,
              child: const Text('Browse categories'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: kHintGrey, fontSize: 12)),
      ],
    );
  }
}
