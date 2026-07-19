import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../providers/providers.dart';

String _hashPin(String pin) => sha256.convert(utf8.encode('dawakti::$pin')).toString();

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _entered = '';
  String? _error;
  bool _biometricTried = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricIfEnabled());
  }

  Future<void> _tryBiometricIfEnabled() async {
    if (_biometricTried) return;
    _biometricTried = true;
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null || !settings.biometricEnabled) return;

    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canCheck) return;
      final ok = await auth.authenticate(
        localizedReason: 'الرجاء تأكيد هويتك لفتح التطبيق',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok && mounted) context.go('/home');
    } catch (_) {
      // Falls back silently to PIN entry — local_auth can throw on
      // simulators/devices with no enrolled biometrics.
    }
  }

  void _onDigit(String d) {
    if (_entered.length >= 6) return;
    setState(() {
      _entered += d;
      _error = null;
    });
    if (_entered.length >= 4) _checkPin();
  }

  void _checkPin() {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings?.pinHash == null) return;
    if (_hashPin(_entered) == settings!.pinHash) {
      context.go('/home');
    } else if (_entered.length >= 6) {
      setState(() {
        _error = 'رمز غير صحيح، حاول مرة أخرى';
        _entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              const Text('أدخل رمز PIN لفتح دعواتي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _entered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 28),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                    _digitButton(d),
                  if (settings?.biometricEnabled == true)
                    _iconButton(Icons.fingerprint, _tryBiometricIfEnabledForce)
                  else
                    const SizedBox.shrink(),
                  _digitButton('0'),
                  _iconButton(Icons.backspace_outlined, () {
                    if (_entered.isNotEmpty) setState(() => _entered = _entered.substring(0, _entered.length - 1));
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _tryBiometricIfEnabledForce() async {
    _biometricTried = false;
    await _tryBiometricIfEnabled();
  }

  Widget _digitButton(String d) => InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => _onDigit(d),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardTheme.color),
          child: Text(d, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _iconButton(IconData icon, VoidCallback onTap) => InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardTheme.color),
          child: Icon(icon),
        ),
      );
}
