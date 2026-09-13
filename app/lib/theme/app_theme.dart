import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

/// Builds the app's single (light) theme — Familienzentrum Lank v2 design:
/// Outfit for headings/buttons/numbers, Nunito Sans for body/meta/inputs.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      surface: AppColors.background,
      primary: AppColors.primary,
      secondary: AppColors.info,
      onSurface: AppColors.ink,
      error: AppColors.error,
    ),
  );

  final textTheme = GoogleFonts.nunitoSansTextTheme(base.textTheme).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

  return base.copyWith(
    textTheme: textTheme.copyWith(
      headlineMedium: AppText.outfit(size: 26, color: AppColors.ink, height: 1.18),
      headlineSmall: AppText.outfit(size: 21, color: AppColors.ink),
      titleLarge: AppText.outfit(size: 19, color: AppColors.ink),
      titleMedium: AppText.outfit(size: 17, color: AppColors.ink),
      titleSmall: AppText.outfit(size: 15, color: AppColors.ink),
      bodyMedium: AppText.nunito(size: 13.5, color: AppColors.ink, height: 1.55),
      bodySmall: AppText.nunito(size: 12, color: AppColors.ink2),
      labelSmall: AppText.nunito(size: 11, color: AppColors.muted),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: AppColors.ink.withValues(alpha: 0.04),
    dividerColor: AppColors.divider,
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.25),
      selectionHandleColor: AppColors.primary,
    ),
  );
}
