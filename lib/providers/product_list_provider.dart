import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar FirebaseAuth
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/services/product_service.dart';
import 'dart:async';

class ProductListProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instancia de FirebaseAuth

  List<Product> _products = [];
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _lastProductKey;
  bool _hasMoreProducts = true;
  StreamSubscription? _authSubscription; // Escucha los cambios de autenticación

  List<Product> get products => _products;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMoreProducts => _hasMoreProducts;

  ProductListProvider() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadInitialProducts(); // Cargar productos cuando el usuario inicia sesión
      } else {
        // Limpiar el estado si el usuario cierra sesión
        _products = [];
        _isLoadingInitial = false;
        _isLoadingMore = false;
        _errorMessage = null;
        _lastProductKey = null;
        _hasMoreProducts = true;
        notifyListeners();
      }
    });
  }

  Future<void> _loadInitialProducts() async {
    _isLoadingInitial = true;
    _products = [];
    _lastProductKey = null;
    _hasMoreProducts = true;
    _errorMessage = null;
    notifyListeners();

    await loadMoreProducts(); // Llamar al método público para cargar la primera página

    _isLoadingInitial = false;
    notifyListeners();
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final userId =
          _auth.currentUser?.uid; // Obtener el userId del usuario actual
      if (userId == null) {
        _errorMessage = 'Usuario no autenticado.';
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final newProducts = await _productService.getSellerProductsPaginated(
        userId,
        pageSize: 10,
        startAfterKey: _lastProductKey,
      );

      if (!hasListeners) return;

      if (newProducts.isEmpty) {
        _hasMoreProducts = false;
      } else {
        _products.addAll(newProducts);
        _lastProductKey = newProducts.last.id;
      }

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      if (!hasListeners) return;
      _errorMessage = 'Error al cargar productos: $e';
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Método público para refrescar la lista
  Future<void> refreshProducts() async {
    await _loadInitialProducts();
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // Cancelar la suscripción de autenticación
    super.dispose();
  }
}
