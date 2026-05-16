import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/library_data.dart';
import 'app_theme.dart';
import 'category_detail_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  Future<List<CategoryData>> _buildFromBooks() async {
    final booksSnapshot = await FirebaseFirestore.instance
        .collection('books')
        .get();

    final names = <String>{};
    for (final doc in booksSnapshot.docs) {
      final data = doc.data();
      final name = (data['category'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        names.add(name);
      }
    }

    if (names.isEmpty) {
      return LibraryCatalog.categories;
    }

    final categories = names
        .map((name) => categoryDataFromName(name, id: name.toLowerCase()))
        .toList();
    categories.sort(
      (left, right) =>
          left.title.toLowerCase().compareTo(right.title.toLowerCase()),
    );
    return categories;
  }

  Future<List<CategoryData>> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      if (snapshot.docs.isEmpty) {
        return _buildFromBooks();
      }

      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        return categoryDataFromName(
          (data['name'] ?? doc.id).toString(),
          id: doc.id,
          subtitle:
              (data['subtitle'] ?? 'Pick a topic area and open the book list.')
                  .toString(),
        );
      }).toList();

      categories.sort(
        (left, right) =>
            left.title.toLowerCase().compareTo(right.title.toLowerCase()),
      );
      return categories;
    } catch (e) {
      print('Error loading categories: $e');
      try {
        return await _buildFromBooks();
      } catch (_) {
        return LibraryCatalog.categories;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view categories.'));
    }

    return FutureBuilder<List<CategoryData>>(
      future: _loadCategories(),
      builder: (context, snapshot) {
        // Show default categories immediately while loading
        final visibleCategories = snapshot.data ?? LibraryCatalog.categories;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _SectionHeader(
              title: 'Categories',
              subtitle: 'Pick a topic area and open the book list.',
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Loading from cloud...',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.08,
              ),
              itemBuilder: (context, index) {
                final category = visibleCategories[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CategoryDetailPage(category: category),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: category.color,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(category.icon, color: kPrimaryBlue),
                          ),
                          const Spacer(),
                          Text(
                            category.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.subtitle,
                            style: const TextStyle(
                              color: kHintGrey,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
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
