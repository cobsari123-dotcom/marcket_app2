import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart' as app_user;

class UserService {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  // Obtener los datos de un usuario por su ID
  Future<app_user.UserModel?> getUserById(String uid) async {
    try {
      final snapshot = await _usersRef.child(uid).get();
      if (snapshot.exists) {
        return app_user.UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map), uid);
      }
      return null;
    } catch (e) {
      // Manejar el error apropiadamente en la UI
      rethrow;
    }
  }

  // Obtener un stream de los datos de un usuario por su ID
  Stream<app_user.UserModel?> getUserStream(String uid) {
    return _usersRef.child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        return app_user.UserModel.fromMap(Map<String, dynamic>.from(event.snapshot.value as Map), uid);
      }
      return null;
    });
  }

  // Crear o actualizar los datos de un usuario
  Future<void> setUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _usersRef.child(uid).set(data);
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar campos específicos de un usuario
  Future<void> updateUserData(String uid, Map<String, Object?> data) async {
    try {
      await _usersRef.child(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar un usuario
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.child(uid).remove();
    } catch (e) {
      rethrow;
    }
  }

  // Verificar si un email pertenece a un administrador
  Future<bool> isAdminEmail(String email) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('admin_emails').get();
      if (snapshot.exists && snapshot.value is Map) {
        final adminEmails = Map<String, dynamic>.from(snapshot.value as Map);
        // Firebase keys cannot contain '.', so we replace it with a placeholder
        final formattedEmail = email.replaceAll('.', ',');
        return adminEmails.containsKey(formattedEmail);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Obtener todos los usuarios
  Future<List<app_user.UserModel>> getAllUsers() async {
    try {
      final snapshot = await _usersRef.get();
      if (snapshot.exists) {
        final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
        return usersMap.entries.map((entry) {
          return app_user.UserModel.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
        }).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // --- Wishlist Methods ---

  // Obtener un stream de los IDs de productos favoritos
  Stream<List<String>> getWishlistStream(String userId) {
    return _usersRef.child(userId).child('wishlist').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final wishlistData = Map<String, dynamic>.from(event.snapshot.value as Map);
        return wishlistData.keys.toList();
      }
      return [];
    });
  }

  // Verificar si un producto es favorito
  Future<bool> isFavorite(String userId, String productId) async {
    final snapshot = await _usersRef.child(userId).child('wishlist').child(productId).get();
    return snapshot.exists;
  }

  // Añadir o quitar un producto de favoritos
  Future<void> toggleFavorite(String userId, String productId) async {
    final isCurrentlyFavorite = await isFavorite(userId, productId);
    if (isCurrentlyFavorite) {
      // Si ya es favorito, quitarlo
      await _usersRef.child(userId).child('wishlist').child(productId).remove();
    } else {
      // Si no es favorito, añadirlo
      await _usersRef.child(userId).child('wishlist').child(productId).set(true);
    }
  }
}
