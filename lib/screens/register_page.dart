import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_theme.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Text(
                            'Create Account',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Join our E-Learning\nCommunity',
                        style: TextStyle(
                          fontSize: 36,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start your reading journey today.',
                        style: TextStyle(color: kHintGrey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      authLabel('Full Name'),
                      TextField(
                        controller: _nameController,
                        decoration: authInputDecoration(
                          hint: 'Enter your full name',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      authLabel('Phone Number'),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: authInputDecoration(
                          hint: 'Enter your phone number',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      authLabel('Email Address'),
                      TextField(
                        controller: _emailController,
                        decoration: authInputDecoration(
                          hint: 'example@email.com',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      authLabel('Password'),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: authInputDecoration(
                          hint: 'Create a password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      authLabel('Confirm Password'),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_showConfirmPassword,
                        decoration: authInputDecoration(
                          hint: 'Repeat your password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: () => setState(
                              () =>
                                  _showConfirmPassword = !_showConfirmPassword,
                            ),
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      authPrimaryButton(
                        text: _isLoading ? 'Registering...' : 'Register',
                        onTap: _isLoading ? () {} : _register,
                      ),
                      const SizedBox(height: 10),
                      authDivider('OR REGISTER WITH'),
                      const SizedBox(height: 10),
                      authSecondaryButton(
                        text: _isLoading ? 'Please wait...' : 'Google',
                        onTap: _isLoading ? () {} : _registerWithGoogle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user == null) {
        throw StateError('Registration failed.');
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final auth = FirebaseAuth.instance;
      UserCredential credential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        credential = await auth.signInWithPopup(googleProvider);
      } else {
        final googleSignIn = GoogleSignIn(scopes: ['email']);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign-in cancelled.')),
          );
          return;
        }

        final googleAuth = await googleUser.authentication;
        final googleCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await auth.signInWithCredential(googleCredential);
      }

      final user = credential.user;
      if (user == null) {
        throw StateError('Google sign-in failed.');
      }

      await _upsertUserProfile(user);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _upsertUserProfile(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    final existingData = snapshot.data() ?? const <String, dynamic>{};

    await ref.set({
      'name': user.displayName ?? existingData['name'] ?? 'User',
      'phone': existingData['phone'] ?? '',
      'email': user.email ?? existingData['email'] ?? '',
      'role': existingData['role'] ?? 'user',
      'createdAt': existingData['createdAt'] ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
