import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../models/app_user.dart';
import 'checkout_screen.dart';


class CartScreen extends StatelessWidget {
  final AppUser user;
  const CartScreen({super.key, required this.user});

  void _msg(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _changeQty(BuildContext context, CartItem item, int qty) async {
    try {
      await CartService.instance.setQuantity(item.product, qty);
    } catch (_) {
      if (context.mounted) _msg(context, 'الكمية المطلوبة أكتر من المخزون');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('السلة')),
      body: StreamBuilder<List<CartItem>>(
        stream: CartService.instance.cartStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('حصل خطأ في تحميل السلة'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('السلة فاضية'));
          }
          final total = items.fold<double>(0, (s, i) => s + i.subtotal);
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final p = item.product;
                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text('${p.price.toStringAsFixed(0)} ج.م'),
                              Text(
                                'الإجمالي: ${item.subtotal.toStringAsFixed(0)} ج.م',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary),
                              ),
                              if (!p.canBuy)
                                const Text('المنتج غير متاح حاليا',
                                    style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _changeQty(
                                      context, item, item.quantity - 1),
                                ),
                                Text('${item.quantity}',
                                    style: const TextStyle(fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _changeQty(
                                      context, item, item.quantity + 1),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () =>
                                  CartService.instance.remove(p.id),
                              child: const Text('حذف',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الإجمالي: ${total.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CheckoutScreen(user: user)),
                        ),
                        child: const Text('إتمام الطلب'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}