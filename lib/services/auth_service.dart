import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authChanges => _auth.authStateChanges();

  Stream<AppUser?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name.trim());
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'role': 'customer', // دايما customer، الأدمن بيتحدد من الـ Console
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String address,
  }) {
    return _db.collection('users').doc(uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
    });
  }

  String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'الإيميل ده مستخدم قبل كده';
        case 'invalid-email':
          return 'الإيميل مش صحيح';
        case 'weak-password':
          return 'الباسورد ضعيف (6 حروف على الأقل)';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'الإيميل أو الباسورد غلط';
        case 'network-request-failed':
          return 'مشكلة في الاتصال بالإنترنت';
        case 'too-many-requests':
          return 'محاولات كتير، جرب بعد شوية';
      }
      return e.message ?? 'حصل خطأ';
    }
    return 'حصل خطأ غير متوقع';
  }
}