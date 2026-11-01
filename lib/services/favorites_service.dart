import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('favorites');
  }

  /// قايمة ids المنتجات المفضلة (لحظيا)
  Stream<Set<String>> favoriteIdsStream() {
    return _col
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Future<void> add(String productId) {
    return _col.doc(productId).set({
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String productId) => _col.doc(productId).delete();

  Future<void> toggle(String productId, bool isFavorite) {
    return isFavorite ? remove(productId) : add(productId);
  }
}