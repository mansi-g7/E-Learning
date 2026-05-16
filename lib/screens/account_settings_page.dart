import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import '../services/app_settings_controller.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _auth = FirebaseAuth.instance;

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email available for this account')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: user!.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickLanguage() async {
    final settings = context.read<AppSettingsController>();

    const languages = <String>[
      'English (US)',
      'English (UK)',
      'Gujarati',
      'Hindi',
      'Spanish',
      'French',
      'Arabic',
      'Bengali',
      'Marathi',
      'Tamil',
      'Telugu',
    ];

    final choice = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemBuilder: (context, index) {
          final language = languages[index];
          return ListTile(
            leading: const Icon(Icons.language_rounded, color: kPrimaryBlue),
            title: Text(language),
            onTap: () => Navigator.pop(context, language),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: languages.length,
      ),
    );

    if (choice != null) {
      await settings.setLanguage(choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Account Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SectionTitle(title: 'SECURITY'),
              const SizedBox(height: 10),
              _SectionCard(
                child: Column(
                  children: [
                    _SettingTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Change Password',
                      subtitle: 'Send reset link to your email',
                      onTap: _changePassword,
                      showChevron: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'NOTIFICATIONS'),
              const SizedBox(height: 10),
              _SectionCard(
                child: Column(
                  children: [
                    _SettingSwitchTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Push Notifications',
                      value: settings.pushNotifications,
                      onChanged: settings.setPushNotifications,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'PREFERENCES'),
              const SizedBox(height: 10),
              _SectionCard(
                child: Column(
                  children: [
                    _SettingSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: settings.setDarkMode,
                    ),
                    const Divider(height: 1),
                    _SettingTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: settings.language,
                      onTap: _pickLanguage,
                      showChevron: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: settings.isHydrating
                      ? null
                      : () async {
                          await settings.saveAll(
                            pushNotifications: settings.pushNotifications,
                            darkMode: settings.themeMode == ThemeMode.dark,
                            language: settings.language,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settings saved')),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: kPrimaryBlue.withValues(alpha: 0.25),
                  ),
                  child: settings.isHydrating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
          if (settings.isHydrating)
            const Positioned(
              left: 0,
              right: 0,
              top: 12,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF7B7F8C),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: child,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EDFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kPrimaryBlue, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: kHintGrey),
            ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right_rounded, color: Color(0xFFB5B9C5))
          : null,
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EDFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kPrimaryBlue, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: kPrimaryBlue,
    );
  }
}
