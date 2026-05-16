import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

class ProfileDetailsPage extends StatefulWidget {
  final User user;

  const ProfileDetailsPage({required this.user, super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();

    final data = doc.data() ?? const <String, dynamic>{};
    _nameController.text =
        (data['name'] ?? widget.user.displayName ?? 'Learner').toString();
    _emailController.text = (data['email'] ?? widget.user.email ?? '')
        .toString();
    _phoneController.text = (data['phone'] ?? '').toString();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
            'name': name,
            'email': email,
            'phone': phone,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await widget.user.updateDisplayName(name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: const Text('Profile Details'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: const Color(0xFFE8ECFF),
                          backgroundImage:
                              widget.user.photoURL != null &&
                                  widget.user.photoURL!.isNotEmpty
                              ? NetworkImage(widget.user.photoURL!)
                              : null,
                          child:
                              widget.user.photoURL == null ||
                                  widget.user.photoURL!.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: kPrimaryBlue,
                                )
                              : null,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Profile photo upload will be added next.',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: kPrimaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Edit Photo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Center(
                    child: Text(
                      'Update your profile picture',
                      style: TextStyle(color: kHintGrey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 18),
                  authLabel('Full Name'),
                  TextFormField(
                    controller: _nameController,
                    decoration: authInputDecoration(
                      hint: 'Your full name',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  authLabel('Email Address'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: authInputDecoration(
                      hint: 'you@email.com',
                      icon: Icons.mail_outline_rounded,
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty || !text.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  authLabel('Phone Number'),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: authInputDecoration(
                      hint: 'Your phone number',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update Profile',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'EduBook v2.4.0 • Secured Data',
                      style: TextStyle(color: Color(0xFF9AA1B3), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
