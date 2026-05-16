import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Seeds Firebase Auth and Firestore with test accounts and data.
/// This creates the necessary test accounts and data for the app to function properly.
Future<void> initializeFirebaseData() async {
  try {
    await _createTestAccounts();
  } catch (e) {
    // Ignore account creation failures
    print('Firebase account creation error (non-fatal): $e');
  }

  // Try to seed data but don't fail the app if it doesn't work
  // This allows the app to run even if seeding fails
  try {
    await _seedFirestore();
  } catch (e) {
    // Ignore seeding failures so app launch is not blocked.
    print('Firebase seeding error (non-fatal): $e');
  }
}

/// Creates test user and admin accounts if they don't exist
Future<void> _createTestAccounts() async {
  final auth = FirebaseAuth.instance;

  final testAccounts = [
    {
      'email': 'user@example.com',
      'password': 'User@123456',
      'name': 'Example User',
      'role': 'user',
    },
    {
      'email': 'admin@example.com',
      'password': 'Admin@123456',
      'name': 'Admin User',
      'role': 'admin',
    },
  ];

  for (final account in testAccounts) {
    try {
      // Try to sign in first
      try {
        await auth.signInWithEmailAndPassword(
          email: account['email']!,
          password: account['password']!,
        );
        // Already exists, sign out
        await auth.signOut();
        continue;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'user-not-found') {
          rethrow;
        }
        // User not found, proceed to create
      }

      // Create the account
      try {
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: account['email']!,
          password: account['password']!,
        );

        // Create user document in Firestore
        if (userCredential.user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
                  'name': account['name'],
                  'email': account['email'],
                  'role': account['role'],
                  'phone': '',
                  'createdAt': FieldValue.serverTimestamp(),
                });
            print('Created user: ${account['email']}');
          } catch (fsError) {
            print('Could not create Firestore user doc: $fsError');
          }
        }

        await auth.signOut();
      } catch (createError) {
        print('Could not create auth account: $createError');
      }
    } catch (e) {
      print('Error processing account ${account['email']}: $e');
    }
  }
}

/// Seeds Firestore with minimal collections/documents required by the app.
Future<void> _seedFirestore() async {
  final firestore = FirebaseFirestore.instance;

  Future<void> ensureDocument(
    String collection,
    Map<String, Object?> data,
    String documentId,
  ) async {
    try {
      final doc = await firestore.collection(collection).doc(documentId).get();
      if (!doc.exists) {
        await firestore.collection(collection).doc(documentId).set(data);
        print('Created $collection/$documentId');
      }
    } catch (e) {
      print('Error creating $collection/$documentId: $e');
    }
  }

  try {
    // Create categories with proper structure
    await ensureDocument('categories', {
      'name': 'Flutter Development',
      'subtitle': 'Learn Flutter app development',
      'description': 'Master Flutter with comprehensive tutorials',
      'icon': 'flutter',
      'createdAt': FieldValue.serverTimestamp(),
    }, 'flutter_dev');

    await ensureDocument('categories', {
      'name': 'Web Development',
      'subtitle': 'Learn web development',
      'description': 'Build modern web applications',
      'icon': 'web',
      'createdAt': FieldValue.serverTimestamp(),
    }, 'web_dev');

    await ensureDocument('categories', {
      'name': 'Dart Programming',
      'subtitle': 'Master Dart language',
      'description': 'Deep dive into Dart programming',
      'icon': 'code',
      'createdAt': FieldValue.serverTimestamp(),
    }, 'dart_prog');

    // Create sample books
    await ensureDocument('books', {
      'title': 'Flutter Development Guide',
      'author': 'Flutter Team',
      'description':
          'Learn Flutter development from basics to advanced concepts',
      'category': 'Flutter Development',
      'categoryId': 'flutter_dev',
      'coverUrl': '',
      'rating': 4.5,
      'createdAt': FieldValue.serverTimestamp(),
    }, 'book_001');

    await ensureDocument('books', {
      'title': 'Web Development Essentials',
      'author': 'Web Experts',
      'description': 'Build responsive and modern web applications',
      'category': 'Web Development',
      'categoryId': 'web_dev',
      'coverUrl': '',
      'rating': 4.8,
      'createdAt': FieldValue.serverTimestamp(),
    }, 'book_002');

    print('✓ Firestore seeding completed successfully');
  } catch (e) {
    print('⚠ Firestore seeding warning: $e');
  }
}
