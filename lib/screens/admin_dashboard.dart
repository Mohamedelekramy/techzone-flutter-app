import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import 'admin_orders_screen.dart';
import 'product_form_screen.dart';

class AdminDashboard extends StatelessWidget {
  final AppUser user;
  const AdminDashboard({super.key, required this.user});

  Future<void> _confirmDelete(BuildContext context, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text('متأكد إنك عايز تحذف "${p.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ProductService.instance.deleteProduct(p.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل الحذف')),
          );
        }
      }
    }
  }

  Widget _productsTab(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('منتج جديد'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: ProductService.instance.productsStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('حصل خطأ في تحميل المنتجات'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snap.data!;
          if (products.isEmpty) {
            return const Center(
                child: Text('مفيش منتجات لسه، اضغط "منتج جديد"'));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = products[i];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    p.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 40),
                  ),
                ),
                title: Text(p.name),
                subtitle: Text(
                    '${p.price} ج.م  •  مخزون: ${p.stock}  •  ${p.category}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductFormScreen(product: p)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, p),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الأدمن'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: AuthService.instance.logout,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory_2), text: 'المنتجات'),
              Tab(icon: Icon(Icons.receipt_long), text: 'الأوردرات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _productsTab(context),
            const AdminOrdersScreen(),
          ],
        ),
      ),
    );
  }
}