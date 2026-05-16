import 'package:flutter/material.dart';

import 'app_theme.dart';

class NotesPage extends StatelessWidget {
  final String bookTitle;
  final String topicTitle;
  final String notes;

  const NotesPage({
    required this.bookTitle,
    required this.topicTitle,
    required this.notes,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bookTitle, style: const TextStyle(color: kHintGrey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(topicTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Text(
                    notes,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF2C3445)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
