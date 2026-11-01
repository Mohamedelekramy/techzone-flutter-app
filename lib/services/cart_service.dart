import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _cart {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('cart');
  }

  /// السلة لحظيا: بنقرا الكميات من السلة، وبيانات المنتج (السعر والاسم) من products
  Stream<List<CartItem>> cartStream() {
    return _cart.snapshots().asyncMap((snap) async {
      final items = <CartItem>[];
      for (final doc in snap.docs) {
        final productDoc = await _db.collection('products').doc(doc.id).get();
        if (!productDoc.exists) continue; // المنتج اتحذف
        items.add(CartItem(
          product: Product.fromDoc(productDoc),
          quantity: (doc.data()['quantity'] ?? 1) as int,
        ));
      }
      return items;
    });
  }

  /// عدد القطع في السلة (للبادج على الأيقونة)
  Stream<int> countStream() {
    return _cart.snapshots().map((snap) => snap.docs.fold<int>(
        0, (sum, d) => sum + ((d.data()['quantity'] ?? 0) as int)));
  }

  /// إضافة للسلة (لو موجود بيزود الكمية بشرط ميعديش المخزون)
  Future<void> add(Product p) async {
    final ref = _cart.doc(p.id);
    final doc = await ref.get();
    final current = doc.exists ? (doc.data()!['quantity'] ?? 0) as int : 0;
    if (current + 1 > p.stock) {
      throw Exception('stock-limit');
    }
    await ref.set({'productId': p.id, 'quantity': current + 1});
  }

  Future<void> setQuantity(Product p, int quantity) async {
    if (quantity <= 0) return remove(p.id);
    if (quantity > p.stock) throw Exception('stock-limit');
    await _cart.doc(p.id).update({'quantity': quantity});
  }

  Future<void> remove(String productId) => _cart.doc(productId).delete();

  Future<void> clear() async {
    final snap = await _cart.get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}