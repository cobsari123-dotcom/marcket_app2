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

  // --- CORRECCIÓN: Getter agregado para usar en los Switches ---
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Si es sistema, asumimos light por defecto o podrías checar el brillo del sistema
      // Pero para el switch, es mejor devolver true si está explícitamente en dark.
      return false; 
    }
    return _themeMode == ThemeMode.dark;
  }

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

  // --- CORRECCIÓN: Método agregado para cambiar el tema ---
  Future<void> toggleTheme() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      bool currentStatus = isDarkMode;
      // Actualizamos Firebase, el listener _listenToThemeChanges se encargará de actualizar la UI
      await FirebaseDatabase.instance.ref('users/${user.uid}').update({
        'isDarkModeEnabled': !currentStatus
      });
    } else {
      // Si no hay usuario (caso raro en esta app), cambiamos localmente
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      notifyListeners();
    }
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