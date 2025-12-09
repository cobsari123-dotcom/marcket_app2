import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/services/publication_service.dart';
import 'package:marcket_app/services/user_service.dart';
import 'dart:async';

class FeedProvider with ChangeNotifier {
  final PublicationService _publicationService = PublicationService();
  final UserService _userService = UserService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  List<Publication> _publications = [];
  final Map<String, UserModel> _sellerData = {};
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _hasMorePublications = true;

  // Variables for pagination
  // ignore: unused_field
  String? _lastPublicationKey;
  // ignore: unused_field
  dynamic _lastPublicationSortValue;

  // Parámetros de filtro y ordenamiento
  String? _selectedCategory;
  String _sortBy = 'timestamp';
  bool _descending = true;

  List<Publication> get publications => _publications;
  Map<String, UserModel> get sellerData => _sellerData;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMorePublications => _hasMorePublications;
  String? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get descending => _descending;

  bool get isLoading => _isLoadingInitial || _isLoadingMore;
  bool get hasError => _errorMessage != null;

  FeedProvider() {
    init();
  }

  void clearAndFetchPublications() {
    _publications = [];
    _sellerData.clear();
    _lastPublicationKey = null;
    _lastPublicationSortValue = null;
    _hasMorePublications = true;
    _isLoadingInitial = true;
    notifyListeners();
    loadInitialPublications();
  }

  Future<void> fetchPublications({bool forceRefresh = false}) async {
    if (forceRefresh) {
      await loadInitialPublications();
    } else {
      await loadMorePublications();
    }
  }

  Future<void> init() async {
    await loadInitialPublications();
  }

  Future<void> toggleLike(String publicationId) async {
    if (_currentUserId == null) return;

    final pubIndex = _publications.indexWhere((p) => p.id == publicationId);
    if (pubIndex == -1) return;

    final publication = _publications[pubIndex];
    final bool isLiked = publication.likes.containsKey(_currentUserId);

    // Optimistic update
    if (isLiked) {
      _publications[pubIndex].likes.remove(_currentUserId);
    } else {
      _publications[pubIndex].likes[_currentUserId] = true;
    }
    notifyListeners();

    try {
      await _publicationService.toggleLike(publicationId);
    } catch (e) {
      // Revert on error
      if (isLiked) {
        _publications[pubIndex].likes[_currentUserId] = true;
      } else {
        _publications[pubIndex].likes.remove(_currentUserId);
      }
      _errorMessage = "Error al actualizar el 'me gusta'.";
      notifyListeners();
    }
  }

  Future<void> _fetchPublications({bool isInitialFetch = false}) async {
    _errorMessage = null;
    if (isInitialFetch) {
      _isLoadingInitial = true;
      _publications = [];
      _sellerData.clear();
      _lastPublicationKey = null;
      _lastPublicationSortValue = null;
      _hasMorePublications = true;
      notifyListeners();
    } else if (!_hasMorePublications) {
      return;
    }

    try {
      final result = await _publicationService.getPublications(
        startAfterKey: _lastPublicationKey,
        startAfterValue: _lastPublicationSortValue,
        limit: 10, // Define a page size
        sortBy: _sortBy,
        descending: _descending,
      );

      final List<Publication> fetchedPublications = result['publications'];
      _lastPublicationKey = result['lastKey'];
      _lastPublicationSortValue = result['lastSortValue'];
      _hasMorePublications = fetchedPublications.length == 10; // Assuming 10 is the page size

      if (!hasListeners) return;

      if (isInitialFetch) {
        _publications = fetchedPublications;
      } else {
        _publications.addAll(fetchedPublications);
      }
      await _fetchSellerDataForPublications(fetchedPublications);
    } catch (e) {
      if (!hasListeners) return;
      _errorMessage = 'Error al cargar publicaciones: $e';
    } finally {
      if (hasListeners) {
        _isLoadingInitial = false;
        // _isLoadingMore is not used here as it's part of the provider state logic
        notifyListeners();
      }
    }
  }

  Future<void> loadInitialPublications() async {
    await _fetchPublications(isInitialFetch: true);
  }

  Future<void> loadMorePublications() async {
    if (_isLoadingMore || !_hasMorePublications) return;

    _isLoadingMore = true;
    notifyListeners();

    await _fetchPublications(isInitialFetch: false);

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _fetchSellerDataForPublications(
      List<Publication> publications) async {
    final Set<String> sellerIds = publications.map((p) => p.sellerId).toSet();
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