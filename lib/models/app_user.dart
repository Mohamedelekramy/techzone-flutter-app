class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role; // 'customer' أو 'admin'

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? 'customer',
    );
  }
}