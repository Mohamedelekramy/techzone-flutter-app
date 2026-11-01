import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'admin_order_details_screen.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  Color _color(String s) {
    switch (s) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService.instance.allOrdersStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('حصل خطأ في تحميل الأوردرات'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data!;
        if (orders.isEmpty) {
          return const Center(child: Text('مفيش أوردرات لسه'));
        }
        return ListView.separated(
          itemCount: orders.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final o = orders[i];
            return ListTile(
              title: Text('طلب #${o.id.substring(0, 8)}'),
              subtitle: Text(
                  '${o.phone}  •  ${o.totalPrice.toStringAsFixed(0)} ج.م'),
              trailing: Chip(
                label: Text(o.statusText,
                    style: const TextStyle(color: Colors.white)),
                backgroundColor: _color(o.status),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminOrderDetailsScreen(orderId: o.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}