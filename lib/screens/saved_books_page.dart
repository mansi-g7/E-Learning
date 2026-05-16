import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin/models/admin_models.dart';
import '../models/library_data.dart';
import 'app_theme.dart';
import 'book_detail_page.dart';

class SavedBooksPage extends StatelessWidget {
  const SavedBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Books')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('mybooks').snapshots(),
        builder: (context, snapshot) {
          final myBooksDocs = snapshot.data?.docs ?? const [];
          if (myBooksDocs.isEmpty) {
            return const Center(child: Text('No books saved yet.'));
          }

          // Get unique book IDs
          final bookIds = myBooksDocs
              .map((doc) => (doc.data()['bookId'] ?? doc.id).toString())
              .toSet();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('books').snapshots(),
            builder: (context, booksSnapshot) {
              final allBooks = (booksSnapshot.data?.docs ?? const [])
                  .map(AdminBook.fromSnapshot)
                  .toList();

              final savedBooks = allBooks
                  .where((book) => bookIds.contains(book.id))
                  .toList();

              if (savedBooks.isEmpty) {
                return const Center(child: Text('No saved books available.'));
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Saved Books (${savedBooks.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Books saved by ${myBooksDocs.length} users',
                    style: const TextStyle(color: kHintGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ...savedBooks.map((book) {
                    // Count how many users saved this book
                    final saveCount = myBooksDocs
                        .where(
                          (doc) =>
                              (doc.data()['bookId'] ?? doc.id).toString() ==
                              book.id,
                        )
                        .length;

                    final categoryData = categoryDataFromName(book.category);
                    final bookData = BookData(
                      id: book.id,
                      title: book.title,
                      author: 'Author',
                      category: book.category,
                      rating: 4.5,
                      summary: book.description,
                      coverColor: categoryData.color,
                      icon: categoryData.icon,
                      topics: const [],
                    );

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
                                  color: bookData.coverColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  bookData.icon,
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
                                      book.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      book.category,
                                      style: const TextStyle(
                                        color: kHintGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.bookmark_rounded,
                                          size: 16,
                                          color: kPrimaryBlue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$saveCount save${saveCount == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            color: kPrimaryBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BookDetailPage(book: bookData),
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
                                child: const Text('View'),
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
}
