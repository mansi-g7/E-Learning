import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../screens/app_theme.dart';

class AdminContactUsPage extends StatelessWidget {
  const AdminContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us Messages')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('contact_us_messages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];

          if (docs.isEmpty) {
            return const Center(child: Text('No messages yet.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: docs.map((doc) {
              final data = doc.data();
              final messageId = doc.id;
              final userName = (data['userName'] ?? 'Unknown').toString();
              final email = (data['email'] ?? '').toString();
              final subject = (data['subject'] ?? '').toString();
              final message = (data['message'] ?? '').toString();
              final status = (data['status'] ?? 'new').toString();
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      color: kHintGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'new'
                                    ? const Color(0xFFFFEAEA)
                                    : const Color(0xFFEAF5EA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status == 'new' ? 'New' : 'Responded',
                                style: TextStyle(
                                  color: status == 'new'
                                      ? const Color(0xFFDA4B4B)
                                      : const Color(0xFF17A36B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          style: const TextStyle(
                            color: kHintGrey,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (createdAt != null)
                          Text(
                            'Received: ${createdAt.toLocal().toString().split('.')[0]}',
                            style: const TextStyle(
                              color: Color(0xFFB8BFC8),
                              fontSize: 10,
                            ),
                          ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminMessageDetailPage(
                                  messageId: messageId,
                                  data: data,
                                ),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('View & Respond'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class AdminMessageDetailPage extends StatefulWidget {
  final String messageId;
  final Map<String, dynamic> data;

  const AdminMessageDetailPage({
    required this.messageId,
    required this.data,
    super.key,
  });

  @override
  State<AdminMessageDetailPage> createState() => _AdminMessageDetailPageState();
}

class _AdminMessageDetailPageState extends State<AdminMessageDetailPage> {
  late TextEditingController _responseController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userName = (widget.data['userName'] ?? 'Unknown').toString();
    final email = (widget.data['email'] ?? '').toString();
    final subject = (widget.data['subject'] ?? '').toString();
    final message = (widget.data['message'] ?? '').toString();
    final createdAt = (widget.data['createdAt'] as Timestamp?)?.toDate();

    return Scaffold(
      appBar: AppBar(title: const Text('Message Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'From',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kHintGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(color: kHintGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Subject',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kHintGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kHintGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: kHintGrey,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Received: ${createdAt.toLocal().toString().split('.')[0]}',
                      style: const TextStyle(
                        color: Color(0xFFB8BFC8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Response',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _responseController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Type your response here...',
              hintStyle: const TextStyle(color: Color(0xFFB8BFC8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDCE2F7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kPrimaryBlue),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sending ? null : _sendResponse,
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              _sending ? 'Sending...' : 'Send Response',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResponse() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please type a response.')));
      return;
    }

    setState(() => _sending = true);

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('contact_us_messages')
          .doc(widget.messageId)
          .update({
            'status': 'responded',
            'updatedAt': FieldValue.serverTimestamp(),
            'adminReply': _responseController.text.trim(),
            'repliedAt': FieldValue.serverTimestamp(),
            'repliedBy': 'Admin',
          });

      await firestore
          .collection('contact_us_messages')
          .doc(widget.messageId)
          .collection('responses')
          .add({
            'adminName': 'Admin',
            'response': _responseController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response sent successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _sending = false);
    }
  }
}
