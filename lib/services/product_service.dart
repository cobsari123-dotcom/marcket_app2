import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:marcket_app/models/product.dart';

class ProductService {
  final DatabaseReference _productsRef =
      FirebaseDatabase.instance.ref('products');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get getUserId => FirebaseAuth.instance.currentUser?.uid;

  // Obtener un stream de los productos del vendedor actual
  Stream<DatabaseEvent> getMyProductsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }
    return _productsRef.child(userId).onValue;
  }

  // Nuevo método para obtener productos paginados de un vendedor específico
  Future<List<Product>> getSellerProductsPaginated(String userId,
      {int pageSize = 10, String? startAfterKey}) async {
    Query query = _productsRef.child(userId).orderByKey();

    if (startAfterKey != null) {
      query = query.startAt(startAfterKey);
    }

    query = query.limitToFirst(pageSize);

    final snapshot = await query.get();

    if (snapshot.value == null) {
      return [];
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.entries.map((entry) {
      return Product.fromMap(
          Map<String, dynamic>.from(entry.value as Map), entry.key,
          sellerIdParam: userId);
    }).toList();
  }

  // Nuevo método para obtener productos paginados y ordenados para el feed principal
  Future<Map<String, dynamic>> getProducts({
    String? startAfterKey,
    dynamic startAfterValue,
    int limit = 10,
    String sortBy = 'timestamp',
    bool descending = true,
  }) async {
    Query query = _productsRef.orderByChild(sortBy);

    if (descending) {
      if (startAfterValue != null) {
        // For descending, we want items *before* the startAfterValue
        // combined with the last key to ensure unique pagination.
        if (startAfterKey != null) {
          query = query.endBefore(startAfterValue, key: startAfterKey);
        } else {
          query = query.endBefore(startAfterValue);
        }
      }
      query = query.limitToLast(limit);
    } else {
      if (startAfterValue != null) {
        // For ascending, we want items *after* the startAfterValue
        // combined with the last key to ensure unique pagination.
        if (startAfterKey != null) {
          query = query.startAfter(startAfterValue, key: startAfterKey);
        } else {
          query = query.startAfter(startAfterValue);
        }
      }
      query = query.limitToFirst(limit);
    }

    final snapshot = await query.get();

    if (snapshot.value == null) {
      return {'products': [], 'lastKey': null, 'lastSortValue': null};
    }

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(snapshot.value as Map);

    // Convert map to list and sort
    List<Product> products = data.entries.map((entry) {
      return Product.fromMap(
          Map<String, dynamic>.from(entry.value as Map), entry.key,
          sellerIdParam: entry.value['sellerId']);
    }).toList();

    // If fetching in descending order, Firebase's limitToLast retrieves items
    // in ascending order of the sort key, so we need to reverse them here.
    if (descending) {
      products = products.reversed.toList();
    }
    // No need for client-side sort if already ordered by child in query and reversed for descending

    String? lastKey;
    dynamic lastSortValue;
    if (products.isNotEmpty) {
      lastKey = products.last.id;
      lastSortValue = products.last.toMap()[sortBy];
    }

    return {
      'products': products,
      'lastKey': lastKey,
      'lastSortValue': lastSortValue
    };
  }

  // Obtener un producto específico por su ID
  Future<Product?> getProductById(String productId) async {
    final allSellersSnapshot = await _productsRef.get();
    if (allSellersSnapshot.exists) {
      final allSellersData =
          Map<String, dynamic>.from(allSellersSnapshot.value as Map);
      for (var sellerId in allSellersData.keys) {
        final sellerProducts =
            allSellersData[sellerId] as Map<dynamic, dynamic>;
        if (sellerProducts.containsKey(productId)) {
          final productData =
              Map<String, dynamic>.from(sellerProducts[productId] as Map);
          return Product.fromMap(productData, productId,
              sellerIdParam: sellerId);
        }
      }
    }
    return null;
  }

  // Eliminar un producto
  Future<void> deleteProduct(Product product) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    // Eliminar de la base de datos
    await _productsRef.child(userId).child(product.id).remove();

    // Eliminar imágenes del almacenamiento
    for (final imageUrl in product.imageUrls) {
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (e) {
        // Ignorar si la imagen ya fue eliminada o no existe
        debugPrint('Error al eliminar la imagen $imageUrl: $e');
      }
    }
  }

  // Guardar (crear o actualizar) un producto
  Future<void> saveProduct({
    Product? existingProduct,
    required String name,
    required String description,
    required double price,
    required int stock,
    required String category,
    required bool isFeatured,
    required List<String> existingImageUrls,
    required List<File> newImages,
    required List<String> imagesToRemove,
    List<String>? newImageUrlsFromWeb, // New parameter
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    // 1. Subir nuevas imágenes y obtener sus URLs
    List<String> uploadedImageUrls = [];
    for (final imageFile in newImages) {
      final storageRef = _storage.ref().child('product_images').child(
          '${userId}_${DateTime.now().millisecondsSinceEpoch}_${uploadedImageUrls.length}.jpg');

      final Uint8List imageData = await imageFile.readAsBytes();
      final metadata = SettableMetadata(contentType: "image/jpeg");
      await storageRef.putData(imageData, metadata);

      final url = await storageRef.getDownloadURL();
      uploadedImageUrls.add(url);
    }

    // 2. Eliminar las imágenes marcadas para borrado
    for (final urlToRemove in imagesToRemove) {
      try {
        await _storage.refFromURL(urlToRemove).delete();
      } catch (e) {
        debugPrint(
            'Error al eliminar la imagen para actualizar $urlToRemove: $e');
      }
    }

    // 3. Preparar los datos del producto
    final finalImageUrls = [
      ...existingImageUrls,
      ...uploadedImageUrls,
      ...?newImageUrlsFromWeb
    ];

    final productData = {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'imageUrls': finalImageUrls,
      'isFeatured': isFeatured,
      'sellerId': userId,
    };

    // 4. Guardar en la base de datos
    if (existingProduct != null) {
      // Actualizar producto existente
      await _productsRef
          .child(userId)
          .child(existingProduct.id)
          .update(productData);
    } else {
      // Crear nuevo producto
      productData['averageRating'] = 0.0;
      productData['reviewCount'] = 0;
      await _productsRef.child(userId).push().set(productData);
    }
  }
}
