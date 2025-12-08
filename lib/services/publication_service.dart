import 'dart:async';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/models/comment.dart';

class PublicationService {
  final DatabaseReference _publicationsRef =
      FirebaseDatabase.instance.ref('publications');
  final DatabaseReference _commentsRef =
      FirebaseDatabase.instance.ref('comments');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Publication>> getPublicationsStream({
    int pageSize = 5,
    String? startAfterKey,
    Comparable? startAfterValue,
    String? category,
    String sortBy = 'timestamp',
    bool descending = true,
  }) {
    Query query = _publicationsRef.orderByChild(sortBy);

    if (category != null && category.isNotEmpty) {
      query = query.orderByChild('category').equalTo(category);
    }

    if (startAfterValue != null) {
      query = query.startAfter([startAfterValue, startAfterKey]);
    }

    query = query.limitToFirst(pageSize);

    return query.onValue.map((event) {
      final List<Publication> publications = [];
      final Map<dynamic, dynamic>? values =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        values.forEach((key, value) {
          try {
            final Map<String, dynamic> publicationData =
                Map<String, dynamic>.from(value);
            publications.add(Publication.fromMap(publicationData, key));
          } catch (e) {
            debugPrint('Error parsing publication $key: $e');
          }
        });
      }

      if (descending) {
        publications.sort((a, b) {
          final aValue = _getPublicationSortValue(a, sortBy);
          final bValue = _getPublicationSortValue(b, sortBy);
          if (aValue is DateTime && bValue is DateTime) {
            return bValue.compareTo(aValue);
          }
          if (aValue is String && bValue is String) {
            return bValue.compareTo(aValue);
          }
          if (aValue is num && bValue is num) {
            return bValue.compareTo(aValue);
          }
          return 0;
        });
      }

      return publications;
    });
  }

  Comparable _getPublicationSortValue(Publication p, String sortBy) {
    switch (sortBy) {
      case 'timestamp':
        return p.timestamp;
      case 'title':
        return p.title;
      default:
        return p.timestamp;
    }
  }

  Future<void> toggleLike(String publicationId) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }

    final DatabaseReference publicationLikesRef =
        _publicationsRef.child(publicationId).child('likes');

    try {
      final TransactionResult result = await publicationLikesRef.runTransaction(
        (Object? currentData) {
          // Copiamos los datos actuales o creamos un mapa vacío
          Map<String, dynamic> likes = {};
          if (currentData != null && currentData is Map) {
            likes = Map<String, dynamic>.from(currentData);
          }

          // Lógica de toggle
          if (likes.containsKey(userId)) {
            likes.remove(userId);
          } else {
            likes[userId] = true;
          }

          // Retornamos el éxito con los nuevos datos
          return Transaction.success(likes);
        },
      );

      if (result.committed) {
        debugPrint('Like toggled successfully for publication $publicationId');
      } else {
        debugPrint('Transaction not committed.');
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Stream<List<Comment>> getCommentsStream(String publicationId) {
    return _commentsRef
        .child(publicationId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final List<Comment> comments = [];
      final Map<dynamic, dynamic>? values =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        values.forEach((key, value) {
          try {
            final Map<String, dynamic> commentData =
                Map<String, dynamic>.from(value);
            comments.add(Comment.fromMap(commentData, key));
          } catch (e) {
            debugPrint('Error parsing comment $key: $e');
          }
        });
      }
      return comments;
    });
  }

  Future<void> addComment({
    required String publicationId,
    required String commentText,
    File? imageFile,
  }) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in.');
    }

    String? imageUrl;
    if (imageFile != null) {
      final String imageFileName =
          'comment_images/${publicationId}/${DateTime.now().millisecondsSinceEpoch}_${currentUser.uid}.jpg';
      final UploadTask uploadTask =
          _storage.ref().child(imageFileName).putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    final String commentId = _commentsRef.child(publicationId).push().key!;
    final Comment newComment = Comment(
      id: commentId,
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'Anonymous',
      userImageUrl: currentUser.photoURL ?? 'https://via.placeholder.com/150',
      comment: commentText,
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    await _commentsRef
        .child(publicationId)
        .child(commentId)
        .set(newComment.toMap());
  }
}