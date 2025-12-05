import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/order.dart';
import 'dart:async';

class OrderListProvider with ChangeNotifier {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref('orders');

  List<Order> _orders = [];
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _lastOrderKey; // Key for pagination
  bool _hasMoreOrders = true;
  StreamSubscription? _ordersSubscription;

  List<Order> get orders => _orders;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMoreOrders => _hasMoreOrders;

  OrderListProvider() {
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

      Query query = _ordersRef.orderByChild('buyerId').equalTo(userId).limitToFirst(10);
      if (_lastOrderKey != null) {
        query = _ordersRef.orderByChild('buyerId').equalTo(userId).startAfter({
          'buyerId': userId, // Este es el valor de referencia para equalTo
          'key': _lastOrderKey, // Usar la clave de la última orden como ancla para la paginación
        }).limitToFirst(10);
      }

      _ordersSubscription = query.onValue.listen((event) {
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

  // Método para refrescar la lista (igual que init)
  Future<void> refreshOrders() => init();

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
