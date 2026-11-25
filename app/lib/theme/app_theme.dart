import 'package:flutter/material.dart';

/// هوية Blue VIP البصرية — باليتة مستخرجة من تحليل تطبيق IPTV احترافي
/// (خلفية 0B0C10 → سطح 13151F → بطاقة 181B26 → حدود 262A36) مع
/// أكسنت أزرق لتمييز العلامة + أحمر "مباشر" + أخضر نجاح.
class BvColors {
  BvColors._();

  /// الخلفية الرئيسية الفائقة الداكنة
  static const Color bg = Color(0xFF0B0C10);

  /// سطح البطاقات الكبيرة والشاشات الثانوية
  static const Color surface = Color(0xFF13151F);

  /// بطاقات القنوات والأفلام
  static const Color card = Color(0xFF181B26);

  /// الحدود الرقيقة
  static const Color border = Color(0xFF262A36);

  /// الأكسنت الأزرق (زر رئيسي + تابات نشطة)
  static const Color blue = Color(0xFF3B82F6);

  /// أزرق فاتح للروابط والتمييز
  static const Color blueLight = Color(0xFF60A5FA);

  /// أزرق عميق للتدرجات
  static const Color blueDark = Color(0xFF2563EB);

  /// أحمر شارة "مباشر الآن"
  static const Color red = Color(0xFFDC2626);

  /// أحمر داكن للتدرجات
  static const Color redDark = Color(0xFF991B1B);

  /// أخضر النجاح/الحالة النشطة
  static const Color green = Color(0xFF10B981);

  /// النص الأساسي
  static const Color text = Color(0xFFF8FAFC);

  /// النص الثانوي
  static const Color muted = Color(0xFF94A3B8);
}

/// ثيم التطبيق الكامل.
ThemeData buildBvTheme() {
  final ThemeData base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: BvColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: BvColors.blue,
      secondary: BvColors.blueLight,
      surface: BvColors.surface,
      error: BvColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BvColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: BvColors.text,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: BvColors.text),
    ),
    cardTheme: CardTheme(
      color: BvColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: BvColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BvColors.card,
      hintStyle: const TextStyle(color: BvColors.muted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: BvColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: BvColors.blue, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: BvColors.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BvColors.card,
      contentTextStyle: const TextStyle(color: BvColors.text, fontSize: 14),
      actionTextColor: BvColors.blueLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: BvColors.text,
      displayColor: BvColors.text,
    ),
  );
}
