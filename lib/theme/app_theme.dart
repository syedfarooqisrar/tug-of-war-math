import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All colors used across the app, in one place. Change a value here
/// and it updates everywhere.
class AppColors {
  static const skyTop = Color(0xFF8ECBFF);
  static const skyBottom = Color(0xFFDFF1FF);
  static const grass1 = Color(0xFF6FBE44);
  static const grass2 = Color(0xFF5AA838);

  static const rope = Color(0xFFC69A5A);
  static const ropeDark = Color(0xFF7A5B32);

  static const team1 = Color(0xFF2461E8);
  static const team1Light = Color(0xFFE3ECFF);
  static const team1Dark = Color(0xFF173E9C);

  static const team2 = Color(0xFFE8432B);
  static const team2Light = Color(0xFFFFE6E0);
  static const team2Dark = Color(0xFFA72C19);

  static const gold = Color(0xFFF4B400);
  static const goldDark = Color(0xFFB98600);
  static const ink = Color(0xFF1E293B);
  static const paper = Color(0xFFFFFAF0);
}

/// Reusable text styles. "Baloo 2" (rounded/playful) for headings,
/// "Nunito" (friendly but readable) for body text and numbers.
class AppText {
  static TextStyle heading({double size = 24, Color color = AppColors.ink}) =>
      GoogleFonts.baloo2(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle number({double size = 22, Color color = AppColors.ink}) =>
      GoogleFonts.baloo2(fontSize: size, fontWeight: FontWeight.w600, color: color);

  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
  }) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);
}

/// A sky-to-grass gradient background used behind both screens, matching
/// the outdoor tug-of-war field theme.
class FieldBackground extends StatelessWidget {
  final Widget child;
  const FieldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.6, 0.62, 1.0],
          colors: [
            AppColors.skyTop,
            AppColors.skyBottom,
            AppColors.grass1,
            AppColors.grass2,
          ],
        ),
      ),
      child: child,
    );
  }
}