import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/models/admin_models.dart';
import '../models/library_data.dart';
import 'app_theme.dart';
import 'book_detail_page.dart';

class CategoryDetailPage extends StatelessWidget {
  final CategoryData category;

  const CategoryDetailPage({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(title: Text(category.title)),
        body: const Center(
          child: Text('Please sign in to view category content.'),
        ),
      );
    }

    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: Text(category.title)),
      body: FutureBuilder<List<AdminBook>>(
        future: firestore.collection('books').get().then((snapshot) {
          final books = snapshot.docs
              .map((d) => AdminBook.fromSnapshot(d))
              .where(
                (book) =>
                    _normalizeCategory(book.categoryId) ==
                        _normalizeCategory(category.id) ||
                    _normalizeCategory(book.category) ==
                        _normalizeCategory(category.title),
              )
              .toList();

          books.sort((left, right) {
            final leftDate =
                left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final rightDate =
                right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return rightDate.compareTo(leftDate);
          });

          return books;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final books = snapshot.data ?? const <AdminBook>[];

          return FutureBuilder<Set<String>>(
            future: firestore
                .collection('mybooks')
                .where('userId', isEqualTo: user.uid)
                .get()
                .then(
                  (savedSnapshot) => savedSnapshot.docs
                      .map((doc) => (doc.data()['bookId'] ?? doc.id).toString())
                      .toSet(),
                ),
            builder: (context, savedSnapshot) {
              final savedIds = savedSnapshot.data ?? const <String>{};

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: category.color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(category.icon, color: kPrimaryBlue),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category.subtitle,
                                  style: const TextStyle(
                                    color: kHintGrey,
                                    fontSize: 12,
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
                  const Text(
                    'Book List',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (books.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No books found in this category yet. Add books from Admin panel using this category.',
                          style: TextStyle(color: kHintGrey),
                        ),
                      ),
                    ),
                  ...books.map((book) {
                    final mapped = _mapAdminBookToBookData(
                      book,
                      category.title,
                    );
                    final isSaved = savedIds.contains(mapped.id);

                    return Padding(
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
                                  color: mapped.coverColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  mapped.icon,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mapped.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mapped.author,
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
                                        Text(mapped.rating.toStringAsFixed(1)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  FilledButton(
                                    onPressed: () async {
                                      try {
                                        await firestore
                                            .collection('users')
                                            .doc(user.uid)
                                            .collection('reading_history')
                                            .doc(mapped.id)
                                            .set({
                                              'bookId': mapped.id,
                                              'title': mapped.title,
                                              'author': mapped.author,
                                              'category': mapped.category,
                                              'lastReadAt':
                                                  FieldValue.serverTimestamp(),
                                              'coverColor': mapped
                                                  .coverColor
                                                  .value, // ignore: deprecated_member_use
                                            }, SetOptions(merge: true));
                                      } catch (_) {}

                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BookDetailPage(book: mapped),
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
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _toggleSaved(context, mapped, isSaved),
                                    icon: Icon(
                                      isSaved
                                          ? Icons.bookmark_remove_outlined
                                          : Icons.bookmark_add_outlined,
                                      size: 18,
                                    ),
                                    label: Text(isSaved ? 'Saved' : 'Save'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleSaved(
    BuildContext context,
    BookData book,
    bool isSaved,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('mybooks')
        .doc('${user.uid}_${book.id}');

    if (isSaved) {
      await docRef.delete();
    } else {
      await docRef.set({
        'userId': user.uid,
        'bookId': book.id,
        'title': book.title,
        'category': book.category,
        'thumbnail': '',
        'addedAt': FieldValue.serverTimestamp(),
        'progress': 0,
      });
    }
  }

  BookData _mapAdminBookToBookData(AdminBook adminBook, String categoryTitle) {
    final cat = LibraryCatalog.categories.firstWhere(
      (c) => c.title == categoryTitle,
      orElse: () => LibraryCatalog.categories.first,
    );

    return BookData(
      id: adminBook.id,
      title: adminBook.title,
      author: 'Author',
      category: adminBook.category,
      rating: 4.5,
      summary: adminBook.description,
      coverColor: cat.color,
      icon: cat.icon,
      topics: const <TopicData>[],
    );
  }

  String _normalizeCategory(String value) {
    return value.trim().toLowerCase();
  }
}
