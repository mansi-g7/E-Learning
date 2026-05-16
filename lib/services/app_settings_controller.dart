import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppSettingsController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;

  ThemeMode _themeMode = ThemeMode.light;
  Locale? _locale;
  String _language = 'English (US)';
  bool _pushNotifications = false;
  bool _hydrating = false;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  String get language => _language;
  bool get pushNotifications => _pushNotifications;
  bool get isHydrating => _hydrating;

  AppSettingsController() {
    _authSubscription = _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _themeMode = ThemeMode.light;
      _locale = null;
      _language = 'English (US)';
      _pushNotifications = false;
      _hydrating = false;
      notifyListeners();
      return;
    }

    _hydrating = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? <String, dynamic>{};
      final rawSettings = data['settings'];
      final settings = rawSettings is Map<String, dynamic>
          ? rawSettings
          : <String, dynamic>{};

      _pushNotifications = settings['pushNotifications'] == true;
      _themeMode = settings['darkMode'] == true
          ? ThemeMode.dark
          : ThemeMode.light;

      final language = (settings['language'] ?? '').toString();
      if (language.trim().isNotEmpty) {
        _language = language;
      } else {
        _language = 'English (US)';
      }
      _locale = _localeFromLanguage(language);
    } catch (_) {
      _themeMode = ThemeMode.light;
      _locale = null;
      _language = 'English (US)';
      _pushNotifications = false;
    } finally {
      _hydrating = false;
      notifyListeners();
    }
  }

  Future<void> setPushNotifications(bool enabled) async {
    _pushNotifications = enabled;
    notifyListeners();
    await _persistSetting('pushNotifications', enabled);
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _persistSetting('darkMode', enabled);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    _locale = _localeFromLanguage(language);
    notifyListeners();
    await _persistSetting('language', language);
  }

  Future<void> saveAll({
    required bool pushNotifications,
    required bool darkMode,
    required String language,
  }) async {
    _pushNotifications = pushNotifications;
    _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    _language = language;
    _locale = _localeFromLanguage(language);
    notifyListeners();

    await _persistAll(
      pushNotifications: pushNotifications,
      darkMode: darkMode,
      language: language,
    );
  }

  Future<void> _persistSetting(String key, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'settings': {key: value},
    }, SetOptions(merge: true));
  }

  Future<void> _persistAll({
    required bool pushNotifications,
    required bool darkMode,
    required String language,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'settings': {
        'pushNotifications': pushNotifications,
        'darkMode': darkMode,
        'language': language,
      },
    }, SetOptions(merge: true));
  }

  Locale? _localeFromLanguage(String language) {
    switch (language) {
      case 'Gujarati':
        return const Locale('gu');
      case 'Hindi':
        return const Locale('hi');
      case 'Spanish':
        return const Locale('es');
      case 'French':
        return const Locale('fr');
      case 'Arabic':
        return const Locale('ar');
      case 'Bengali':
        return const Locale('bn');
      case 'Marathi':
        return const Locale('mr');
      case 'Tamil':
        return const Locale('ta');
      case 'Telugu':
        return const Locale('te');
      case 'English (UK)':
      case 'English (US)':
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
