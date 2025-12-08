import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:marcket_app/models/comment.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/services/user_service.dart';

class PublicationService {
  final DatabaseReference _publicationsRef = FirebaseDatabase.instance.ref('publications');
  final DatabaseReference _commentsRef = FirebaseDatabase.instance.ref('comments');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final UserService _userService = UserService();

  // Obtener un stream de publicaciones con paginación, filtro y ordenamiento
  Stream<List<Publication>> getPublicationsStream({
    int pageSize = 10,
    String? startAfterKey, // La última clave de la publicación para la paginación
    String? startAfterValue, // El valor de ordenamiento de la última publicación
    String? category,
    String sortBy = 'timestamp', // Campo por el que ordenar
    bool descending = true, // true para más nuevas primero
  }) {
    Query query = _publicationsRef;

    // Ordenamiento
    query = query.orderByChild(sortBy);

    // Paginación
    if (startAfterKey != null && startAfterValue != null) {
      query = query.startAfter([startAfterValue, startAfterKey]);
    }

    // Limitar el número de resultados
    query = query.limitToFirst(pageSize);

    return query.onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.value == null) {
        return [];
      }
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      List<Publication> publications = [];
      data.forEach((key, value) {
        publications.add(Publication.fromMap(Map<String, dynamic>.from(value), key));
      });

      // Ordenar si es necesario
      publications.sort((a, b) {
        final aValue = _getPublicationSortValue(a, sortBy);
        final bValue = _getPublicationSortValue(b, sortBy);
        return descending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
      });

      return publications;
    });
  }

  // Helper para obtener el valor de ordenamiento
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

  // Dar o quitar 'like' a una publicación
  Future<void> toggleLike(String publicationId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return; // No se puede dar like si no está logueado
    }

    final DatabaseReference likesRef = _publicationsRef.child(publicationId).child('likes');

    await likesRef.runTransaction((Object? data) {
      Map<String, dynamic> likes = data == null ? {} : Map<String, dynamic>.from(data as Map);
      
      if (likes.containsKey(userId)) {
        // El usuario ya dio like, se quita
        likes.remove(userId);
      } else {
        // El usuario no ha dado like, se añade
        likes[userId] = true;
      }

      return Transaction.success(likes);
    });
  }

  // Obtener stream de comentarios para una publicación
  Stream<List<Comment>> getCommentsStream(String publicationId) {
    return _commentsRef.child(publicationId).onValue.map((event) {
      if (!event.snapshot.exists) {
        return [];
      }
      final commentsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      final comments = commentsMap.entries.map((entry) {
        return Comment.fromMap(Map<String, dynamic>.from(entry.value), entry.key);
      }).toList();
      comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return comments;
    });
  }

  // Añadir un comentario a una publicación
  Future<void> addComment({
    required String publicationId,
    required String commentText,
    File? imageFile,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }

    final user = await _userService.getUserById(currentUser.uid);
    if (user == null) {
      throw Exception('Datos de usuario no encontrados.');
    }

    String? imageUrl;
    if (imageFile != null) {
      final storageRef = _storage
          .ref()
          .child('comment_images')
          .child('${publicationId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await storageRef.putFile(imageFile);
      imageUrl = await storageRef.getDownloadURL();
    }

    final newCommentRef = _commentsRef.child(publicationId).push();
    final newComment = Comment(
      id: newCommentRef.key!,
      userId: currentUser.uid,
      userName: user.fullName,
      userImageUrl: user.profilePicture ?? '',
      comment: commentText,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
    );

    await newCommentRef.set(newComment.toMap());
  }
}
