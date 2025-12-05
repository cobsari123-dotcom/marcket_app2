import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/services/user_service.dart';
import 'dart:async';

class AdminDashboardProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedIndex = 0;
  UserModel? _currentUserModel;
  bool _isLoadingUserData = true;
  String? _errorMessage;
  StreamSubscription? _userSubscription;

  int get selectedIndex => _selectedIndex;
  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoadingUserData => _isLoadingUserData;
  String? get errorMessage => _errorMessage;

  AdminDashboardProvider() {
    _listenToUserChanges();
  }

  void _listenToUserChanges() {
    _auth.authStateChanges().listen((User? user) async {
      _userSubscription?.cancel();
      if (user != null) {
        _userSubscription = _userService.getUserStream(user.uid).listen((userModel) {
          if (!hasListeners) return;
          _currentUserModel = userModel;
          _isLoadingUserData = false;
          _errorMessage = null;
          notifyListeners();
        }, onError: (e) {
          if (!hasListeners) return;
          _errorMessage = 'Error al cargar datos del administrador: $e';
          _isLoadingUserData = false;
          notifyListeners();
        });
      } else {
        _currentUserModel = null;
        _isLoadingUserData = false;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
