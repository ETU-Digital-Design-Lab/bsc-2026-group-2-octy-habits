import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const darkTop = Color(0xFF101827);
  static const darkBottom = Color(0xFF070A12);
  static const lightTop = Color(0xFFF8FAFF);
  static const lightBottom = Color(0xFFEFF6F3);

  static LinearGradient pageGradient(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [darkTop, darkBottom]
          : const [lightTop, lightBottom],
    );
  }

  static Color glassFill(BuildContext context, {double dark = 0.07}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: dark)
        : Colors.white.withValues(alpha: 0.78);
  }

  static Color glassBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFCFD8E3);
  }

  static Color mutedText(BuildContext context, [double alpha = 0.66]) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha);
  }

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    background: darkBottom,
    surface: const Color(0xFF111722),
    surfaceHigh: const Color(0xFF192131),
    primary: const Color(0xFF54B6F7),
    secondary: const Color(0xFF38D6B6),
    onSurface: const Color(0xFFF4F7FB),
    nav: const Color(0xFF16151D),
    navIndicator: const Color(0xFF2B5467),
  );

  static ThemeData light() => _build(
    brightness: Brightness.light,
    background: lightBottom,
    surface: Colors.white,
    surfaceHigh: const Color(0xFFFFFFFF),
    primary: const Color(0xFF176B87),
    secondary: const Color(0xFF0E9F7A),
    onSurface: const Color(0xFF17202A),
    nav: const Color(0xFFFDFDFE),
    navIndicator: const Color(0xFFD8EEE9),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceHigh,
    required Color primary,
    required Color secondary,
    required Color onSurface,
    required Color nav,
    required Color navIndicator,
  }) {
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final textTheme = GoogleFonts.manropeTextTheme(
      base.textTheme,
    ).apply(bodyColor: onSurface, displayColor: onSurface);
    final isDark = brightness == Brightness.dark;

    return base.copyWith(
      textTheme: textTheme,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: isDark ? const Color(0xFF07130F) : Colors.white,
        error: const Color(0xFFE84B5F),
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surfaceHigh,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: nav,
        indicatorColor: navIndicator,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? onSurface
                : onSurface.withValues(alpha: 0.64),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? onSurface
                : onSurface.withValues(alpha: 0.62),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(52, 48),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(52, 48),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.82),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.66),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.42),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFD4DCE6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFD4DCE6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceHigh,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.72),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1D2635)
            : const Color(0xFF17202A),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
