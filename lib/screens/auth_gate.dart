import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'admin_dashboard.dart';
import 'customer_home.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    return StreamBuilder<User?>(
      stream: auth.authChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();

        return StreamBuilder<AppUser?>(
          stream: auth.userStream(user.uid),
          builder: (context, userSnap) {
            if (userSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('حصل خطأ في تحميل البيانات'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: auth.logout,
                        child: const Text('تسجيل خروج'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final appUser = userSnap.data;
            if (appUser == null) return const _Loading();
            return appUser.isAdmin
                ? AdminDashboard(user: appUser)
                : CustomerHome(user: appUser);
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}