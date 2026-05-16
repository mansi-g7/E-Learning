import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/admin_models.dart';
import '../services/admin_repository.dart';
import 'book_form_page.dart';
import 'book_topics_page.dart';

class AdminBooksPage extends StatefulWidget {
  final bool openCreateFlow;

  const AdminBooksPage({this.openCreateFlow = false, super.key});

  @override
  State<AdminBooksPage> createState() => _AdminBooksPageState();
}

class _AdminBooksPageState extends State<AdminBooksPage> {
  @override
  void initState() {
    super.initState();
    if (widget.openCreateFlow) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openBookForm());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-books-add-book-fab',
        onPressed: _openBookForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
      body: StreamBuilder<List<AdminBook>>(
        stream: context.read<AdminRepository>().streamBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load books',
              subtitle: snapshot.error.toString(),
            );
          }

          final books = snapshot.data ?? const <AdminBook>[];
          if (books.isEmpty) {
            return _EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No books yet',
              subtitle:
                  'Create the first book to start adding topics and content.',
              actionLabel: 'Add Book',
              onAction: _openBookForm,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: book.thumbnailUrl.isEmpty
                          ? Container(
                              color: const Color(0xFFE8ECFF),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Color(0xFF3B53D6),
                              ),
                            )
                          : Image.network(book.thumbnailUrl, fit: BoxFit.cover),
                    ),
                  ),
                  title: Text(
                    book.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${book.category}\n${book.description}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _openBookForm(existingBook: book);
                      } else if (value == 'topics') {
                        final repository = context.read<AdminRepository>();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BookTopicsPage(
                              book: book,
                              repository: repository,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        await _confirmDelete(book);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit book')),
                      PopupMenuItem(
                        value: 'topics',
                        child: Text('Manage topics'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete book'),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final repository = context.read<AdminRepository>();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            BookTopicsPage(book: book, repository: repository),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openBookForm({AdminBook? existingBook}) async {
    final repository = context.read<AdminRepository>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            BookFormPage(existingBook: existingBook, repository: repository),
      ),
    );
  }

  Future<void> _confirmDelete(AdminBook book) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text(
          'This will remove "${book.title}" and all of its topics.',
        ),
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

    if (shouldDelete != true) {
      return;
    }

    try {
      await context.read<AdminRepository>().deleteBook(book.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Book deleted')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
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
            Icon(icon, size: 52, color: const Color(0xFF98A2B3)),
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
