import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/services/user_service.dart'; // Para actualizar el token FCM del usuario

class NotificationService with ChangeNotifier {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  NotificationService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _initializeFCM();
      } else {
        _fcmToken = null;
        notifyListeners();
      }
    });
  }

  Future<void> _initializeFCM() async {
    // Solicitar permisos de notificación
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permisos de usuario concedidos');
      // Obtener el token de FCM
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      // Guardar el token en la base de datos para el usuario actual
      if (_fcmToken != null && _auth.currentUser != null) {
        await _userService
            .updateUserData(_auth.currentUser!.uid, {'fcmToken': _fcmToken});
      }
      notifyListeners();

      // Manejar mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            'Mensaje en primer plano recibido: ${message.notification?.title}');
        // Mostrar notificación o actualizar UI
        // Ejemplo: ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(...)
      });

      // Manejar interacción con notificaciones cuando la app está en segundo plano o terminada
      // Estas se manejan fuera del UI context, en _firebaseMessagingBackgroundHandler
    } else {
      debugPrint('Permisos denegados o no concedidos');
    }
  }

  // Actualizar el token si cambia
  void onTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      debugPrint('Nuevo FCM Token: $newToken');
      if (_auth.currentUser != null) {
        await _userService
            .updateUserData(_auth.currentUser!.uid, {'fcmToken': newToken});
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    // No es necesario cancelar suscripciones de FirebaseMessaging aquí, ya se gestionan automáticamente
    super.dispose();
  }
}
