import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../providers/providers.dart';

String _hashPin(String pin) => sha256.convert(utf8.encode('dawakti::$pin')).toString();

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('الأمان')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('قفل التطبيق برقم PIN'),
            subtitle: Text(settings.lockEnabled ? 'مفعّل' : 'غير مفعّل'),
            value: settings.lockEnabled,
            onChanged: (v) async {
              if (v) {
                final pin = await _promptForPin(context);
                if (pin != null && pin.length >= 4) {
                  await ref.read(settingsProvider.notifier).setLock(enabled: true, pinHash: _hashPin(pin));
                }
              } else {
                await ref.read(settingsProvider.notifier).setLock(enabled: false);
                await ref.read(settingsProvider.notifier).setBiometric(false);
              }
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('فتح ببصمة الإصبع / فيس آيدي'),
            subtitle: Text(settings.lockEnabled ? 'كطبقة إضافية أسرع من رمز PIN' : 'فعّل قفل PIN أولًا'),
            value: settings.biometricEnabled,
            onChanged: !settings.lockEnabled
                ? null
                : (v) async {
                    if (v) {
                      final auth = LocalAuthentication();
                      final supported = await auth.isDeviceSupported();
                      if (!supported) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الجهاز لا يدعم البصمة/فيس آيدي، أو لم تُفعَّل من إعدادات النظام')),
                          );
                        }
                        return;
                      }
                    }
                    await ref.read(settingsProvider.notifier).setBiometric(v);
                  },
          ),
          const SizedBox(height: 8),
          Text(
            'عند تفعيل القفل، ستظهر شاشة PIN عند فتح التطبيق. إن فعّلت البصمة أيضًا، سيحاول التطبيق مصادقتك بالبصمة أولًا ثم يعرض لوحة PIN كخيار احتياطي.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptForPin(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنشاء رقم PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(hintText: '4 أرقام على الأقل'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('حفظ')),
        ],
      ),
    );
  }
}
