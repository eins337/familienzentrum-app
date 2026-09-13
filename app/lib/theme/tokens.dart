import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Familienzentrum Lank v2 design tokens — ported 1:1 from the design
/// handoff's README (Farben, Typografie, Spacing, Radien, Schatten). Keep
/// these in sync with `design_handoff_familienzentrum_redesign/README.md`
/// if the design changes. Replaces the earlier dark "Nocturne" theme.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF3A63B8);
  static const primaryInk = Color(0xFF2E4F94);
  static const primarySoft = Color(0xFFE9EFFA);

  static const ink = Color(0xFF23262F);
  static const ink2 = Color(0xFF5C6170);
  static const muted = Color(0xFF8A8F9E);
  static const mutedAlt = Color(0xFFA9AEBC);
  static const label = Color(0xFF9A9FAE);

  static const background = Color(0xFFFAF6F0);
  static const pageBg = Color(0xFFF1EAE0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFCFAF6);
  static const soft = Color(0xFFF4EEE4);
  static const border = Color(0xFFE8DFD0);
  static const cardBorder = Color(0xFFEFE7DA);
  static const divider = Color(0xFFF2EBE0);

  static const success = Color(0xFF3F9A73);
  static const successSoft = Color(0xFFE3F1EA);
  static const successInk = Color(0xFF1F5C46);
  static const successInk2 = Color(0xFF2A6B52);

  static const warning = Color(0xFFC98A18);
  static const warningSoft = Color(0xFFFAEFD6);
  static const warningInk = Color(0xFF6B4708);
  static const warningInk2 = Color(0xFF8A6A2A);

  static const error = Color(0xFFD9694F);
  static const errorSoft = Color(0xFFFBE7E1);
  static const errorBorder = Color(0xFFF0C8BB);
  static const errorInk = Color(0xFF8E3A26);
  static const errorInk2 = Color(0xFF7A3E2D);

  static const info = Color(0xFF7D6CD0);
  static const infoSoft = Color(0xFFEDEAFB);
  static const infoInk = Color(0xFF5B4CB0);

  /// Kindergarten group colors — Blau / Gelb / Rot.
  static const groupBlau = Color(0xFF5B8ED6);
  static const groupBlauSoft = Color(0xFFE7EFFB);
  static const groupGelb = Color(0xFFE0A32E);
  static const groupGelbSoft = Color(0xFFFAEFD6);
  static const groupRot = Color(0xFFD9694F);
  static const groupRotSoft = Color(0xFFFBE7E1);

  static const avatarNeutralBg = Color(0xFFF1E9DD);
  static const avatarNeutralText = Color(0xFF6B6255);

  // Illustration palette.
  static const illuSkin = Color(0xFFF3D2B3);
  static const illuSkinShade = Color(0xFFE8BE9A);
  static const illuHair = Color(0xFF3F3730);
  static const illuHairAlt = Color(0xFF5C4433);
  static const illuGras = Color(0xFFCFE3D3);
  static const illuGrasShade = Color(0xFFBBD8C2);
  static const illuSonne = Color(0xFFF2C75C);
  static const illuHolz = Color(0xFF8A6A55);
  static const illuDach = Color(0xFFD9694F);
}

/// Outfit (headings/buttons/tab labels/numbers) + Nunito Sans (body/meta/
/// inputs), per the README type scale. Sizes are set per call site; these
/// helpers just pin family + weight + the shared letter-spacing rule.
class AppText {
  AppText._();

  static TextStyle outfit({required double size, FontWeight weight = FontWeight.w600, Color? color, double? height}) {
    return GoogleFonts.outfit(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: -0.01 * size);
  }

  static TextStyle nunito({required double size, FontWeight weight = FontWeight.w400, Color? color, double? height}) {
    return GoogleFonts.nunitoSans(fontSize: size, fontWeight: weight, color: color, height: height);
  }

  /// 10px/800 uppercase, letter-spacing .13em — SectionLabel / Badge base.
  static TextStyle sectionLabel({Color color = AppColors.label, double size = 10}) {
    return GoogleFonts.outfit(fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: size * 0.13);
  }
}

class AppSpace {
  AppSpace._();

  static const base = 4.0;
  static const screenH = 16.0;
  static const screenTop = 14.0;
  static const screenBottom = 26.0;
  static const cardPadding = 14.0;
  static const cardGap = 12.0;
  static const cardInnerGap = 10.0;
  static const buttonRowGap = 7.5;
}

class AppRadius {
  AppRadius._();

  static const card = 20.0;
  static const sheetTop = 26.0;
  static const buttonLg = 15.5;
  static const buttonSm = 13.5;
  static const input = 14.0;
  static const iconBackplate = 11.0;
  static const avatar = 14.0;
  static const pill = 999.0;
  static const chatBubble = 18.0;
  static const chatBubbleTail = 6.0;

  // Legacy aliases kept during the v2 migration so not-yet-restyled
  // widgets still compile; remove once every screen is converted.
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
}

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(color: Color(0x0A23262F), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const cardElevated = [
    BoxShadow(color: Color(0x0A23262F), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x7423262F), blurRadius: 26, offset: Offset(0, 14), spreadRadius: -20),
  ];
  static const primaryButton = [
    BoxShadow(color: Color(0xF23A63B8), blurRadius: 20, offset: Offset(0, 12), spreadRadius: -12),
  ];
  static const toast = [
    BoxShadow(color: Color(0xCC23262F), blurRadius: 34, offset: Offset(0, 18), spreadRadius: -16),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x8023262F), blurRadius: 50, offset: Offset(0, -20), spreadRadius: -20),
  ];

  // Legacy aliases during migration.
  static List<BoxShadow> sm = card;
  static List<BoxShadow> md = cardElevated;
  static List<BoxShadow> lg = cardElevated;
}

class AppMotion {
  AppMotion._();

  static const press = Duration(milliseconds: 120);
  static const popIn = Duration(milliseconds: 260);
  static const sheetUp = Duration(milliseconds: 240);
  static const toastIn = Duration(milliseconds: 220);
  static const toastDismiss = Duration(milliseconds: 2800);
  static const tabPill = Duration(milliseconds: 200);

  static const pressScale = 0.96;
  static const cardPressScale = 0.985;
}
