import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return null;
}

class AdminDashboardStats {
  final int usersCount;
  final int booksCount;
  final int categoriesCount;
  final int savedBooksCount;

  const AdminDashboardStats({
    required this.usersCount,
    required this.booksCount,
    required this.categoriesCount,
    required this.savedBooksCount,
  });
}

class AdminCategory {
  final String id;
  final String name;
  final DateTime? createdAt;

  const AdminCategory({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory AdminCategory.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return AdminCategory(
      id: snapshot.id,
      name: (data['name'] ?? 'General') as String,
      createdAt: _toDateTime(data['createdAt']),
    );
  }
}

class AdminUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final DateTime? joinedAt;

  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  factory AdminUser.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return AdminUser(
      id: snapshot.id,
      name: (data['name'] ?? 'Unknown') as String,
      phone: (data['phone'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      role: (data['role'] ?? 'user') as String,
      joinedAt: _toDateTime(data['joinedAt'] ?? data['createdAt']),
    );
  }
}

class AdminBook {
  final String id;
  final String title;
  final String description;
  final String category;
  final String categoryId;
  final String thumbnailUrl;
  final DateTime? createdAt;

  const AdminBook({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryId,
    required this.thumbnailUrl,
    required this.createdAt,
  });

  factory AdminBook.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return AdminBook(
      id: snapshot.id,
      title: (data['title'] ?? 'Untitled Book') as String,
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? 'General') as String,
      categoryId: (data['categoryId'] ?? '') as String,
      thumbnailUrl: (data['thumbnail'] ?? '') as String,
      createdAt: _toDateTime(data['createdAt']),
    );
  }
}

class AdminTopic {
  final String id;
  final String title;
  final String notes;
  final String knowledgeMapImage;
  final String videoUrl;
  final double? posX;
  final double? posY;
  final DateTime? createdAt;

  const AdminTopic({
    required this.id,
    required this.title,
    required this.notes,
    required this.knowledgeMapImage,
    required this.videoUrl,
    this.posX,
    this.posY,
    required this.createdAt,
  });

  factory AdminTopic.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return AdminTopic(
      id: snapshot.id,
      title: (data['title'] ?? 'Untitled Topic') as String,
      notes: (data['notes'] ?? '') as String,
      knowledgeMapImage: (data['knowledgeMapImage'] ?? '') as String,
      videoUrl: (data['videoUrl'] ?? '') as String,
      posX: (data['posX'] is num) ? (data['posX'] as num).toDouble() : null,
      posY: (data['posY'] is num) ? (data['posY'] as num).toDouble() : null,
      createdAt: _toDateTime(data['createdAt']),
    );
  }
}
