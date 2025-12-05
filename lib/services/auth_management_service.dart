import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthManagementService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  
  // CORRECCIÓN AQUÍ: Usamos el constructor () en lugar de .instance
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Reautenticar al usuario
  Future<void> reauthenticateUser(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }
    AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  // Actualizar la contraseña del usuario
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }
    await user.updatePassword(newPassword);
  }

  // Actualizar el correo electrónico del usuario
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }
    await user.verifyBeforeUpdateEmail(newEmail);
  }

  // Eliminar la cuenta del usuario
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }

    // Opcional: Eliminar datos del usuario de la base de datos y almacenamiento
    // Obtener profilePicture antes de eliminar el usuario de la DB
    String? profilePictureUrl;
    final userSnapshot = await _usersRef.child(user.uid).get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.value as Map<dynamic, dynamic>;
      profilePictureUrl = userData['profilePicture'];
    }

    // Eliminar entrada del usuario de Realtime Database
    await _usersRef.child(user.uid).remove();

    // Si tiene foto de perfil y no es usuario de Google (Google maneja sus propias fotos)
    if (profilePictureUrl != null && !user.providerData.any((p) => p.providerId == 'google.com')) {
      try {
        await FirebaseStorage.instance.refFromURL(profilePictureUrl).delete();
      } catch (e) {
        // Ignorar si la imagen no se encuentra o ya fue eliminada
        debugPrint('Error al eliminar imagen de perfil del usuario ${user.uid}: $e');
      }
    }

    // Cerrar sesión de Google si aplica
    if (user.providerData.any((p) => p.providerId == 'google.com')) {
      await _googleSignIn.signOut();
    }
    
    // Eliminar la cuenta de Firebase Authentication
    await user.delete();
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // También cierra la sesión de Google
    await _auth.signOut();
  }
}