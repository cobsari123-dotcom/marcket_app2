import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/services/user_service.dart';
import 'dart:async';

class UserProfileProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUserModel;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _userSubscription;

  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserProfileProvider() {
    _listenToUserChanges();
  }

  void _listenToUserChanges() {
    _auth.authStateChanges().listen((User? user) async {
      _userSubscription?.cancel();
      if (user != null) {
        _userSubscription = _userService.getUserStream(user.uid).listen((userModel) {
          if (!hasListeners) return;
          _currentUserModel = userModel;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        }, onError: (e) {
          if (!hasListeners) return;
          _errorMessage = 'Error al cargar el perfil: $e';
          _isLoading = false;
          notifyListeners();
        });
      } else {
        _currentUserModel = null;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? address,
    String? dob,
    String? rfc,
    String? placeOfBirth,
    String? businessName,
    String? businessAddress,
    String? paymentInstructions,
    bool? isDarkModeEnabled,
    String? profilePicture, // Nuevo parámetro
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _errorMessage = 'Usuario no autenticado para actualizar perfil.';
      notifyListeners();
      return;
    }

    setLoading(true);

    try {
      Map<String, dynamic> data = {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'address': address,
        'dob': dob,
        'rfc': rfc,
        'placeOfBirth': placeOfBirth,
        'businessName': businessName,
        'businessAddress': businessAddress,
        'paymentInstructions': paymentInstructions,
        'isDarkModeEnabled': isDarkModeEnabled,
        'profilePicture': profilePicture,
      };
      
      // Eliminar nulos para que no se sobrescriban campos existentes si no se proveen
      data.removeWhere((key, value) => value == null);

      await _userService.updateUserData(userId, data);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al actualizar el perfil: $e';
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
