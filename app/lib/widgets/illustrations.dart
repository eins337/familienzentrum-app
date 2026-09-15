import 'package:flutter/material.dart';
import '../theme/tokens.dart';

// Flat-vector illustrations for the spots named in the README: Krankmeldung
// success, confirmed Spielverabredung. Built from simple shapes (no
// bitmaps), using the illustration palette tokens. The Login header and
// Feed greeting now use the real brand mark (`AppLogo`) instead of the
// placeholder tree motif that used to live here.

/// Krankmeldung success — a sleeping child in bed.
class SleepingChildIllustration extends StatelessWidget {
  const SleepingChildIllustration({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: size * 0.12,
            child: Container(
              width: size * 0.86,
              height: size * 0.14,
              decoration: BoxDecoration(color: AppColors.illuHolz, borderRadius: BorderRadius.circular(6)),
            ),
          ),
          Positioned(
            bottom: size * 0.24,
            child: Container(
              width: size * 0.78,
              height: size * 0.32,
              decoration: BoxDecoration(color: AppColors.groupBlauSoft, borderRadius: BorderRadius.circular(14)),
            ),
          ),
          Positioned(
            bottom: size * 0.42,
            left: size * 0.16,
            child: Container(width: size * 0.24, height: size * 0.18, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8))),
          ),
          Positioned(
            bottom: size * 0.44,
            left: size * 0.2,
            child: Container(width: size * 0.16, height: size * 0.16, decoration: const BoxDecoration(color: AppColors.illuSkin, shape: BoxShape.circle)),
          ),
          Positioned(top: size * 0.14, right: size * 0.22, child: Text('z z z', style: AppText.outfit(size: size * 0.14, weight: FontWeight.w700, color: AppColors.primary))),
        ],
      ),
    );
  }
}

/// Confirmed Spielverabredung — two children's head-circles side by side.
class PlaydateConfirmedIllustration extends StatelessWidget {
  const PlaydateConfirmedIllustration({super.key, this.size = 110});
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget child(Color hair, Color shirt) => Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: BoxDecoration(color: shirt, shape: BoxShape.circle),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: size * 0.02,
                child: Container(
                  width: size * 0.24,
                  height: size * 0.24,
                  decoration: const BoxDecoration(color: AppColors.illuSkin, shape: BoxShape.circle),
                  child: ClipOval(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(height: size * 0.12, color: hair),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

    return SizedBox(
      width: size,
      height: size * 0.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: size * 0.06, child: child(AppColors.illuHair, AppColors.groupBlauSoft)),
          Positioned(right: size * 0.06, child: child(AppColors.illuHairAlt, AppColors.groupRotSoft)),
          Positioned(
            bottom: 0,
            child: Icon(Icons.favorite_rounded, size: size * 0.16, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

