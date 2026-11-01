import 'product.dart';

/// عنصر في السلة: المنتج + الكمية
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;
}