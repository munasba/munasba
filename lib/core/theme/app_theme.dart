import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color premiumGold = Color(0xFFC5A880);
  static const Color blushPink = Color(0xFFE5BAA9);
  static const Color creamyWhite = Color(0xFFFFFDF9);
  static const Color charcoalText = Color(0xFF2D2D2D);
  static const Color mutedGray = Color(0xFF757575);
  static const Color borderLight = Color(0xFFE8E0D5);
  static const Color surfaceLight = Color(0xFFFDF6F0);

  // Status Colors
  static const Color statusConfirmed = Color(0xFF4CAF50);
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusDeclined = Color(0xFFE57373);

  // Service Backgrounds
  static const Color serviceHalls = Color(0xFFFDF6F0);
  static const Color serviceCatering = Color(0xFFFDF0F0);
  static const Color servicePhoto = Color(0xFFF0F8FF);
  static const Color serviceInvites = Color(0xFFF5F0FF);

  // Event Gradients
  static const List<Color> eventGradients = [
    Color(0xFFE5BAA9),
    Color(0xFFC5A880),
    Color(0xFFD4B896),
    Color(0xFFE8D5C4),
    Color(0xFFF0E6D8),
    Color(0xFFDDC9B4),
  ];

  // Inspiration Gradients
  static const List<List<Color>> inspirationGradients = [
    [Color(0xFFFFE4E1), Color(0xFFFFD5CD)],
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.creamyWhite,
      colorScheme: const ColorScheme.light(
        primary: AppColors.premiumGold,
        secondary: AppColors.blushPink,
        surface: Colors.white,
        background: AppColors.creamyWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.charcoalText,
        onBackground: AppColors.charcoalText,
        error: AppColors.statusDeclined,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.creamyWhite,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.charcoalText),
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.charcoalText,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.premiumGold, width: 2),
        ),
        hintStyle: const TextStyle(
          color: AppColors.mutedGray,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.premiumGold,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.premiumGold,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.premiumGold.withOpacity(0.15),
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.premiumGold,
        unselectedItemColor: AppColors.mutedGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

