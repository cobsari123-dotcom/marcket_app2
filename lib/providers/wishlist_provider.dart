import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/services/user_service.dart';
import 'dart:async';

class WishlistProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _wishlistProductIds = [];
  StreamSubscription? _wishlistSubscription;
  StreamSubscription? _authSubscription;
  bool _isLoading = true;

  List<String> get wishlistProductIds => _wishlistProductIds;
  bool get isLoading => _isLoading;

  WishlistProvider() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToWishlist(user.uid);
      } else {
        _wishlistSubscription?.cancel();
        _wishlistProductIds = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _listenToWishlist(String userId) {
    _wishlistSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _wishlistSubscription =
        _userService.getWishlistStream(userId).listen((productIds) {
      if (!hasListeners) return;
      _wishlistProductIds = productIds;
      _isLoading = false;
      notifyListeners();
    });
  }

  bool isFavorite(String productId) {
    return _wishlistProductIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Actualiza el estado local inmediatamente para una respuesta de UI rápida
    if (isFavorite(productId)) {
      _wishlistProductIds.remove(productId);
    } else {
      _wishlistProductIds.add(productId);
    }
    notifyListeners();

    // Luego, actualiza la base de datos en segundo plano
    try {
      await _userService.toggleFavorite(userId, productId);
    } catch (e) {
      // Si falla, revierte el cambio en la UI y notifica el error (opcional)
      _listenToWishlist(userId); // Vuelve a sincronizar con la base de datos
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _wishlistSubscription?.cancel();
    super.dispose();
  }
}
