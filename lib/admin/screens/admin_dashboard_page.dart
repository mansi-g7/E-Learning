import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_contact_us_page.dart';
import 'admin_saved_books_page.dart';
import '../models/admin_models.dart';
import '../services/admin_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  final VoidCallback onAddBook;
  final VoidCallback onOpenBooks;
  final VoidCallback onOpenCategories;
  final VoidCallback onManageUsers;

  const AdminDashboardPage({
    required this.onAddBook,
    required this.onOpenBooks,
    required this.onOpenCategories,
    required this.onManageUsers,
    super.key,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Future<AdminDashboardStats>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminRepository>().syncBookMirrorCollections();
    });
  }

  void _reload() {
    _future = context.read<AdminRepository>().fetchDashboardStats();
  }

  Future<void> _refresh() async {
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage books, users, and learning content from one place.',
            style: TextStyle(color: Color(0xFF667085)),
          ),
          const SizedBox(height: 18),
          StreamBuilder<AdminDashboardStats>(
            stream: _dashboardStatsStream(),
            initialData: _future == null ? null : null,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorCard(
                  message:
                      snapshot.error?.toString() ??
                      'Could not load dashboard data.',
                );
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final stats = snapshot.data!;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  final crossAxisCount = isWide ? 4 : 1;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.8 : 2.6,
                    children: [
                      _StatCard(
                        title: 'Users',
                        value: stats.usersCount.toString(),
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF3B53D6),
                        onTap: widget.onManageUsers,
                      ),
                      _StatCard(
                        title: 'Books',
                        value: stats.booksCount.toString(),
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF17A36B),
                        onTap: widget.onOpenBooks,
                      ),
                      _StatCard(
                        title: 'Categories',
                        value: stats.categoriesCount.toString(),
                        icon: Icons.grid_view_rounded,
                        color: const Color(0xFFE06A2F),
                        onTap: widget.onOpenCategories,
                      ),
                      _StatCard(
                        title: 'Saved',
                        value: stats.savedBooksCount.toString(),
                        icon: Icons.bookmark_rounded,
                        color: const Color(0xFF7A4FD6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminSavedBooksPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionButton(
                icon: Icons.add_circle_outline_rounded,
                label: 'Add Book',
                onTap: widget.onAddBook,
              ),
              _ActionButton(
                icon: Icons.support_agent_outlined,
                label: 'Contact Us',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminContactUsPage(),
                    ),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.category_outlined,
                label: 'Add Category',
                onTap: () => _showAddCategoryDialog(context),
              ),
              _ActionButton(
                icon: Icons.people_outline_rounded,
                label: 'Manage Users',
                onTap: widget.onManageUsers,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final _controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Category name'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Enter a category name' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (shouldCreate != true) return;

    try {
      await context.read<AdminRepository>().saveCategory(
        name: _controller.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category created')));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

extension on _AdminDashboardPageState {
  Stream<AdminDashboardStats> _dashboardStatsStream() {
    final repository = context.read<AdminRepository>();
    return StreamZip([
      repository.firestore.collection('users').snapshots(),
      repository.firestore
          .collection('books')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      repository.firestore.collection('categories').snapshots(),
      repository.firestore.collection('mybooks').snapshots(),
    ]).map(
      (values) => AdminDashboardStats(
        usersCount: (values[0] as QuerySnapshot).docs.length,
        booksCount: (values[1] as QuerySnapshot).docs.length,
        categoriesCount: (values[2] as QuerySnapshot).docs.length,
        savedBooksCount: (values[3] as QuerySnapshot).docs.length,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(color: Color(0xFF667085)),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }
}
