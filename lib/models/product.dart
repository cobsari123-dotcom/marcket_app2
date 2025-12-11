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
    };
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
