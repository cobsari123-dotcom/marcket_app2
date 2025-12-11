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
    String? productCategory, // New parameter for category filter
    dynamic startAfterValue, // Value of sortBy for pagination
    int limit = 10,
    String sortBy = 'timestamp',
    bool descending = true,
  }) async {
    List<Product> allProducts = [];

    // Fetch all sellers' products
    final allSellersSnapshot = await _productsRef.get();

    if (allSellersSnapshot.exists && allSellersSnapshot.value != null) {
      Map<dynamic, dynamic> sellersData = allSellersSnapshot.value as Map<dynamic, dynamic>;

      // Iterate through each seller's products
      sellersData.forEach((sellerId, productsData) {
        if (productsData is Map) {
          productsData.forEach((productId, productMap) {
            try {
              allProducts.add(Product.fromMap(Map<String, dynamic>.from(productMap), productId, sellerIdParam: sellerId));
            } catch (e) {
              debugPrint('Error parsing product $productId for seller $sellerId: $e');
            }
          });
        }
      });
    }

    // Apply filtering (if any)
    if (productCategory != null && productCategory != 'Todas') {
      allProducts = allProducts
          .where((product) => product.category == productCategory)
          .toList();
    }

    // Apply sorting
    allProducts.sort((a, b) {
      dynamic aValue;
      dynamic bValue;

      // Extract values based on sortBy field
      if (sortBy == 'timestamp') {
        aValue = a.timestamp?.millisecondsSinceEpoch; // Use null-aware operator
        bValue = b.timestamp?.millisecondsSinceEpoch; // Use null-aware operator
      } else if (sortBy == 'price') {
        aValue = a.price;
        bValue = b.price;
      } else if (sortBy == 'name') {
        aValue = a.name;
        bValue = b.name;
      } else {
        // Default to timestamp if sortBy is unknown or title
        aValue = a.timestamp?.millisecondsSinceEpoch; // Use null-aware operator
        bValue = b.timestamp?.millisecondsSinceEpoch; // Use null-aware operator
      }

      // Handle comparison based on type and descending flag
      if (aValue is num && bValue is num) {
        return descending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
      } else if (aValue is String && bValue is String) {
        return descending ? bValue.compareTo(aValue) : aValue.compareTo(bValue);
      }
      return 0; // Fallback if types are incomparable
    });

    // Apply pagination (client-side for now)
    List<Product> paginatedProducts = [];
    int startIndex = 0;
    if (startAfterKey != null && startAfterValue != null) {
      // Find the index of the last product from the previous page
      int lastIndex = allProducts.indexWhere((p) {
        dynamic pValue;
        if (sortBy == 'timestamp') {
          pValue = p.timestamp?.millisecondsSinceEpoch; // Use null-aware operator
        } else if (sortBy == 'price') {
          pValue = p.price;
        } else if (sortBy == 'name') {
          pValue = p.name;
        } else {
          pValue = p.timestamp?.millisecondsSinceEpoch; // Default, use null-aware operator
        }

        return p.id == startAfterKey && pValue == startAfterValue;
      });
      if (lastIndex != -1) {
        startIndex = lastIndex + 1;
      }
    }

    // Ensure startIndex is within bounds
    if (startIndex < allProducts.length) {
      paginatedProducts = allProducts.sublist(startIndex).take(limit).toList();
    }

    String? newLastKey;
    dynamic newLastSortValue;
    if (paginatedProducts.isNotEmpty) {
      newLastKey = paginatedProducts.last.id;
      if (sortBy == 'timestamp') {
        newLastSortValue = paginatedProducts.last.timestamp?.millisecondsSinceEpoch;
      } else if (sortBy == 'price') {
        newLastSortValue = paginatedProducts.last.price;
      } else if (sortBy == 'name') {
        newLastSortValue = paginatedProducts.last.name;
      } else {
        newLastSortValue = paginatedProducts.last.timestamp?.millisecondsSinceEpoch; // Default
      }
    }

    return {
      'products': paginatedProducts,
      'lastKey': newLastKey,
      'lastSortValue': newLastSortValue,
      'hasMore': paginatedProducts.length == limit && (startIndex + limit) < allProducts.length,
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
    required String productType, // New required parameter
    String? freshness, // New optional parameter
    DateTime? freshnessDate, // New optional parameter
    double? weightValue, // New optional parameter
    String? weightUnit, // New optional parameter
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

    final productData = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'imageUrls': finalImageUrls,
      'isFeatured': isFeatured,
      'sellerId': userId,
      'productType': productType, // New field
      'timestamp': DateTime.now().millisecondsSinceEpoch, // Added timestamp
    };

    // Add optional fields only if they have values
    if (freshness != null && freshness.isNotEmpty) {
      productData['freshness'] = freshness;
    }
    if (freshnessDate != null) {
      productData['freshnessDate'] = freshnessDate.millisecondsSinceEpoch;
    }
    if (weightValue != null) {
      productData['weightValue'] = weightValue;
    }
    if (weightUnit != null && weightUnit.isNotEmpty) {
      productData['weightUnit'] = weightUnit;
    }

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
