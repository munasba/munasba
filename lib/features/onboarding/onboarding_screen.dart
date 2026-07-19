import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';

/// Data for a single onboarding slide: icon + gradient theme + copy.
class _OnbPage {
  final IconData icon;
  final String title;
  final String desc;
  final List<Color> gradient;
  const _OnbPage({required this.icon, required this.title, required this.desc, required this.gradient});
}

const _purple = [Color(0xFF9B6BF3), Color(0xFF6C4CDB)];
const _indigo = [Color(0xFF7B8CF0), Color(0xFF4C5FDB)];
const _teal = [Color(0xFF3FE0C0), Color(0xFF1FA893)];
const _blue = [Color(0xFF4FB2F0), Color(0xFF2A7ED8)];
const _magenta = [Color(0xFFE05FD0), Color(0xFFB23AA8)];
const _pink = [Color(0xFFE84FA0), Color(0xFFC22E86)];

const _pages = [
  _OnbPage(
    icon: Icons.calendar_month_rounded,
    title: 'إدارة مناسباتك',
    desc: 'أنشئ مناسباتك وادِر من تحب في مكان واحد',
    gradient: _purple,
  ),
  _OnbPage(
    icon: Icons.groups_rounded,
    title: 'نظم جهاتك',
    desc: 'احفظ الأسماء والأرقام وسهّل التواصل معهم',
    gradient: _indigo,
  ),
  _OnbPage(
    icon: Icons.phonelink_ring_rounded,
    title: 'تواصل بسهولة',
    desc: 'اتصل أو أرسل رسائل بضغطة واحدة',
    gradient: _teal,
  ),
  _OnbPage(
    icon: Icons.pie_chart_rounded,
    title: 'تقارير ذكية',
    desc: 'احصل على إحصائيات دقيقة لمناسباتك',
    gradient: _magenta,
  ),
  _OnbPage(
    icon: Icons.shield_rounded,
    title: 'خصوصيتك محمية',
    desc: 'بياناتك آمنة ومشفّرة بالكامل',
    gradient: _blue,
  ),
  _OnbPage(
    icon: Icons.celebration_rounded,
    title: 'ابدأ الآن',
    desc: 'كل ما تحتاجه لإدارة مناسباتك في مكان واحد',
    gradient: _pink,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final _nameController = TextEditingController();
  int _index = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the name field if one was already captured previously.
    Future.microtask(() async {
      final name = await ref.read(authRepoProvider).displayName();
      if (mounted && name != null && name.isNotEmpty) {
        setState(() => _nameController.text = name);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;
  bool get _canFinish => _nameController.text.trim().isNotEmpty;

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _finishing = true);
    await ref.read(authProvider.notifier).signIn(name);
    await ref.read(settingsProvider.notifier).setOnboardingSeen(true);
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _skip() async {
    // Skipping still needs a name to personalize the home screen; fall back
    // to a generic one if the person hasn't typed anything yet.
    final existing = await ref.read(authRepoProvider).displayName();
    if (existing == null || existing.isEmpty) {
      await ref.read(authProvider.notifier).signIn('صديقنا');
    }
    await ref.read(settingsProvider.notifier).setOnboardingSeen(true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF150F2B),
              Color.lerp(const Color(0xFF1B1438), page.gradient[1], 0.28)!,
              const Color(0xFF120C26),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Soft ambient glow that shifts color with the current page.
            Positioned(
              top: -80,
              right: -60,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: page.gradient[0].withOpacity(0.25),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: TextButton(
                          onPressed: _isLast ? null : _skip,
                          child: const Text('تخطي', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => _OnboardingPage(
                        page: _pages[i],
                        isLast: i == _pages.length - 1,
                        nameController: _nameController,
                        onNameChanged: () => setState(() {}),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _GlassPanel(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_pages.length, (i) {
                              final active = i == _index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: active ? 26 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: active ? LinearGradient(colors: page.gradient) : null,
                                  color: active ? null : Colors.white24,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                              ),
                              onPressed: (_isLast && !_canFinish) || _finishing
                                  ? null
                                  : () {
                                      if (_isLast) {
                                        _finish();
                                      } else {
                                        _controller.nextPage(
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeOutCubic,
                                        );
                                      }
                                    },
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: (_isLast && !_canFinish)
                                        ? [Colors.white24, Colors.white24]
                                        : page.gradient,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: _finishing
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : Text(
                                          _isLast ? 'ابدأ الاستخدام' : 'التالي',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single onboarding slide, with a staggered entrance animation (icon pop
/// + fade-up text) that replays each time the PageView builds it.
class _OnboardingPage extends StatelessWidget {
  final _OnbPage page;
  final bool isLast;
  final TextEditingController nameController;
  final VoidCallback onNameChanged;

  const _OnboardingPage({
    required this.page,
    required this.isLast,
    required this.nameController,
    required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [page.gradient[0].withOpacity(0.35), page.gradient[1].withOpacity(0.08)],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
            ),
            child: Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: page.gradient),
                boxShadow: [BoxShadow(color: page.gradient[1].withOpacity(0.45), blurRadius: 22, spreadRadius: 2)],
              ),
              child: Icon(page.icon, color: Colors.white, size: 38),
            ),
          )
              .animate()
              .scale(duration: 480.ms, curve: Curves.elasticOut, begin: const Offset(0.4, 0.4), end: const Offset(1, 1))
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 30),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Colors.white),
          ).animate().fadeIn(delay: 120.ms, duration: 350.ms).slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 10),
          Text(
            page.desc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, height: 1.7, color: Colors.white.withOpacity(0.78)),
          ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
          if (isLast) ...[
            const SizedBox(height: 26),
            _GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                controller: nameController,
                textAlign: TextAlign.center,
                onChanged: (_) => onNameChanged(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'ما اسمك؟',
                  hintStyle: TextStyle(color: Colors.white38, fontWeight: FontWeight.w600),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.white70),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ).animate().fadeIn(delay: 280.ms, duration: 350.ms).slideY(begin: 0.25, end: 0),
          ],
        ],
      ),
    );
  }
}

/// Frosted glass panel used for onboarding chrome (name field, dots + button).
class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassPanel({required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: child,
        ),
      ),
    );
  }
}
