import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/admin_models.dart';
import '../services/admin_repository.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  Future<List<AdminCategory>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<AdminRepository>().fetchCategories();
  }

  Future<void> _refresh() async {
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-categories-add-category-fab',
        onPressed: _addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: FutureBuilder<List<AdminCategory>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final categories = snapshot.data ?? const <AdminCategory>[];
          if (categories.isEmpty) {
            return _EmptyState(
              title: 'No categories yet',
              subtitle: 'Create categories so users can browse books by topic.',
              actionLabel: 'Add Category',
              onAction: _addCategory,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8ECFF),
                      child: Icon(
                        Icons.category_rounded,
                        color: Color(0xFF3B53D6),
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('ID: ${category.id}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _editCategory(category);
                        } else if (value == 'delete') {
                          await _deleteCategory(category);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit category'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete category'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _addCategory() async {
    await _showCategoryDialog();
  }

  Future<void> _editCategory(AdminCategory category) async {
    await _showCategoryDialog(category: category);
  }

  Future<void> _deleteCategory(AdminCategory category) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete "${category.name}" from Firestore?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await context.read<AdminRepository>().deleteCategory(category.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Category deleted')));
    await _refresh();
  }

  Future<void> _showCategoryDialog({AdminCategory? category}) async {
    final controller = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Category name'),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter a category name' : null,
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    await context.read<AdminRepository>().saveCategory(
      categoryId: category?.id,
      name: controller.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Category saved')));
    await _refresh();
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.category_rounded,
              size: 52,
              color: Color(0xFF98A2B3),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
