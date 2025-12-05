import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/order.dart';
import 'package:marcket_app/services/user_service.dart'; // Para obtener nombre del comprador
import 'dart:async';

class SellerOrderListProvider with ChangeNotifier {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref('orders');
  final UserService _userService = UserService();

  List<Order> _orders = [];
  final Map<String, String> _buyerNames = {}; // Cache para nombres de compradores
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _lastOrderKey;
  bool _hasMoreOrders = true;
  StreamSubscription? _ordersSubscription;

  List<Order> get orders => _orders;
  Map<String, String> get buyerNames => _buyerNames;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMoreOrders => _hasMoreOrders;

  SellerOrderListProvider() {
    init();
  }

  Future<void> init() async {
    _ordersSubscription?.cancel();
    _isLoadingInitial = true;
    _orders = [];
    _lastOrderKey = null;
    _hasMoreOrders = true;
    _errorMessage = null;
    notifyListeners();

    await loadMoreOrders();

    _isLoadingInitial = false;
    notifyListeners();
  }

  Future<void> loadMoreOrders() async {
    if (_isLoadingMore || !_hasMoreOrders || _isLoadingInitial) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado.');
      }

      Query query = _ordersRef.orderByChild('sellerId').equalTo(userId);
      if (_lastOrderKey != null) {
        query = _ordersRef.orderByChild('sellerId').equalTo(userId).startAfter({
          'sellerId': userId,
          'key': _lastOrderKey,
        });
      }
      query = query.limitToFirst(10); // Límite por página

      _ordersSubscription = query.onValue.listen((event) async {
        if (!hasListeners) return;

        final snapshot = event.snapshot;
        if (snapshot.value == null) {
          _hasMoreOrders = false;
          _isLoadingMore = false;
          notifyListeners();
          return;
        }

        final Map<dynamic, dynamic> ordersMap = snapshot.value as Map<dynamic, dynamic>;
        List<Order> fetchedOrders = [];
        ordersMap.forEach((key, value) {
          fetchedOrders.add(Order.fromMap(Map<String, dynamic>.from(value), key));
        });

        if (fetchedOrders.isEmpty) {
          _hasMoreOrders = false;
        } else {
          // Filtra los duplicados si se usó startAfter({value, key})
          final newOrders = fetchedOrders.where((order) => !_orders.any((existingOrder) => existingOrder.id == order.id)).toList();
          _orders.addAll(newOrders);
          _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Reordenar por fecha
          _lastOrderKey = newOrders.last.id;
          await _fetchBuyerNames(newOrders); // Obtener nombres de compradores
        }

        _isLoadingMore = false;
        notifyListeners();
      }, onError: (e) {
        if (!hasListeners) return;
        _errorMessage = 'Error al cargar órdenes: $e';
        _isLoadingMore = false;
        notifyListeners();
      });
    } catch (e) {
      if (!hasListeners) return;
      _errorMessage = 'Error al cargar órdenes: $e';
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchBuyerNames(List<Order> orders) async {
    final Set<String> buyerIds = orders.map((order) => order.buyerId).toSet();
    for (final id in buyerIds) {
      if (!_buyerNames.containsKey(id)) {
        final buyer = await _userService.getUserById(id);
        if (buyer != null) {
          _buyerNames[id] = buyer.fullName;
        }
      }
    }
    // No es necesario notificar aquí
  }

  Future<void> refreshOrders() => init();

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
