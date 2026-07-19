import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class _OnbPage {
  final String emoji;
  final String title;
  final String desc;
  const _OnbPage(this.emoji, this.title, this.desc);
}

const _pages = [
  _OnbPage('💌', 'مرحباً بك في دعواتي', 'نظم جميع أفراد العائلة والأصدقاء والجيران في مكان واحد، واستعد لكل مناسبة بسهولة.'),
  _OnbPage('🗓️', 'أنشئ مناسبتك خلال ثوانٍ', 'أنشئ حفلات الزفاف، أعياد الميلاد، التخرج، العزاء أو أي مناسبة، ثم اختر المدعوين بضغطة واحدة.'),
  _OnbPage('📞', 'تابع جميع الاتصالات', 'اعرف من تم الاتصال به، ومن بقي، مع إحصائيات لحظية ونسبة الإنجاز.'),
  _OnbPage('🎊', 'جاهز للبدء', 'ابدأ بتنظيم مناسباتك بطريقة احترافية واستمتع بتجربة استخدام مميزة.'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).setOnboardingSeen(true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3F1F3B), Color(0xFF6B4162), Color(0xFF4A2E45)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: TextButton(onPressed: _finish, child: const Text('تخطي', style: TextStyle(color: Colors.white))),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _OnboardingPage(page: _pages[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? AppColors.gold : Colors.white38,
                            borderRadius: BorderRadius.circular(100),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: const Color(0xFF3A2C0F)),
                        onPressed: () {
                          if (isLast) {
                            _finish();
                          } else {
                            _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
                          }
                        },
                        child: Text(isLast ? 'ابدأ الآن' : 'التالي'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnbPage page;
  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
            ),
            child: Text(page.emoji, style: const TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 34),
          Text(page.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 12),
          Text(page.desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.5, height: 1.7, color: Colors.white.withOpacity(0.85))),
        ],
      ),
    );
  }
}
