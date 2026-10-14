// 📁 FILE: lib/theme/app_theme.dart
// 📌 WHAT: "Clean Arena" design tokens (colors, text, spacing, radius, shadow) and a calm minimalist background
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All colors used across the app, in one place. Change a value here
/// and it updates everywhere.
///
/// Design rule: neutrals for surfaces and text, the two team colors only
/// for the teams, gold only for the main action and the trophy.
class AppColors {
  AppColors._();

  // ---------- Neutrals ----------
  static const background = Color(0xFFF5F7FB);
  static const backgroundDeep = Color(0xFFE9EEF6);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const ink = Color(0xFF1B2433);
  static const inkMuted = Color(0xFF5B6678);
  static const inkFaint = Color(0xFF94A3B8);

  /// Cards (start screen, result card). Plain white now.
  static const paper = Color(0xFFFFFFFF);

  // ---------- Teams ----------
  static const team1 = Color(0xFF2563EB);
  static const team1Light = Color(0xFFE8F0FE);
  static const team1Dark = Color(0xFF1D4ED8);

  static const team2 = Color(0xFFDC2626);
  static const team2Light = Color(0xFFFDECEC);
  static const team2Dark = Color(0xFFB91C1C);

  // ---------- Accent ----------
  static const gold = Color(0xFFF5B301);
  static const goldDark = Color(0xFFB98600);

  /// Dark brown text on gold (readable).
  static const onGold = Color(0xFF4A3200);

  // ---------- Feedback ----------
  static const success = Color(0xFF22A559);
  static const danger = Color(0xFFD92D20);
  static const fire = Color(0xFFF97316);

  // ---------- Arena scenery (used by the rope arena only) ----------
  static const skyTop = Color(0xFF8ECBFF);
  static const skyBottom = Color(0xFFDFF1FF);
  static const grass1 = Color(0xFF6FBE44);
  static const grass2 = Color(0xFF5AA838);

  static const rope = Color(0xFFC69A5A);
  static const ropeDark = Color(0xFF7A5B32);
}

/// Spacing scale. Use these instead of loose numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Corner radius scale.
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

/// One soft shadow for every card, so the app feels consistent.
class AppShadows {
  AppShadows._();

  static final List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF1B2433).withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Reusable text styles. "Fredoka" (rounded, friendly) for headings and
/// "Nunito" (clear and readable) for numbers and body text.
///
/// Only the font weights that are bundled in assets/google_fonts may be
/// used (Fredoka 600/700, Nunito 600/700/800). Another weight would make
/// the app try to download a font.
class AppText {
  AppText._();

  // The type scale: use only these sizes in new code.
  static const double sizeCaption = 12;
  static const double sizeSmall = 14;
  static const double sizeTitle = 18;
  static const double sizeDisplay = 28;
  static const double sizeHero = 44;

  static TextStyle heading({double size = 24, Color color = AppColors.ink}) =>
      GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Digits use Nunito ExtraBold because its 4 is closed and very clear.
  static TextStyle number({double size = 22, Color color = AppColors.ink}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
  }) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);
}

/// A calm, flat background used behind both screens: a very soft vertical
/// gradient from almost-white to a light grey-blue.
class FieldBackground extends StatelessWidget {
  final Widget child;
  const FieldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, AppColors.backgroundDeep],
        ),
      ),
      child: child,
    );
  }
}
