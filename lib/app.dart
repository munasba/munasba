import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/providers.dart';

class DawaktiApp extends ConsumerWidget {
  const DawaktiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final accent = Color(settings?.accentColorValue ?? 0xFF6C5CE7);
    final isDark = (settings?.themeMode ?? 'dark') == 'dark';
    final locale = Locale(settings?.language ?? 'ar');

    return MaterialApp.router(
      title: 'دعواتي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('ku')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // اللغتان العربية والكردية (السورانية) تُعرضان من اليمين لليسار.
        final isRtl = locale.languageCode == 'ar' || locale.languageCode == 'ku';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
