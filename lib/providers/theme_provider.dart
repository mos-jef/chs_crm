// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider extends ChangeNotifier {
  String _currentTheme = 'athlete_dark';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentTheme => _currentTheme;
  bool get isDarkMode => _currentTheme.contains('_dark');
  bool get isAthleteTheme => _currentTheme.contains('athlete');
  bool get isNinjaTheme => _currentTheme.contains('ninja');

  ThemeProvider() {
    _loadTheme();
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    if (user != null) {
      _loadThemeFromFirebase();
    }
  }

  void setTheme(String themeName) async {
    _currentTheme = themeName;
    notifyListeners();
    await _saveTheme();
    await _saveThemeToFirebase();
  }

  void toggleLightDark() async {
    if (_currentTheme == 'athlete_light') {
      _currentTheme = 'athlete_dark';
    } else if (_currentTheme == 'athlete_dark') {
      _currentTheme = 'athlete_light';
    } else if (_currentTheme == 'ninja_light') {
      _currentTheme = 'ninja_dark';
    } else if (_currentTheme == 'ninja_dark') {
      _currentTheme = 'ninja_light';
    }
    notifyListeners();
    await _saveTheme();
    await _saveThemeToFirebase();
  }

  void switchToAthlete() async {
    if (isDarkMode) {
      _currentTheme = 'athlete_dark';
    } else {
      _currentTheme = 'athlete_light';
    }
    notifyListeners();
    await _saveTheme();
    await _saveThemeToFirebase();
  }

  void switchToNinja() async {
    if (isDarkMode) {
      _currentTheme = 'ninja_dark';
    } else {
      _currentTheme = 'ninja_light';
    }
    notifyListeners();
    await _saveTheme();
    await _saveThemeToFirebase();
  }

  // Local storage (for offline/guest users)
  _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentTheme = prefs.getString('currentTheme') ?? 'athlete_dark';
    notifyListeners();
  }

  _saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('currentTheme', _currentTheme);
  }

  // Firebase storage (for logged-in users)
  _loadThemeFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final userData = doc.data()!;
          _currentTheme = userData['preferredTheme'] ?? 'athlete_dark';
          notifyListeners();
          // Also save locally for faster loading
          await _saveTheme();
        }
      }
    } catch (e) {
      print('Error loading theme from Firebase: $e');
    }
  }

  _saveThemeToFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'preferredTheme': _currentTheme,
        });
      }
    } catch (e) {
      print('Error saving theme to Firebase: $e');
    }
  }

  String get themeDisplayName {
    switch (_currentTheme) {
      case 'athlete_light':
        return 'Athlete Light';
      case 'athlete_dark':
        return 'Athlete Dark';
      case 'ninja_light':
        return 'Ninja Light';
      case 'ninja_dark':
        return 'Ninja Dark';
      default:
        return 'Athlete Dark';
    }
  }
}
