import 'package:flutter/material.dart';

/// Central color palette shared by light & dark themes.
/// Values are picked to match the purple/indigo glassmorphism mockups.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF6C5CE7);
  static const primaryDark = Color(0xFF4B3FA8);
  static const secondary = Color(0xFF4C6FFF);
  static const gold = Color(0xFFC9A66B);

  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const pending = Color(0xFF94A3B8);

  // Dark theme surfaces (default app look — matches the mockups)
  static const darkBgTop = Color(0xFF201A3B);
  static const darkBgBottom = Color(0xFF160F2E);
  static const darkSurface = Color(0xFF241C46);
  static const darkSurfaceVariant = Color(0xFF2D2456);
  static const darkOutline = Color(0x33FFFFFF);

  // Light theme surfaces
  static const lightBg = Color(0xFFF5F3FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFEDE9FB);
  static const lightOutline = Color(0x1F1A1436);

  /// Category card gradients — cycled by index, matching the "الفئات" screen.
  static const List<List<Color>> categoryGradients = [
    [Color(0xFF7B5FE0), Color(0xFF5B3FBF)], // بنفسجي
    [Color(0xFF3F6FE0), Color(0xFF2A4FBF)], // أزرق
    [Color(0xFF3FBF7B), Color(0xFF23955A)], // أخضر
    [Color(0xFFE0973F), Color(0xFFBF7423)], // برتقالي
    [Color(0xFFD84FA0), Color(0xFFA23A78)], // فوشيا
    [Color(0xFF3FA8BF), Color(0xFF237E95)], // تركواز
    [Color(0xFF4F6FD8), Color(0xFF3A4FA2)], // نيلي
    [Color(0xFFC9A66B), Color(0xFF8A6D3B)], // ذهبي
  ];

  /// Event accent colors offered on the "لون المناسبة" picker.
  static const List<Color> eventColors = [
    primary,
    Color(0xFFE91E8C),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFF29B6D8),
    Color(0xFF7B5FA6),
  ];

  static Color rsvpColor(String status) {
    switch (status) {
      case 'invited':
        return success;
      case 'declined':
        return danger;
      case 'notContacted':
        return warning;
      case 'pending':
      default:
        return pending;
    }
  }
}
