import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final AppUser user;
  const CheckoutScreen({super.key, required this.user});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.user.phone);
    _address = TextEditingController(text: widget.user.address);
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final id = await OrderService.instance
          .placeOrder(address: _address.text, phone: _phone.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: id)),
      );
    } on OrderException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل إرسال الطلب، حاول تاني')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الطلب')),
      body: StreamBuilder<List<CartItem>>(
        stream: CartService.instance.cartStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          final total = items.fold<double>(0, (s, i) => s + i.subtotal);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('المنتجات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((i) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(i.product.name),
                subtitle: Text(
                    '${i.quantity} × ${i.product.price.toStringAsFixed(0)} ج.م'),
                trailing: Text('${i.subtotal.toStringAsFixed(0)} ج.م'),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${total.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('بيانات التوصيل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الموبايل',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().length < 10)
                          ? 'اكتب رقم صحيح'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _address,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'عنوان التوصيل',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'اكتب العنوان'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.payments),
                  title: Text('الدفع عند الاستلام'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: (_loading || items.isEmpty) ? null : _placeOrder,
                  child: _loading
                      ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('تأكيد الطلب'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}