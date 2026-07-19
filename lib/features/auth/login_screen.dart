import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  bool _submitting = false;

  Future<void> _continue() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    await ref.read(authProvider.notifier).signIn(_nameController.text.trim());
    if (!mounted) return;
    final settings = await ref.read(settingsProvider.future);
    if (!mounted) return;
    if (!settings.onboardingSeen) {
      context.go('/onboarding');
    } else if (settings.lockEnabled && settings.pinHash != null) {
      context.go('/lock');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('💌', style: TextStyle(fontSize: 60), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text('مرحباً بك في دعواتي', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('أدخل اسمك للمتابعة', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _continue,
                child: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('متابعة'),
              ),
              const SizedBox(height: 12),
              Text(
                'ملاحظة: هذا تسجيل دخول محلي مبسّط لأغراض العرض. اربطه لاحقًا بخدمة مصادقة فعلية (Firebase/Supabase) دون تغيير بقية الشاشات.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
