import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;
  const ProfileScreen({super.key, required this.user});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone);
    _address = TextEditingController(text: widget.user.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.updateProfile(
        uid: widget.user.uid,
        name: _name.text,
        phone: _phone.text,
        address: _address.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حفظ البيانات ✓')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('فشل الحفظ، حاول تاني')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(widget.user.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'الاسم', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'رقم الموبايل', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'العنوان', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('حفظ'),
            ),
          ),
        ],
      ),
    );
  }
}