class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final List<String> imageUrls;
  final String category;
  final bool isFeatured;
  final String sellerId;
  final double averageRating; // New field
  final int reviewCount; // New field
  final String? freshness; // New field
  final DateTime? freshnessDate; // New field
  final double? weightValue; // New field
  final String? weightUnit; // New field
  final String productType; // New field
  final DateTime? timestamp; // New field

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrls,
    required this.category,
    required this.isFeatured,
    required this.sellerId,
    required this.averageRating,
    required this.reviewCount,
    this.freshness, // Add to constructor
    this.freshnessDate, // Add to constructor
    this.weightValue, // Add to constructor
    this.weightUnit, // Add to constructor
    this.productType = 'Artesanía', // Default value
    this.timestamp, // Add to constructor
  });

  factory Product.fromMap(Map<String, dynamic> map, String id,
      {String? sellerIdParam}) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: _parseToDouble(map['price']),
      stock: _parseToInt(map['stock']),
      imageUrls: _parseImageUrls(map),
      category: map['category'] ?? '',
      isFeatured: map['isFeatured'] ?? false,
      sellerId: sellerIdParam ?? map['sellerId'] ?? '',
      averageRating:
          _parseToDouble(map['averageRating']), // Added to fromMap
      reviewCount:
          _parseToInt(map['reviewCount']), // Added to fromMap
      freshness: map['freshness'], // Add to fromMap
      freshnessDate: map['freshnessDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['freshnessDate'] as num).toInt())
          : null,
      weightValue: map['weightValue'] is num ? map['weightValue'].toDouble() : null, // Add to fromMap
      weightUnit: map['weightUnit'], // Add to fromMap
      productType: map['productType'] ?? 'Artesanía', // Add to fromMap
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['timestamp'] as num).toInt())
          : null, // Add to fromMap
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrls': imageUrls,
      'category': category,
      'isFeatured': isFeatured,
      'sellerId': sellerId,
      'averageRating': averageRating, // Added to toMap
      'reviewCount': reviewCount, // Added to toMap
      'freshness': freshness, // Add to toMap
      'freshnessDate': freshnessDate?.millisecondsSinceEpoch, // Add to toMap
      'weightValue': weightValue, // Add to toMap
      'weightUnit': weightUnit, // Add to toMap
      'productType': productType, // Add to toMap
      'timestamp': timestamp?.millisecondsSinceEpoch, // Add to toMap
    };
  }

  // Add copyWith method for consistency
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    List<String>? imageUrls,
    String? category,
    bool? isFeatured,
    String? sellerId,
    double? averageRating,
    int? reviewCount,
    String? freshness,
    DateTime? freshnessDate,
    double? weightValue,
    String? weightUnit,
    String? productType,
    DateTime? timestamp,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      isFeatured: isFeatured ?? this.isFeatured,
      sellerId: sellerId ?? this.sellerId,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      freshness: freshness ?? this.freshness,
      freshnessDate: freshnessDate ?? this.freshnessDate,
      weightValue: weightValue ?? this.weightValue,
      weightUnit: weightUnit ?? this.weightUnit,
      productType: productType ?? this.productType,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

// Helper functions for robust parsing
double _parseToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _parseToInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

List<String> _parseImageUrls(Map<String, dynamic> map) {
  final List<String> urls = [];
  if (map['imageUrls'] is List) {
    urls.addAll(List<String>.from(map['imageUrls'])
        .where((url) => url.isNotEmpty));
  } else if (map['imageUrl'] is String && (map['imageUrl'] as String).isNotEmpty) {
    urls.add(map['imageUrl'] as String);
  }
  return urls;
}