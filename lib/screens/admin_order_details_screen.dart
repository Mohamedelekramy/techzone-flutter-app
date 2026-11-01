import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class AdminOrderDetailsScreen extends StatelessWidget {
  final String orderId;
  const AdminOrderDetailsScreen({super.key, required this.orderId});

  Future<void> _change(
      BuildContext context, OrderModel o, String newStatus) async {
    try {
      await OrderService.instance.updateStatus(o.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم التغيير إلى: ${OrderModel.statusArabic(newStatus)}')));
      }
    } on OrderException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      debugPrint('STATUS ERROR: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('فشل تغيير الحالة')));
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context, OrderModel o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إلغاء الأوردر'),
        content: const Text('متأكد إنك عايز تلغي الأوردر ده؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لا')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نعم، إلغاء')),
        ],
      ),
    );
    if (ok == true && context.mounted) _change(context, o, 'cancelled');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderModel?>(
      stream: OrderService.instance.orderStream(orderId),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('حصل خطأ في تحميل الأوردر')));
        }
        if (!snap.hasData) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()));
        }
        final o = snap.data!;
        final next = OrderService.allowedNext[o.status] ?? [];
        final forward = next.where((s) => s != 'cancelled').toList();
        final canCancel = next.contains('cancelled');

        return Scaffold(
          appBar: AppBar(title: Text('طلب #${o.id.substring(0, 8)}')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text('الحالة الحالية'),
                  trailing: Chip(label: Text(o.statusText)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('المنتجات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...o.items.map((it) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(it.name),
                subtitle: Text(
                    '${it.quantity} × ${it.price.toStringAsFixed(0)} ج.م'),
                trailing: Text('${it.subtotal.toStringAsFixed(0)} ج.م'),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${o.totalPrice.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('بيانات التوصيل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on),
                title: Text(o.shippingAddress),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone),
                title: Text(o.phone),
              ),
              const SizedBox(height: 16),
              ...forward.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () => _change(context, o, s),
                    child: Text('تغيير إلى: ${OrderModel.statusArabic(s)}'),
                  ),
                ),
              )),
              if (canCancel)
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                    onPressed: () => _confirmCancel(context, o),
                    child: const Text('إلغاء الأوردر'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}