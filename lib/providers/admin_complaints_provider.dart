import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class AdminComplaintsProvider with ChangeNotifier {
  final DatabaseReference _complaintsRef = FirebaseDatabase.instance.ref('complaints_suggestions');

  List<Map<dynamic, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _complaintsSubscription;

  List<Map<dynamic, dynamic>> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AdminComplaintsProvider() {
    init();
  }

  void init() {
    _listenToComplaints();
  }

  void _listenToComplaints() {
    _complaintsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _complaintsSubscription = _complaintsRef.onValue.listen((event) {
      if (!hasListeners) return;

      final snapshot = event.snapshot;
      if (snapshot.value == null) {
        _complaints = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final Map<dynamic, dynamic> complaintsMap = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<dynamic, dynamic>> fetchedComplaints = [];
      complaintsMap.forEach((key, value) {
        final complaint = Map<dynamic, dynamic>.from(value);
        complaint['id'] = key;
        fetchedComplaints.add(complaint);
      });

      fetchedComplaints.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

      _complaints = fetchedComplaints;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      if (!hasListeners) return;
      _errorMessage = 'Error al cargar quejas/sugerencias: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> replyToComplaint(String complaintId, String replyText) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _complaintsRef.child(complaintId).update({
        'reply': replyText,
        'status': 'responded',
      });
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al enviar respuesta: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    super.dispose();
  }
}
