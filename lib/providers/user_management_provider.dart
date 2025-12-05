import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/services/user_service.dart';
import 'dart:async';

class UserManagementProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  StreamSubscription? _usersSubscription;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  UserManagementProvider() {
    init();
  }

  void init() {
    _listenToUserChanges();
  }

  void _listenToUserChanges() {
    _usersSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _usersSubscription = _usersRef.onValue.listen((event) {
      if (!hasListeners) return;

      final snapshot = event.snapshot;
      if (snapshot.value == null) {
        _users = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final Map<dynamic, dynamic> usersMap = snapshot.value as Map<dynamic, dynamic>;
      List<UserModel> fetchedUsers = [];
      usersMap.forEach((key, value) {
        fetchedUsers.add(UserModel.fromMap(Map<String, dynamic>.from(value), key));
      });

      _users = fetchedUsers;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      if (!hasListeners) return;
      _errorMessage = 'Error al cargar usuarios: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  Future<void> deleteUser(UserModel user) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _userService.deleteUser(user.id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al eliminar usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }
}
