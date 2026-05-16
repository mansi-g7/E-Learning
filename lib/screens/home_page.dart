import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/models/admin_models.dart';
import '../models/library_data.dart';
import 'app_theme.dart';
import 'book_detail_page.dart';
import 'category_page.dart';
import 'login_page.dart';
import 'more_page.dart';
import 'wishlist_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = <Widget>[
    _HomeTab(onOpenBook: _openBook, onOpenCategory: _openCategory),
    const WishlistPage(),
    const CategoryPage(),
    MorePage(onLogout: _logout),
  ];

  @override
  Widget build(BuildContext context) {
    const titles = <String>['Home', 'My Books', 'Categories', 'More'];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimaryBlue,
        unselectedItemColor: const Color(0xFF8A8F9D),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'My Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  void _openBook(BookData book) async {
    final user = FirebaseAuth.instance.currentUser;
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
              'lastReadAt': FieldValue.serverTimestamp(),
              'coverColor':
                  book.coverColor.value, // ignore: deprecated_member_use
            }, SetOptions(merge: true));
      } catch (_) {}
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
    );
  }

  void _openCategory(CategoryData category) {
    // Open the main categories list page instead of a single category detail
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryPage()),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

class _HomeTab extends StatelessWidget {
  final void Function(BookData book) onOpenBook;
  final void Function(CategoryData category) onOpenCategory;

  const _HomeTab({required this.onOpenBook, required this.onOpenCategory});

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
            child: Text('Please sign in to view home content.'),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('categories')
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? const [];
            final categories = docs
                .map(
                  (doc) => categoryDataFromName(
                    (doc.data()['name'] ?? doc.id).toString(),
                  ),
                )
                .toList();

            final firstCategory = categories.isNotEmpty
                ? categories.first
                : categoryDataFromName('General');

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, booksSnapshot) {
                final featuredBooks = (booksSnapshot.data?.docs ?? const [])
                    .map(AdminBook.fromSnapshot)
                    .take(4)
                    .map(_mapAdminBookToBookData)
                    .toList();
                final featuredBook = featuredBooks.isNotEmpty
                    ? featuredBooks.first
                    : null;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _HeroCard(
                      onOpenCategory: onOpenCategory,
                      onOpenBook: onOpenBook,
                      featuredCategory: firstCategory,
                      featuredBook: featuredBook,
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Could not load categories: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    if (booksSnapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Could not load books: ${booksSnapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    const _SectionHeader(
                      title: 'Featured Books',
                      subtitle: 'Books added from the admin panel.',
                    ),
                    const SizedBox(height: 12),
                    if (featuredBooks.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('No books added by admin yet.'),
                        ),
                      )
                    else
                      ...featuredBooks.map(
                        (book) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FeaturedBookCard(
                            book: book,
                            onTap: () => onOpenBook(book),
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
}

class _HeroCard extends StatelessWidget {
  final void Function(CategoryData category) onOpenCategory;
  final void Function(BookData book) onOpenBook;
  final CategoryData featuredCategory;
  final BookData? featuredBook;

  const _HeroCard({
    required this.onOpenCategory,
    required this.onOpenBook,
    required this.featuredCategory,
    required this.featuredBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2038B6), Color(0xFF3B53D6)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2340C7),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -55,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              final textBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Keep learning with simple lessons and beautiful pages.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Browse featured books, save what you like, and open knowledge maps when you want to learn deeper.',
                    style: TextStyle(
                      color: Color(0xFFE9EEFF),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: featuredBook == null
                        ? null
                        : () => onOpenBook(featuredBook!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Open latest book'),
                  ),
                ],
              );

              final imageBlock = Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2B000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'lib/assets/topbar.png',
                    width: 120,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: textBlock),
                    const SizedBox(width: 14),
                    imageBlock,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textBlock,
                  const SizedBox(height: 16),
                  Center(child: imageBlock),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturedBookCard extends StatelessWidget {
  final BookData book;
  final VoidCallback onTap;

  const _FeaturedBookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      book.coverColor,
                      book.coverColor.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: book.coverColor.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(book.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9EEFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            book.category,
                            style: const TextStyle(
                              color: Color(0xFF3450DA),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          book.author,
                          style: const TextStyle(
                            color: kHintGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.summary,
                      style: const TextStyle(
                        color: kHintGrey,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF6B000),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          book.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        const Text(
                          'Open',
                          style: TextStyle(
                            color: kPrimaryBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: kPrimaryBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
