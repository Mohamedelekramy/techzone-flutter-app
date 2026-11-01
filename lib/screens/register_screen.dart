import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
        address: _address.text,
      );
      // AuthGate هيفتح الصفحة الرئيسية لوحده، فنقفل صفحة التسجيل
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.instance.errorMessage(e))),
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
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: _dec('الاسم', Icons.person),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'اكتب اسمك' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('الإيميل', Icons.email),
                validator: (v) =>
                (v == null || !v.contains('@')) ? 'اكتب إيميل صحيح' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: _dec('الباسورد', Icons.lock),
                validator: (v) =>
                (v == null || v.length < 6) ? '6 حروف على الأقل' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _dec('رقم الموبايل', Icons.phone),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'اكتب رقم صحيح'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: _dec('عنوان التوصيل', Icons.location_on),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'اكتب العنوان' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('إنشاء الحساب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}