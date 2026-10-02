import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colours beyond the Material scheme: one pair per day state.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.got,
    required this.gotSoft,
    required this.skipped,
    required this.skippedSoft,
    required this.missing,
    required this.missingSoft,
    required this.muted,
    required this.border,
    required this.card,
  });

  final Color got;
  final Color gotSoft;
  final Color skipped;
  final Color skippedSoft;
  final Color missing;
  final Color missingSoft;
  final Color muted;
  final Color border;
  final Color card;

  static const light = AppColors(
    got: Color(0xFF2F7D5B),
    gotSoft: Color(0xFFE2F1E9),
    skipped: Color(0xFF857A6C),
    skippedSoft: Color(0xFFEEE8DF),
    missing: Color(0xFFC98A1B),
    missingSoft: Color(0xFFFBEFD5),
    muted: Color(0xFF6E665B),
    border: Color(0xFFE7DFD2),
    card: Color(0xFFFFFFFF),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

const _ink = Color(0xFF1C2B3F);
const _primary = Color(0xFF1E3A5F);
const _background = Color(0xFFF7F3EC);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: _primary, surface: _background)
      .copyWith(
        primary: _primary,
        onPrimary: Colors.white,
        onSurface: _ink,
        primaryContainer: const Color(0xFFDCE6F2),
        onPrimaryContainer: _primary,
      );

  const text = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.1,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.15,
    ),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
    titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _background,
    fontFamily: 'Nunito',
    fontFamilyFallback: const ['NunitoExt'],
    textTheme: text.apply(bodyColor: _ink, displayColor: _ink),
    extensions: const [AppColors.light],
    splashFactory: InkSparkle.splashFactory,
    // Dark status-bar icons on the light background, on every screen.
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      titleTextStyle: text.titleLarge?.copyWith(color: _ink),
      systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        shape: shape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        shape: shape,
        foregroundColor: _ink,
        side: BorderSide(color: AppColors.light.border, width: 1.5),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: text.labelMedium?.copyWith(fontSize: 16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: AppColors.light.card,
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 14,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? _primary
              : AppColors.light.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 28,
          color: states.contains(WidgetState.selected)
              ? _primary
              : AppColors.light.muted,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      prefixIconConstraints: const BoxConstraints(),
      suffixIconConstraints: const BoxConstraints(),
      fillColor: AppColors.light.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: text.bodyLarge?.copyWith(color: const Color(0xFFADA393)),
      prefixStyle: text.bodyLarge?.copyWith(
        color: _ink,
        fontWeight: FontWeight.w700,
      ),
      suffixStyle: text.bodyMedium?.copyWith(color: AppColors.light.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.light.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.light.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _background,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.light.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
