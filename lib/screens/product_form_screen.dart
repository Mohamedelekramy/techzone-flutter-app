import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = إضافة، غير كده = تعديل
  const ProductFormScreen({super.key, this.product});
  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _imageUrl;
  late final TextEditingController _stock;
  late String _category;
  late bool _isAvailable;
  bool _loading = false;

  static const categories = ['موبايلات', 'سماعات', 'لابتوب', 'إكسسوارات'];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p != null ? p.price.toString() : '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _stock = TextEditingController(text: p != null ? p.stock.toString() : '');
    _category = (p != null && categories.contains(p.category))
        ? p.category
        : categories.first;
    _isAvailable = p?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _imageUrl.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final product = Product(
        id: widget.product?.id ?? '',
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: double.parse(_price.text.trim()),
        imageUrl: _imageUrl.text.trim(),
        category: _category,
        stock: int.parse(_stock.text.trim()),
        isAvailable: _isAvailable,
      );
      if (_isEdit) {
        await ProductService.instance.updateProduct(product);
      } else {
        await ProductService.instance.addProduct(product);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الحفظ، حاول تاني')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: const OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل منتج' : 'إضافة منتج')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: _dec('اسم المنتج', Icons.inventory_2),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'اكتب الاسم' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: _dec('الوصف', Icons.description),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'اكتب الوصف' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec('السعر', Icons.attach_money),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  return (n == null || n <= 0) ? 'اكتب سعر صحيح' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: _dec('الكمية في المخزون', Icons.numbers),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  return (n == null || n < 0) ? 'اكتب كمية صحيحة' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrl,
                keyboardType: TextInputType.url,
                decoration: _dec('رابط الصورة (URL)', Icons.image),
                validator: (v) => (v == null || !v.trim().startsWith('http'))
                    ? 'اكتب رابط صورة يبدأ بـ http'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _dec('التصنيف', Icons.category),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('متاح للبيع'),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'حفظ التعديلات' : 'إضافة المنتج'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}