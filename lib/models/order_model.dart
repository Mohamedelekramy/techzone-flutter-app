import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final double price; // السعر وقت الشراء
  final int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    productId: m['productId'] ?? '',
    name: m['name'] ?? '',
    price: (m['price'] ?? 0).toDouble(),
    quantity: (m['quantity'] ?? 1).toInt(),
  );
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalPrice;
  final String shippingAddress;
  final String phone;
  final String status;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.shippingAddress,
    required this.phone,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return OrderModel(
      id: doc.id,
      userId: m['userId'] ?? '',
      items: ((m['items'] ?? []) as List)
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      totalPrice: (m['totalPrice'] ?? 0).toDouble(),
      shippingAddress: m['shippingAddress'] ?? '',
      phone: m['phone'] ?? '',
      status: m['status'] ?? 'pending',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String get statusText => statusArabic(status);

  static String statusArabic(String s) {
    switch (s) {
      case 'pending':
        return 'قيد المراجعة';
      case 'confirmed':
        return 'تم التأكيد';
      case 'preparing':
        return 'جاري التجهيز';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return s;
    }
  }
}