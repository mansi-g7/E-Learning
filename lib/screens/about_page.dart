import 'package:flutter/material.dart';

import 'app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'About App',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2FA9B4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: kPrimaryBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'E-Learning',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Version 2.4.0',
                    style: TextStyle(
                      color: kPrimaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Our Mission',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            'E-Learning is dedicated to making learning accessible to everyone, everywhere. Our platform provides a vast library of e-books to empower students and lifelong learners with the tools they need to succeed in their educational journey.',
            style: TextStyle(
              color: Color(0xFF5E6575),
              fontSize: 13,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 18),
          const Text(
            'Legal & Credits',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _LegalCard(
            title: 'Terms of Service',
            icon: Icons.description_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const _LegalPage(
                    title: 'Terms of Service',
                    body:
                        'These are the terms of service for the E-Learning app.\n\n1. Use the app responsibly.\n2. Content is for learning purposes.\n3. Respect copyright and community rules.\n4. The platform may update policies at any time.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _LegalCard(
            title: 'Privacy Policy',
            icon: Icons.gavel_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const _LegalPage(
                    title: 'Privacy Policy',
                    body:
                        'This privacy policy explains how E-Learning handles your information.\n\n- We store account details to sign you in.\n- We save preferences and reading history to improve your experience.\n- We do not sell your data.\n- You may contact support for data requests.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 34),
          const Center(
            child: Text(
              '© 2026 E-Learning Inc.',
              style: TextStyle(color: Color(0xFF9AA1B1), fontSize: 12),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Made with ❤ for learners worldwide',
              style: TextStyle(color: Color(0xFFB1B7C5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _LegalCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8ECFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: kPrimaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF99A1B1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalPage extends StatelessWidget {
  final String title;
  final String body;

  const _LegalPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF5E6575),
            ),
          ),
        ],
      ),
    );
  }
}
