import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/admin_models.dart';
import '../services/admin_repository.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  Future<List<AdminUser>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<AdminRepository>().fetchUsers();
  }

  Future<void> _refresh() async {
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminUser>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final users = snapshot.data ?? const <AdminUser>[];
        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8ECFF),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF3B53D6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(user.email),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'view') {
                        await _showDetails(user);
                      } else if (value == 'delete') {
                        await _deleteUser(user);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('View details')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete user'),
                      ),
                    ],
                  ),
                  onTap: () => _showDetails(user),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showDetails(AdminUser user) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            const SizedBox(height: 8),
            Text('Phone: ${user.phone.isNotEmpty ? user.phone : 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Role: ${user.role}'),
            const SizedBox(height: 8),
            Text(
              'Joined: ${user.joinedAt?.toLocal().toString().split('.').first ?? 'Unknown'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(AdminUser user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'Remove ${user.name} from the Firestore users collection?',
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

    await context.read<AdminRepository>().deleteUserProfile(user.id);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('User deleted')));
    await _refresh();
  }
}
