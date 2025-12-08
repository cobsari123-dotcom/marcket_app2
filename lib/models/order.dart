import 'package:marcket_app/models/cart_item.dart';

enum OrderStatus {
  pending, // Waiting for buyer to upload receipt
  verifying, // Waiting for seller to confirm payment
  preparing, // Seller is preparing the order
  shipped, // Order has been shipped
  delivered, // Order has been delivered
  cancelled, // Order was cancelled
}

class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final List<CartItem> items;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final String? paymentReceiptUrl;
  final String? trackingNumber;
  final String? rejectionReason;
  final Map<String, String>? deliveryAddress;
  final String? phoneNumber;
  final String? email;
  final String paymentMethod;
  final DateTime? estimatedDeliveryDate;
  final String? deliveryCode; // New field
  final String? deliveryTimeWindow; // New field

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.paymentReceiptUrl,
    this.trackingNumber,
    this.rejectionReason,
    this.deliveryAddress,
    this.phoneNumber,
    this.email,
    this.paymentMethod = 'Bank Transfer',
    this.estimatedDeliveryDate,
    this.deliveryCode, // Add to constructor
    this.deliveryTimeWindow, // Add to constructor
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) =>
                  CartItem.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${map['status']}',
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num).toInt()),
      paymentReceiptUrl: map['paymentReceiptUrl'],
      trackingNumber: map['trackingNumber'],
      rejectionReason: map['rejectionReason'],
      deliveryAddress: map['deliveryAddress'] != null
          ? Map<String, String>.from(map['deliveryAddress'])
          : null,
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      paymentMethod: map['paymentMethod'] ?? 'Bank Transfer',
      estimatedDeliveryDate: (map['estimatedDeliveryDate'] as num?) != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['estimatedDeliveryDate'].toInt())
          : null,
      deliveryCode: map['deliveryCode'], // Add to fromMap
      deliveryTimeWindow: map['deliveryTimeWindow'], // Add to fromMap
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'paymentReceiptUrl': paymentReceiptUrl,
      'trackingNumber': trackingNumber,
      'rejectionReason': rejectionReason,
      'deliveryAddress': deliveryAddress,
      'phoneNumber': phoneNumber,
      'email': email,
      'paymentMethod': paymentMethod,
      'estimatedDeliveryDate': estimatedDeliveryDate?.millisecondsSinceEpoch,
      'deliveryCode': deliveryCode, // Add to toMap
      'deliveryTimeWindow': deliveryTimeWindow, // Add to toMap
    };
  }
}
