import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
// SOLUCIÓN: Agregamos 'as google' para diferenciar la librería de cualquier archivo local
import 'package:google_sign_in/google_sign_in.dart' as google;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Usamos el alias 'google.' para asegurar que usamos la librería oficial
  final google.GoogleSignIn _googleSignIn = google.GoogleSignIn(
    clientId: '766952734433-a2i9su93l8j9j1h2k8n5db0hgr1cbi7h.apps.googleusercontent.com',
  );

  // Stream para escuchar los cambios de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Iniciar sesión con email y contraseña
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Iniciar sesión con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Iniciar el flujo interactivo usando el alias
      final google.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In cancelado por el usuario.');
        return null;
      }

      // 2. Obtener la autenticación (con el await que corregimos antes)
      final google.GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Crear credencial
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase
      return await _auth.signInWithCredential(credential);

    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Error en Google Sign In: $e');
      return null;
    }
  }

  // Registrarse con email y contraseña
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  // Enviar correo de recuperación
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }
}