import 'package:flutter/material.dart';
import 'tokens.dart';

/// Builds the app's single (dark-only) theme — the design has no light
/// variant, matching the prototype which is Nocturne-dark throughout.
ThemeData buildAppTheme() {
  const headingStyle = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, height: 1.12);

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      onSurface: AppColors.text,
      error: AppColors.groupRot,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text, fontFamily: 'Inter')
        .copyWith(
          headlineMedium: headingStyle.copyWith(fontSize: 32, color: AppColors.text),
          headlineSmall: headingStyle.copyWith(fontSize: 25, color: AppColors.text),
          titleLarge: headingStyle.copyWith(fontSize: 20, color: AppColors.text),
          titleMedium: headingStyle.copyWith(fontSize: 17, color: AppColors.text),
          titleSmall: headingStyle.copyWith(fontSize: 15, color: AppColors.text, fontWeight: FontWeight.w500),
          bodyMedium: const TextStyle(fontFamily: 'Inter', fontSize: 15, height: 1.55, color: AppColors.text),
          bodySmall: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.text),
          labelSmall: const TextStyle(fontFamily: 'Inter', fontSize: 11, letterSpacing: 0.02, color: AppColors.neutral500),
        ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: AppColors.text.withValues(alpha: 0.07),
    dividerColor: AppColors.divider,
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accent.withValues(alpha: 0.3),
      selectionHandleColor: AppColors.accent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
