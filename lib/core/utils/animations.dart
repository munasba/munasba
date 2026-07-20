import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Collection of reusable animation presets for the app
class AppAnimations {
  AppAnimations._();

  // ─── Fade In Up ───
  static Widget fadeInUp({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 400),
    double begin = 0.08,
  }) {
    return child
        .animate()
        .fadeIn(delay: delay, duration: duration)
        .slideY(begin: begin, end: 0, curve: Curves.easeOutCubic);
  }

  // ─── Fade In Left (RTL) ───
  static Widget fadeInLeft({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return child
        .animate()
        .fadeIn(delay: delay, duration: duration)
        .slideX(begin: -0.06, end: 0, curve: Curves.easeOutCubic);
  }

  // ─── Scale In ───
  static Widget scaleIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return child
        .animate()
        .fadeIn(delay: delay, duration: duration)
        .scaleXY(begin: 0.92, end: 1, curve: Curves.easeOutBack);
  }

  // ─── Staggered List ───
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration baseDelay = Duration.zero,
    Duration itemDelay = const Duration(milliseconds: 50),
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      return child
          .animate()
          .fadeIn(delay: baseDelay + (itemDelay * index), duration: duration)
          .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
    }).toList();
  }

  // ─── Hero Card Animation ───
  static Widget heroCard({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return child
        .animate()
        .fadeIn(delay: delay, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic)
        .scaleXY(begin: 0.95, end: 1, curve: Curves.easeOutCubic);
  }

  // ─── Counter Animation ───
  static Widget animatedCounter({
    required int value,
    required TextStyle style,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) => Text('$val', style: style),
    );
  }

  // ─── Progress Ring Animation ───
  static Widget animatedProgress({
    required double value,
    required Color color,
    required Widget center,
    Duration duration = const Duration(milliseconds: 900),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) => Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: val,
            strokeWidth: 5,
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          center,
        ],
      ),
    );
  }

  // ─── Shimmer Loading ───
  static Widget shimmerLoading({required Widget child}) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.2));
  }

  // ─── Pulse Animation ───
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 2000),
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .scaleXY(begin: 1, end: 1.05, duration: duration.ms)
        .then()
        .scaleXY(begin: 1.05, end: 1, duration: duration.ms);
  }

  // ─── Floating Animation ───
  static Widget floating({
    required Widget child,
    Duration duration = const Duration(milliseconds: 3000),
    double offset = 8,
  }) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .slideY(begin: 0, end: -offset, duration: (duration.inMilliseconds ~/ 2).ms)
        .then()
        .slideY(begin: -offset, end: 0, duration: (duration.inMilliseconds ~/ 2).ms);
  }

  // ─── Page Transition ───
  static PageRouteBuilder pageTransition({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      transitionDuration: duration,
    );
  }
}

