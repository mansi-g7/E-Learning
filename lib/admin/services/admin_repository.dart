import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/admin_models.dart';

class AdminRepository {
  AdminRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : auth = auth ?? FirebaseAuth.instance,
       firestore = firestore ?? FirebaseFirestore.instance,
       storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  Future<String?> resolveRoleForUser(User user) async {
    final profile = await _findUserProfile(user);
    return profile?.role;
  }

  Future<AdminUser?> _findUserProfile(User user) async {
    final uidDoc = await firestore.collection('users').doc(user.uid).get();
    if (uidDoc.exists) {
      final data = uidDoc.data();
      if (data != null) {
        return AdminUser(
          id: uidDoc.id,
          name: (data['name'] ?? 'Unknown') as String,
          phone: (data['phone'] ?? '') as String,
          email: (data['email'] ?? user.email ?? '') as String,
          role: (data['role'] ?? 'user') as String,
          joinedAt: _toDateTime(data['joinedAt'] ?? data['createdAt']),
        );
      }
    }

    if (user.email != null && user.email!.isNotEmpty) {
      final emailSnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (emailSnapshot.docs.isNotEmpty) {
        return AdminUser.fromSnapshot(emailSnapshot.docs.first);
      }
    }

    return null;
  }

  Future<AdminUser?> fetchUserProfileByEmail(String email) async {
    final snapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return AdminUser.fromSnapshot(snapshot.docs.first);
  }

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Admin sign-in failed: No user found');
      }

      final profile = await _findUserProfile(user);
      if (profile == null) {
        await auth.signOut();
        throw StateError(
          'User profile not found. Please contact administrator.',
        );
      }

      if (profile.role.toLowerCase() != 'admin') {
        await auth.signOut();
        throw StateError('This account does not have admin privileges.');
      }
    } on StateError {
      rethrow;
    } catch (e) {
      throw StateError('Login failed: ${e.toString()}');
    }
  }

  Future<AdminDashboardStats> fetchDashboardStats() async {
    try {
      final results = await Future.wait([
        firestore.collection('users').get(),
        firestore
            .collection('books')
            .get(), // Removed orderBy to avoid index requirement
        firestore.collection('categories').get(),
        firestore.collection('mybooks').get(),
      ]);

      return AdminDashboardStats(
        usersCount: results[0].docs.length,
        booksCount: results[1].docs.length,
        categoriesCount: results[2].docs.length,
        savedBooksCount: results[3].docs.length,
      );
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return AdminDashboardStats(
        usersCount: 0,
        booksCount: 0,
        categoriesCount: 0,
        savedBooksCount: 0,
      );
    }
  }

  Future<List<AdminCategory>> fetchCategories() async {
    final snapshot = await firestore.collection('categories').get();
    final categories = snapshot.docs.map(AdminCategory.fromSnapshot).toList();
    categories.sort((left, right) {
      final leftDate = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });
    return categories;
  }

  Future<List<AdminUser>> fetchUsers() async {
    final snapshot = await firestore.collection('users').get();
    final users = snapshot.docs.map(AdminUser.fromSnapshot).toList();
    users.sort((left, right) {
      final leftDate = left.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.joinedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });
    return users;
  }

  Future<void> deleteUserProfile(String userId) async {
    await firestore.collection('users').doc(userId).delete();
  }

  Future<void> deleteCategory(String categoryId) async {
    await firestore.collection('categories').doc(categoryId).delete();
  }

  Future<List<AdminBook>> fetchBooks() async {
    final snapshot = await firestore.collection('books').get();
    final books = snapshot.docs.map(AdminBook.fromSnapshot).toList();
    books.sort((left, right) {
      final leftDate = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });
    return books;
  }

  Stream<List<AdminBook>> streamBooks() {
    return firestore.collection('books').snapshots().map((snapshot) {
      final books = snapshot.docs.map(AdminBook.fromSnapshot).toList();
      books.sort((left, right) {
        final leftDate =
            left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightDate =
            right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return rightDate.compareTo(leftDate);
      });
      return books;
    });
  }

  Future<void> syncBookMirrorCollections() async {
    final books = await fetchBooks();
    if (books.isEmpty) {
      return;
    }

    final batch = firestore.batch();

    for (final book in books) {
      final createdAt = book.createdAt ?? FieldValue.serverTimestamp();
      final detailRef = firestore.collection('book_details').doc(book.id);
      final contentRef = firestore.collection('book_content').doc(book.id);

      batch.set(detailRef, {
        'bookId': book.id,
        'title': book.title,
        'description': book.description,
        'category': book.category,
        'thumbnail': book.thumbnailUrl,
        'createdAt': createdAt,
      }, SetOptions(merge: true));

      batch.set(contentRef, {
        'bookId': book.id,
        'title': book.title,
        'notes': book.description,
        'sub_topic': 'Introduction',
        'video_url': '',
        'content': book.description,
        'createdAt': createdAt,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<List<AdminTopic>> fetchTopics(String bookId) async {
    final snapshot = await firestore
        .collection('books')
        .doc(bookId)
        .collection('topics')
        .get();
    final topics = snapshot.docs.map(AdminTopic.fromSnapshot).toList();
    topics.sort((left, right) {
      final leftDate = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });
    return topics;
  }

  Future<void> saveBook({
    String? bookId,
    required String title,
    required String description,
    required String category,
    String? categoryId,
    Uint8List? thumbnailBytes,
    String? existingThumbnailUrl,
  }) async {
    final reference = bookId == null
        ? firestore.collection('books').doc()
        : firestore.collection('books').doc(bookId);
    final existingSnapshot = await reference.get();

    String thumbnailUrl = existingThumbnailUrl ?? '';
    if (thumbnailBytes != null) {
      try {
        thumbnailUrl = await _uploadBytes(
          path: 'book_thumbnails/${reference.id}.jpg',
          bytes: thumbnailBytes,
        );
      } catch (e) {
        print('Thumbnail upload failed, saving book without image: $e');
        thumbnailUrl = ''; // Allow book to be saved without image
      }
    }

    final createdAt =
        existingSnapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp();

    // Save book even if thumbnail is empty (thumbnail is optional)
    final bookData = {
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'categoryId': (categoryId ?? '').trim(),
      'thumbnail': thumbnailUrl,
      'createdAt': createdAt,
    };

    await reference.set(bookData);

    await firestore.collection('book_details').doc(reference.id).set({
      'bookId': reference.id,
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'categoryId': (categoryId ?? '').trim(),
      'thumbnail': thumbnailUrl,
      'createdAt': createdAt,
    }, SetOptions(merge: true));

    await firestore.collection('book_content').doc(reference.id).set({
      'bookId': reference.id,
      'title': title.trim(),
      'notes': description.trim(),
      'sub_topic': 'Introduction',
      'video_url': '',
      'content': description.trim(),
      'categoryId': (categoryId ?? '').trim(),
      'createdAt': createdAt,
    }, SetOptions(merge: true));

    // Send notifications to all users about the new book
    if (bookId == null) {
      // Only send notifications for new books, not updates
      await _sendNotificationToAllUsers(
        bookId: reference.id,
        bookTitle: title.trim(),
      );
    }
  }

  Future<void> _sendNotificationToAllUsers({
    required String bookId,
    required String bookTitle,
  }) async {
    try {
      final usersSnapshot = await firestore.collection('users').get();
      final batch = firestore.batch();
      final now = FieldValue.serverTimestamp();

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final notificationRef = firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(bookId);

        batch.set(notificationRef, {
          'bookId': bookId,
          'bookTitle': bookTitle,
          'message': 'A new book "$bookTitle" has been added to the library.',
          'createdAt': now,
          'read': false,
          'notificationType': 'new_book',
        });
      }

      await batch.commit();
      print('Notifications sent to all users for book: $bookTitle');
    } catch (e) {
      print('Error sending notifications: $e');
      rethrow;
    }
  }

  Future<void> saveCategory({String? categoryId, required String name}) async {
    final reference = categoryId == null
        ? firestore.collection('categories').doc()
        : firestore.collection('categories').doc(categoryId);

    final existingSnapshot = await reference.get();

    await reference.set({
      'name': name.trim(),
      'createdAt':
          existingSnapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBook(String bookId) async {
    final reference = firestore.collection('books').doc(bookId);
    final topicsSnapshot = await reference.collection('topics').get();
    final bookDetailsDoc = firestore.collection('book_details').doc(bookId);
    final bookContentDoc = firestore.collection('book_content').doc(bookId);
    final batch = firestore.batch();

    for (final topic in topicsSnapshot.docs) {
      batch.delete(topic.reference);
    }

    batch.delete(reference);
    batch.delete(bookDetailsDoc);
    batch.delete(bookContentDoc);
    await batch.commit();
  }

  Future<void> saveTopic({
    required String bookId,
    String? topicId,
    required String title,
    required String notes,
    required String videoUrl,
    Uint8List? knowledgeMapBytes,
    String? existingKnowledgeMapImage,
  }) async {
    final reference = topicId == null
        ? firestore.collection('books').doc(bookId).collection('topics').doc()
        : firestore
              .collection('books')
              .doc(bookId)
              .collection('topics')
              .doc(topicId);
    final existingSnapshot = await reference.get();
    final existingData = existingSnapshot.data() ?? const <String, dynamic>{};

    String knowledgeMapImage = existingKnowledgeMapImage ?? '';
    if (knowledgeMapBytes != null) {
      try {
        knowledgeMapImage = await _uploadBytes(
          path: 'topic_maps/$bookId/${reference.id}.jpg',
          bytes: knowledgeMapBytes,
        );
      } catch (e) {
        print('Topic map upload failed, saving topic without new image: $e');
        // Keep previous image when editing, else save without an image.
        knowledgeMapImage =
            existingKnowledgeMapImage ??
            (existingData['knowledgeMapImage'] as String? ?? '');
      }
    }

    final data = <String, Object>{
      'title': title.trim(),
      'notes': notes.trim(),
      'knowledgeMapImage': knowledgeMapImage,
      'videoUrl': videoUrl.trim(),
      'createdAt':
          existingSnapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
    };

    await reference.set(data);
  }

  Future<void> deleteTopic({
    required String bookId,
    required String topicId,
  }) async {
    await firestore
        .collection('books')
        .doc(bookId)
        .collection('topics')
        .doc(topicId)
        .delete();
  }

  Future<String> _uploadBytes({
    required String path,
    required Uint8List bytes,
  }) async {
    try {
      final reference = storage.ref(path);
      print('Uploading to: $path, size: ${bytes.length} bytes');

      final uploadTask = reference.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload timeout after 30 seconds');
        },
      );

      print('Upload complete, getting download URL');
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return null;
}
