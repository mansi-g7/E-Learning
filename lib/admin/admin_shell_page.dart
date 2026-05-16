import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/login_page.dart';
import 'screens/admin_books_page.dart';
import 'screens/admin_categories_page.dart';
import 'screens/admin_dashboard_page.dart';
import 'screens/admin_users_page.dart';
import 'screens/book_form_page.dart';
import 'services/admin_repository.dart';

class AdminShellPage extends StatelessWidget {
  final User? authUser;

  const AdminShellPage({this.authUser, super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AdminRepository>(
      create: (_) => AdminRepository(),
      child: _AdminShellView(authUser: authUser),
    );
  }
}

class _AdminShellView extends StatefulWidget {
  final User? authUser;

  const _AdminShellView({required this.authUser});

  @override
  State<_AdminShellView> createState() => _AdminShellViewState();
}

class _AdminShellViewState extends State<_AdminShellView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      AdminDashboardPage(
        onAddBook: _openBookForm,
        onOpenBooks: () => setState(() => _selectedIndex = 1),
        onOpenCategories: () => setState(() => _selectedIndex = 2),
        onManageUsers: () => setState(() => _selectedIndex = 3),
      ),
      const AdminBooksPage(),
      const AdminCategoriesPage(),
      const AdminUsersPage(),
    ];

    final titles = <String>['Dashboard', 'Books', 'Categories', 'Users'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                widget.authUser?.email ?? 'Admin',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A6274)),
              ),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          if (isWide) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: Text('Books'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.grid_view_outlined),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: Text('Categories'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_alt_outlined),
                      selectedIcon: Icon(Icons.people_alt_rounded),
                      label: Text('Users'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IndexedStack(index: _selectedIndex, children: pages),
                  ),
                ),
              ],
            );
          }

          return IndexedStack(index: _selectedIndex, children: pages);
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width >= 980
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Books',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Categories',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt_rounded),
                  label: 'Users',
                ),
              ],
            ),
    );
  }

  Future<void> _logout() async {
    if (widget.authUser != null) {
      await FirebaseAuth.instance.signOut();
    }
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openBookForm() async {
    final repository = context.read<AdminRepository>();
    final shouldRefresh = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BookFormPage(repository: repository),
      ),
    );

    if (shouldRefresh == true && mounted) {
      setState(() => _selectedIndex = 1);
    }
  }
}
