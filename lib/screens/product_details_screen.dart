import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: ProductService.instance.productStream(productId),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('حصل خطأ في تحميل المنتج')),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final p = snap.data;
        if (p == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('المنتج ده اتحذف')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(p.name)),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('أضف للسلة'),
                onPressed: !p.canBuy
                    ? null
                    : () async {
                  try {
                    await CartService.instance.add(p);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تمت الإضافة للسلة ✓')),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text('وصلت للحد الأقصى من المخزون')),
                      );
                    }
                  }
                },
              ),
            ),
          ),
          body: ListView(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  p.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image, size: 60)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${p.price.toStringAsFixed(0)} ج.م',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(p.category)),
                        Chip(
                          label: Text(p.canBuy
                              ? 'متاح (${p.stock} قطعة)'
                              : 'غير متاح'),
                          backgroundColor: p.canBuy
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('الوصف',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(p.description, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}