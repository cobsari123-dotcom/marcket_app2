import 'package:flutter/material.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/services/product_service.dart';
import 'package:marcket_app/services/user_service.dart';
import 'dart:async';

class FeedProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  // final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid; // Removed as it's unused

  List<Product> _products = [];
  final Map<String, UserModel> _sellerData = {};
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _hasMoreProducts = true;

  // Variables for pagination
  // ignore: unused_field
  String? _lastProductKey;
  // ignore: unused_field
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

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await loadInitialProducts();
    } else {
      await loadMoreProducts();
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

  Future<void> _fetchProducts({bool isInitialFetch = false}) async {
    _errorMessage = null;
    if (isInitialFetch) {
      _isLoadingInitial = true;
      _products = [];
      _sellerData.clear();
      _lastProductKey = null;
      _lastProductSortValue = null;
      _hasMoreProducts = true;
      notifyListeners();
    } else if (!_hasMoreProducts) {
      return;
    }

    try {
      final result = await _productService.getProducts(
        startAfterKey: _lastProductKey,
        startAfterValue: _lastProductSortValue,
        limit: 10, // Define a page size
        sortBy: _sortBy,
        descending: _descending,
      );

      final List<Product> fetchedProducts = result['products'];
      _lastProductKey = result['lastKey'];
      _lastProductSortValue = result['lastSortValue'];
      _hasMoreProducts = fetchedProducts.length == 10; // Assuming 10 is the page size

      if (!hasListeners) return;

      if (isInitialFetch) {
        _products = fetchedProducts;
      } else {
        _products.addAll(fetchedProducts);
      }
      await _fetchSellerDataForProducts(fetchedProducts);
    } catch (e) {
      if (!hasListeners) return;
      _errorMessage = 'Error al cargar productos: $e';
    } finally {
      if (hasListeners) {
        _isLoadingInitial = false;
        // _isLoadingMore is not used here as it's part of the provider state logic
        notifyListeners();
      }
    }
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
      loadInitialProducts(); // Recargar todo con el nuevo filtro
    }
  }

  void setSortBy(String sortBy) {
    if (_sortBy != sortBy) {
      loadInitialProducts(); // Recargar todo con el nuevo orden
    }
  }

  void setDescending(bool descending) {
    if (_descending != descending) {
      _descending = descending;
      loadInitialProducts(); // Recargar todo con el nuevo orden
    }
  }
}