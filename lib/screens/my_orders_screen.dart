import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService.instance.myOrdersStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('حصل خطأ في تحميل الطلبات'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snap.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('لسه معملتش أي طلبات'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              return Card(
                child: ExpansionTile(
                  title: Text('طلب #${o.id.substring(0, 8)}'),
                  subtitle: Text(
                      '${o.totalPrice.toStringAsFixed(0)} ج.م  •  ${o.createdAt != null ? '${o.createdAt!.day}/${o.createdAt!.month}/${o.createdAt!.year}' : ''}'),
                  trailing: Chip(
                    label: Text(o.statusText,
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: _color(o.status),
                  ),
                  children: [
                    ...o.items.map((it) => ListTile(
                      dense: true,
                      title: Text(it.name),
                      subtitle: Text(
                          '${it.quantity} × ${it.price.toStringAsFixed(0)} ج.م'),
                      trailing:
                      Text('${it.subtotal.toStringAsFixed(0)} ج.م'),
                    )),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on),
                      title: Text(o.shippingAddress),
                      subtitle: Text(o.phone),
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
}