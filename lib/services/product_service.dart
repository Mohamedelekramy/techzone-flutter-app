import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  final CollectionReference<Map<String, dynamic>> _col =
  FirebaseFirestore.instance.collection('products');

  /// كل المنتجات (بتتحدث لحظيا)
  Stream<List<Product>> productsStream() {
    return _col.snapshots().map(
          (snap) => snap.docs.map(Product.fromDoc).toList(),
    );
  }

  Stream<Product?> productStream(String id) {
    return _col.doc(id).snapshots().map(
          (doc) => doc.exists ? Product.fromDoc(doc) : null,
    );
  }

  // ===== للأدمن =====

  Future<void> addProduct(Product p) => _col.add(p.toMap());

  Future<void> updateProduct(Product p) => _col.doc(p.id).update(p.toMap());

  Future<void> deleteProduct(String id) => _col.doc(id).delete();
}