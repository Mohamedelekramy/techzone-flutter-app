import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';
import '../models/product.dart';

class OrderException implements Exception {
  final String message;
  OrderException(this.message);
}

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// بيعمل الأوردر: بيتحقق من المخزون والأسعار من Firestore، يحفظ الأوردر، ويفضّي السلة
  Future<String> placeOrder({
    required String address,
    required String phone,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final cartSnap =
    await _db.collection('users').doc(uid).collection('cart').get();
    if (cartSnap.docs.isEmpty) throw OrderException('السلة فاضية');

    final items = <OrderItem>[];
    for (final doc in cartSnap.docs) {
      final pDoc = await _db.collection('products').doc(doc.id).get();
      if (!pDoc.exists) {
        throw OrderException('فيه منتج في السلة اتحذف، شيله وحاول تاني');
      }
      final p = Product.fromDoc(pDoc);
      final qty = (doc.data()['quantity'] ?? 1) as int;
      if (!p.canBuy) throw OrderException('"${p.name}" غير متاح حاليا');
      if (qty > p.stock) {
        throw OrderException('"${p.name}" المتاح منه ${p.stock} بس');
      }
      items.add(OrderItem(
        productId: p.id,
        name: p.name,
        price: p.price,
        quantity: qty,
      ));
    }

    final total = items.fold<double>(0, (s, i) => s + i.subtotal);
    final orderRef = _db.collection('orders').doc();
    final batch = _db.batch();
    batch.set(orderRef, {
      'userId': uid,
      'items': items.map((i) => i.toMap()).toList(),
      'totalPrice': total,
      'shippingAddress': address.trim(),
      'phone': phone.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    for (final d in cartSnap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    return orderRef.id;
  }

  /// أوردرات العميل (مرتبة من الأحدث، الترتيب هنا في التطبيق عشان منحتاجش Index)
  Stream<List<OrderModel>> myOrdersStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(OrderModel.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  // ===== للأدمن =====

  /// كل الأوردرات (الأحدث أولا)
  Stream<List<OrderModel>> allOrdersStream() {
    return _db.collection('orders').snapshots().map((snap) {
      final list = snap.docs.map(OrderModel.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  Stream<OrderModel?> orderStream(String id) {
    return _db
        .collection('orders')
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? OrderModel.fromDoc(d) : null);
  }

  /// الحالات المسموح الانتقال ليها من كل حالة
  static const Map<String, List<String>> allowedNext = {
    'pending': ['confirmed', 'cancelled'],
    'confirmed': ['preparing', 'cancelled'],
    'preparing': ['shipped', 'cancelled'],
    'shipped': ['delivered'],
    'delivered': [],
    'cancelled': [],
  };

  /// تغيير حالة الأوردر (بـ transaction).
  /// - عند التأكيد: بيخصم المخزون
  /// - عند الإلغاء بعد التأكيد: بيرجّع المخزون
  Future<void> updateStatus(String orderId, String newStatus) async {
    final orderRef = _db.collection('orders').doc(orderId);

    await _db.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw OrderException('الأوردر مش موجود');
      final order = OrderModel.fromDoc(orderSnap);

      final allowed = allowedNext[order.status] ?? [];
      if (!allowed.contains(newStatus)) {
        throw OrderException('مينفعش تنقل الأوردر للحالة دي');
      }

      final wasStockDeducted = order.status != 'pending';

      // لازم كل القراءات قبل أي كتابة
      final productRefs = order.items
          .map((i) => _db.collection('products').doc(i.productId))
          .toList();
      final productSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final r in productRefs) {
        productSnaps.add(await tx.get(r));
      }

      // تأكيد: خصم المخزون
      if (newStatus == 'confirmed') {
        for (var i = 0; i < order.items.length; i++) {
          final snap = productSnaps[i];
          final item = order.items[i];
          if (!snap.exists) {
            throw OrderException('المنتج "${item.name}" اتحذف');
          }
          final stock = (snap.data()!['stock'] ?? 0) as int;
          if (stock < item.quantity) {
            throw OrderException(
                'المخزون مش كفاية لـ "${item.name}" (المتاح $stock)');
          }
          tx.update(productRefs[i], {'stock': stock - item.quantity});
        }
      }

      // إلغاء بعد التأكيد: رجوع المخزون
      if (newStatus == 'cancelled' && wasStockDeducted) {
        for (var i = 0; i < order.items.length; i++) {
          final snap = productSnaps[i];
          if (!snap.exists) continue;
          final stock = (snap.data()!['stock'] ?? 0) as int;
          tx.update(
              productRefs[i], {'stock': stock + order.items[i].quantity});
        }
      }

      tx.update(orderRef, {'status': newStatus});
    });
  }
}