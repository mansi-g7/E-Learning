import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  late TextEditingController _messageController;
  bool _sending = false;
  String _selectedReason = 'Billing Question';

  final List<String> _reasons = [
    'Billing Question',
    'Technical Support',
    'Account Issue',
    'Course Content',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const SizedBox(height: 8),
          const Text(
            "We're here to help!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Have questions about your E-Learning subscription or need technical support? Drop us a message below.',
            style: TextStyle(color: kHintGrey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.mail_outline_rounded,
                      color: kPrimaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email Us',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'support@e-learning.com',
                          style: TextStyle(
                            color: kPrimaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Response within 24 hours',
                          style: TextStyle(color: kHintGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EDFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.call_outlined,
                      color: kPrimaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Call Us',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '+1 (555) 000-1234',
                          style: TextStyle(
                            color: kPrimaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Mon-Fri, 9am - 5pm',
                          style: TextStyle(color: kHintGrey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Subject',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFDCE2F7)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedReason,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedReason = newValue);
                }
              },
              items: _reasons
                  .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Message',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'How can we help you today?',
              hintStyle: const TextStyle(
                color: Color(0xFFB8BFC8),
                fontSize: 13,
              ),
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
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _sending ? null : _sendMessage,
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(_sending ? 'Sending...' : 'Send Message'),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Follow us on social media',
              style: TextStyle(
                color: kHintGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business_center_rounded,
                    color: kPrimaryBlue,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.facebook_rounded,
                    color: kPrimaryBlue,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your message.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to send a message.')),
      );
      return;
    }
    setState(() => _sending = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('contact_us_messages').doc();

      final payload = {
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'email': user.email ?? '',
        'subject': _selectedReason,
        'message': _messageController.text.trim(),
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Ensure client-side userId matches auth UID to satisfy rules
      if (payload['userId'] != user.uid) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'Auth UID mismatch when sending message.',
        );
      }

      // Use set with generated ID (more explicit than add())
      await docRef.set(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent! We will get back to you soon.'),
          duration: Duration(seconds: 2),
        ),
      );
      _messageController.clear();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      // Provide a clearer message for permission issues or SDK errors
      final msg = e.message ?? e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $msg')));
      // Log to console for debugging
      // ignore: avoid_print
      print('Contact send FirebaseException: $e');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      // ignore: avoid_print
      print('Contact send error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
