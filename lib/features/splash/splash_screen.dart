import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    final loggedIn = await ref.read(authProvider.future);
    if (!mounted) return;
    if (!loggedIn) {
      context.go('/login');
      return;
    }
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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💌', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text('دعواتي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
