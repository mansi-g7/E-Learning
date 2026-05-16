import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/models/admin_models.dart';
import '../models/library_data.dart';
import 'book_detail_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(
          child: Text('Please sign in to view notifications.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), elevation: 0),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notifDoc = notifications[index];
              final notifData = notifDoc.data();
              final bookId = notifData['bookId'] as String?;
              final bookTitle = notifData['bookTitle'] as String? ?? 'New Book';
              final message =
                  notifData['message'] as String? ??
                  'A new book has been added';
              final createdAt = notifData['createdAt'] as Timestamp?;
              final isRead = notifData['read'] as bool? ?? false;

              return _NotificationTile(
                bookId: bookId,
                bookTitle: bookTitle,
                message: message,
                createdAt: createdAt,
                isRead: isRead,
                userId: user.uid,
                notificationId: notifDoc.id,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String? bookId;
  final String bookTitle;
  final String message;
  final Timestamp? createdAt;
  final bool isRead;
  final String userId;
  final String notificationId;

  const _NotificationTile({
    required this.bookId,
    required this.bookTitle,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.userId,
    required this.notificationId,
  });

  void _markAsRead(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  void _navigateToBook(BuildContext context) async {
    if (bookId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book not found')));
      return;
    }

    try {
      final bookDoc = await FirebaseFirestore.instance
          .collection('books')
          .doc(bookId)
          .get();

      if (!bookDoc.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Book not found')));
        }
        return;
      }

      final bookData = bookDoc.data();
      if (bookData == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Book data is invalid')));
        }
        return;
      }

      final adminBook = AdminBook(
        id: bookId!,
        title: (bookData['title'] ?? 'Untitled Book') as String,
        description: (bookData['description'] ?? '') as String,
        category: (bookData['category'] ?? 'General') as String,
        categoryId: (bookData['categoryId'] ?? '') as String,
        thumbnailUrl: (bookData['thumbnail'] ?? '') as String,
        createdAt: _parseDateTime(bookData['createdAt']),
      );
      final book = _mapAdminBookToBookData(adminBook);

      if (context.mounted) {
        // Mark notification as read
        _markAsRead(context);

        // Navigate to book detail
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => BookDetailPage(book: book)));
      }
    } catch (e) {
      print('Error navigating to book: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading book: $e')));
      }
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  BookData _mapAdminBookToBookData(AdminBook adminBook) {
    final cat = LibraryCatalog.categories.firstWhere(
      (c) => c.title == adminBook.category,
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
      topics: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isRead ? Colors.transparent : Colors.blue.withValues(alpha: 0.05),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isRead ? Colors.grey : Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          bookTitle,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message),
            const SizedBox(height: 4),
            Text(
              _formatTime(createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () => _navigateToBook(context),
      ),
    );
  }
}
