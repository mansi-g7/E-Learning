import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../screens/app_theme.dart';

class AdminSavedBooksPage extends StatelessWidget {
  const AdminSavedBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Books by Users')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('mybooks').snapshots(),
        builder: (context, snapshot) {
          final myBooksDocs = snapshot.data?.docs ?? const [];
          if (myBooksDocs.isEmpty) {
            return const Center(child: Text('No books saved yet.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const SizedBox(height: 8),
              Text(
                'User Book Saves (${myBooksDocs.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'All books saved by users',
                style: const TextStyle(color: kHintGrey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ...myBooksDocs.map((mybook) {
                return _SavedBookUserTile(myBookDoc: mybook);
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SavedBookUserTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> myBookDoc;

  const _SavedBookUserTile({required this.myBookDoc});

  @override
  Widget build(BuildContext context) {
    final data = myBookDoc.data();
    final bookId = (data['bookId'] ?? myBookDoc.id).toString();
    final userId = data['userId'] as String?;
    final savedAt = data['createdAt'] as Timestamp?;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('books').doc(bookId).get(),
      builder: (context, bookSnapshot) {
        if (bookSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final bookData = bookSnapshot.data?.data();
        final bookTitle = bookData?['title'] ?? 'Unknown Book';
        final bookCategory = bookData?['category'] ?? 'General';

        if (userId == null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bookCategory,
                      style: const TextStyle(color: kHintGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    const Text('User information not available'),
                  ],
                ),
              ),
            ),
          );
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get(),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data();
            final userName = userData?['name'] ?? 'Unknown User';
            final userEmail = userData?['email'] ?? 'No email';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Title
                      Text(
                        bookTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Category
                      Text(
                        bookCategory,
                        style: const TextStyle(color: kHintGrey, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Name
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: kPrimaryBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'User Name',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: kHintGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // User Email
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email_rounded,
                                    size: 16,
                                    color: kPrimaryBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Email',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: kHintGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          userEmail,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Saved At
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 16,
                                    color: kPrimaryBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Saved At',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: kHintGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatDate(savedAt),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
