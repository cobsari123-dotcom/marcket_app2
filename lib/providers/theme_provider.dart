import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:marcket_app/models/user.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  StreamSubscription? _authStateSubscription;
  StreamSubscription? _userSettingsSubscription;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _listenToThemeChanges();
  }

  void _listenToThemeChanges() {
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _userSettingsSubscription?.cancel();

      if (user != null) {
        _userSettingsSubscription = FirebaseDatabase.instance.ref('users/${user.uid}').onValue.listen((event) {
          if (event.snapshot.exists) {
            final userData = UserModel.fromMap(
              Map<String, dynamic>.from(event.snapshot.value as Map),
              user.uid,
            );
            final newThemeMode = userData.isDarkModeEnabled ?? false ? ThemeMode.dark : ThemeMode.light;
            if (_themeMode != newThemeMode) {
              _themeMode = newThemeMode;
              notifyListeners();
            }
          } else {
            _resetTheme();
          }
        });
      } else {
        _resetTheme();
      }
    });
  }

  void _resetTheme() {
    if (_themeMode != ThemeMode.system) {
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _userSettingsSubscription?.cancel();
    super.dispose();
  }
}
