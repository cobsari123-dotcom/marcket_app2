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
  String? _lastPublicationKey;
  Comparable? _lastPublicationSortValue; // Para la paginación con ordenamiento
  bool _hasMorePublications = true;
  StreamSubscription? _publicationSubscription;

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

  FeedProvider() {
    init();
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

  Future<void> loadInitialPublications() async {
    _publicationSubscription?.cancel();
    _isLoadingInitial = true;
    _publications = [];
    _lastPublicationKey = null;
    _lastPublicationSortValue = null;
    _hasMorePublications = true;
    _errorMessage = null;
    notifyListeners();

    await _loadMorePublicationsInternal();

    _isLoadingInitial = false;
    notifyListeners();
  }

  // Método público para cargar más publicaciones, que llama al interno
  Future<void> loadMorePublications() async {
    await _loadMorePublicationsInternal();
  }

  Future<void> _loadMorePublicationsInternal() async {
    if (_isLoadingMore || !_hasMorePublications) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _publicationSubscription = _publicationService
          .getPublicationsStream(
        pageSize: 5,
        startAfterKey: _lastPublicationKey,
        startAfterValue:
            _lastPublicationSortValue?.toString(), // Convertir a String
        category: _selectedCategory,
        sortBy: _sortBy,
        descending: _descending,
      )
          .listen((newPublications) async {
        if (!hasListeners) return;

        if (newPublications.isEmpty) {
          _hasMorePublications = false;
        } else {
          _publications.addAll(newPublications);
          _lastPublicationKey = newPublications.last.id;
          _lastPublicationSortValue =
              _getPublicationSortValue(newPublications.last, _sortBy);
        }

        await _fetchSellerDataForPublications(newPublications);

        _isLoadingMore = false;
        notifyListeners();
      }, onError: (e) {
        if (!hasListeners) return;
        _errorMessage = 'Error al cargar publicaciones: $e';
        _isLoadingMore = false;
        notifyListeners();
      });
    } catch (e) {
      if (!hasListeners) return;
      _errorMessage = 'Error al cargar publicaciones: $e';
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Comparable _getPublicationSortValue(Publication p, String sortBy) {
    switch (sortBy) {
      case 'timestamp':
        return p.timestamp;
      case 'title':
        return p.title;
      // Añadir otros campos de ordenamiento aquí si es necesario
      default:
        return p.timestamp;
    }
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

  @override
  void dispose() {
    _publicationSubscription?.cancel();
    super.dispose();
  }
}
