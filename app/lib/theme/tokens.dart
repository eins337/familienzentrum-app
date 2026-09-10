import 'package:flutter/widgets.dart';

/// Nocturne design tokens — ported 1:1 from the Claude Design handoff's
/// styles.css so the app matches the prototype pixel-for-pixel. Keep these
/// in sync with `project/_ds/nocturne-*/styles.css` if the design changes.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF161826);
  static const surface = Color(0xFF232532);
  static const text = Color(0xFFE9E9ED);
  static const accent = Color(0xFF9184D9);
  static const accent2 = Color(0xFFA7A1DB);
  static const divider = Color(0x29E9E9ED); // #e9e9ed at 16% alpha

  static const neutral100 = Color(0xFFF3F5FE);
  static const neutral200 = Color(0xFFE4E7F5);
  static const neutral300 = Color(0xFFCFD3E5);
  static const neutral400 = Color(0xFFB2B6CA);
  static const neutral500 = Color(0xFF9397AB);
  static const neutral600 = Color(0xFF75798C);
  static const neutral700 = Color(0xFF595D6C);
  static const neutral800 = Color(0xFF3F424D);
  static const neutral900 = Color(0xFF292B31);

  static const accent100 = Color(0xFFF5F4FF);
  static const accent200 = Color(0xFFE7E5FE);
  static const accent300 = Color(0xFFD2CEFD);
  static const accent400 = Color(0xFFB5ABFC);
  static const accent500 = Color(0xFF968AE0);
  static const accent600 = Color(0xFF796CBF);
  static const accent700 = Color(0xFF5D5294);
  static const accent800 = Color(0xFF423A6A);
  static const accent900 = Color(0xFF2B2741);

  /// Kindergarten group colors — Blau / Gelb / Rot.
  static const groupBlau = Color(0xFF7F93C9);
  static const groupGelb = Color(0xFFC9B47F);
  static const groupRot = Color(0xFFC98B8B);
}

class AppSpace {
  AppSpace._();

  static const s1 = 2.8;
  static const s2 = 5.6;
  static const s3 = 8.4;
  static const s4 = 11.2;
  static const s6 = 16.8;
  static const s8 = 22.4;
}

class AppRadius {
  AppRadius._();

  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 14.0;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> sm = [
    const BoxShadow(color: AppColors.neutral800, spreadRadius: 1, blurRadius: 0),
  ];
  static List<BoxShadow> md = [
    const BoxShadow(color: AppColors.neutral700, spreadRadius: 1, blurRadius: 0),
    const BoxShadow(color: Color(0x8C000000), blurRadius: 18, offset: Offset(0, 6)),
  ];
  static List<BoxShadow> lg = [
    const BoxShadow(color: AppColors.neutral500, spreadRadius: 1, blurRadius: 0),
    const BoxShadow(color: Color(0xA6000000), blurRadius: 40, offset: Offset(0, 16)),
  ];
}
