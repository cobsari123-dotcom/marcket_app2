import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/services/product_service.dart';
import 'package:marcket_app/services/user_service.dart';
import 'dart:async';

class FeedProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  List<Product> _products = [];
  final Map<String, UserModel> _sellerData = {};
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _hasMoreProducts = true;

  // Variables for pagination
  String? _lastProductKey;
  dynamic _lastProductSortValue;

  // Parámetros de filtro y ordenamiento
  String? _selectedCategory;
  String _sortBy = 'timestamp';
  bool _descending = true;

  List<Product> get products => _products;
  Map<String, UserModel> get sellerData => _sellerData;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMoreProducts => _hasMoreProducts;
  String? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get descending => _descending;

  bool get isLoading => _isLoadingInitial || _isLoadingMore;
  bool get hasError => _errorMessage != null;

  FeedProvider() {
    init();
  }

  void clearAndFetchProducts() {
    _products = [];
    _sellerData.clear();
    _lastProductKey = null;
    _lastProductSortValue = null;
    _hasMoreProducts = true;
    _isLoadingInitial = true;
    notifyListeners();
    loadInitialProducts();
  }

  Future<void> fetchPublications({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await loadInitialPublications();
    } else {
      await loadMorePublications();
    }
  }

  Future<void> init() async {
    await loadInitialProducts();
  }

  // Remove toggleLike as it's for publications and products do not have this directly

  Future<void> loadInitialProducts() async {
    await _fetchProducts(isInitialFetch: true);
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    _isLoadingMore = true;
    notifyListeners();

    await _fetchProducts(isInitialFetch: false);

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _fetchSellerDataForProducts(List<Product> products) async {
    final Set<String> sellerIds = products.map((p) => p.sellerId).toSet();
    for (final id in sellerIds) {
      if (!_sellerData.containsKey(id)) {
        final seller = await _userService.getUserById(id);
        if (seller != null) {
          _sellerData[id] = seller;
        }
      }
    }
  }

  // Métodos para actualizar filtros
  void setCategory(String? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      loadInitialPublications(); // Recargar todo con el nuevo filtro
    }
  }

  void setSortBy(String sortBy) {
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      loadInitialPublications(); // Recargar todo con el nuevo orden
    }
  }

  void setDescending(bool descending) {
    if (_descending != descending) {
      _descending = descending;
      loadInitialPublications(); // Recargar todo con el nuevo orden
    }
  }
}