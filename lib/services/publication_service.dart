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

  Future<Map<String, dynamic>> getPublications({
    String? startAfterKey,
    dynamic startAfterValue,
    int limit = 10,
    String sortBy = 'timestamp',
    bool descending = true,
  }) async {
    Query query = _publicationsRef.orderByChild(sortBy);

    if (startAfterValue != null && startAfterKey != null) {
      query = descending
          ? query.endBefore(startAfterValue, key: startAfterKey)
          : query.startAfter(startAfterValue, key: startAfterKey);
    }

    query = descending ? query.limitToLast(limit) : query.limitToFirst(limit);

    final event = await query.once();
    final List<Publication> publications = [];
    final Map<dynamic, dynamic>? values =
        event.snapshot.value as Map<dynamic, dynamic>?;

    String? lastKey;
    dynamic lastSortValue;

    if (values != null) {
      List<MapEntry<dynamic, dynamic>> sortedValues = values.entries.toList();

      // Firebase's limitToLast returns in ascending order, so reverse if descending is true.
      if (descending) {
        sortedValues = sortedValues.reversed.toList();
      }

      for (var entry in sortedValues) {
        try {
          final Map<String, dynamic> publicationData =
              Map<String, dynamic>.from(entry.value);
          publications.add(Publication.fromMap(publicationData, entry.key));
        } catch (e) {
          debugPrint('Error parsing publication ${entry.key}: $e');
        }
      }

      if (publications.isNotEmpty) {
        lastKey = publications.last.id;
        lastSortValue = publications.last.toMap()[sortBy];
      }
    }

    return {
      'publications': publications,
      'lastKey': lastKey,
      'lastSortValue': lastSortValue,
    };
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
          'comment_images/$publicationId/${DateTime.now().millisecondsSinceEpoch}_${currentUser.uid}.jpg';
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