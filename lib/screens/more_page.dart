import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'about_page.dart';
import 'account_settings_page.dart';
import 'profile_details_page.dart';
import 'reading_history_page.dart';
import 'contact_us_page.dart';
import 'notifications_page.dart';

class MorePage extends StatelessWidget {
  final VoidCallback onLogout;

  const MorePage({required this.onLogout, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return const Center(
            child: Text('Please sign in to view your account.'),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            final profile =
                profileSnapshot.data?.data() ?? const <String, dynamic>{};
            final displayName = _resolveDisplayName(user, profile);

            void openProfileDetails() {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileDetailsPage(user: user),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _ProfileCard(
                  user: user,
                  displayName: displayName,
                  onEdit: openProfileDetails,
                ),
                const SizedBox(height: 14),
                _MenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile Details',
                  onTap: openProfileDetails,
                ),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'Account Settings',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.history_rounded,
                  title: 'Reading History',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReadingHistoryPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _NotificationMenuTile(
                  userId: user.uid,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Contact Us',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ContactUsPage()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About App',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutPage()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _LogoutTile(onLogout: onLogout),
              ],
            );
          },
        );
      },
    );
  }

  String _resolveDisplayName(User user, Map<String, dynamic> profile) {
    final fromProfile = (profile['name'] ?? '').toString().trim();
    if (fromProfile.isNotEmpty) {
      return fromProfile;
    }

    final fromAuth = (user.displayName ?? '').trim();
    if (fromAuth.isNotEmpty) {
      return fromAuth;
    }

    final email = (user.email ?? '').trim();
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'Learner';
  }
}

class _ProfileCard extends StatelessWidget {
  final User user;
  final String displayName;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.user,
    required this.displayName,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFE8ECFF),
              backgroundImage:
                  user.photoURL != null && user.photoURL!.isNotEmpty
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null || user.photoURL!.isEmpty
                  ? const Icon(Icons.person_rounded, color: kPrimaryBlue)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _MenuTile({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kPrimaryBlue, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9BA3B5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutTile({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onLogout,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFE1E1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDA4B4B), size: 20),
            SizedBox(width: 10),
            Text(
              'Logout Account',
              style: TextStyle(
                color: Color(0xFFDA4B4B),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationMenuTile extends StatelessWidget {
  final String userId;
  final VoidCallback onTap;

  const _NotificationMenuTile({required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EDFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: kPrimaryBlue,
                          size: 20,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9BA3B5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
