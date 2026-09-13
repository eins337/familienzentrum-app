import 'package:flutter/material.dart';
import '../theme/tokens.dart';

// Flat-vector illustrations for the four spots named in the README: Login
// header, Feed greeting, Krankmeldung success, confirmed Spielverabredung.
// Built from simple shapes (no bitmaps), using the illustration palette
// tokens. I can't render/preview Flutter UI in this environment, so please
// eyeball these once the app runs and tell me what to adjust — proportions
// especially are a best guess without a live view.

/// Login header — sky gradient block with sun, clouds, grass and a
/// stylized tree echoing the Ev. Familienzentrum Lank logo (a tree in a
/// circle), standing in for the prototype's generic Kita-Haus scene.
class LoginIllustration extends StatelessWidget {
  const LoginIllustration({super.key, this.height = 186});
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDCE8FA), Color(0xFFEDF3FB)]),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(right: 22, top: 20, child: _Sun()),
            Positioned(left: 26, top: 30, child: _Cloud(scale: 0.8)),
            Positioned(left: 90, top: 16, child: _Cloud(scale: 0.55)),
            Positioned(bottom: 0, left: 0, right: 0, child: _GrassBand()),
            Align(alignment: Alignment.bottomCenter, child: _Tree(height: height * 0.72)),
          ],
        ),
      ),
    );
  }
}

/// Feed greeting card — a small floating tree motif, matching the login
/// header's brand element at a smaller size.
class FeedGreetingIllustration extends StatelessWidget {
  const FeedGreetingIllustration({super.key, this.size = 74});
  final double size;

  @override
  Widget build(BuildContext context) {
    return _FloatingWrapper(child: _Tree(height: size));
  }
}

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

class _FloatingWrapper extends StatefulWidget {
  const _FloatingWrapper({required this.child});
  final Widget child;

  @override
  State<_FloatingWrapper> createState() => _FloatingWrapperState();
}

class _FloatingWrapperState extends State<_FloatingWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(offset: Offset(0, (_controller.value - 0.5) * 6), child: child),
      child: widget.child,
    );
  }
}

class _Sun extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 34, height: 34, decoration: const BoxDecoration(color: AppColors.illuSonne, shape: BoxShape.circle));
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud({this.scale = 1});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 60,
        height: 26,
        child: Stack(
          children: [
            Positioned(left: 0, top: 8, child: _puff(22)),
            Positioned(left: 16, top: 0, child: _puff(28)),
            Positioned(left: 36, top: 8, child: _puff(20)),
          ],
        ),
      ),
    );
  }

  Widget _puff(double d) => Container(width: d, height: d, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle));
}

class _GrassBand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Stack(
        children: [
          Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 16, color: AppColors.illuGrasShade)),
          Positioned(bottom: 6, left: 0, right: 0, child: Container(height: 14, color: AppColors.illuGras)),
        ],
      ),
    );
  }
}

/// The trunk + rounded canopy motif echoing the real Ev. Familienzentrum
/// Lank logo (a tree inside a circle).
class _Tree extends StatelessWidget {
  const _Tree({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final trunkW = height * 0.1;
    return SizedBox(
      height: height,
      width: height * 0.82,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(width: trunkW, height: height * 0.42, decoration: BoxDecoration(color: AppColors.illuHolz, borderRadius: BorderRadius.circular(trunkW / 2))),
          ),
          Positioned(
            bottom: height * 0.3,
            child: Container(
              width: height * 0.7,
              height: height * 0.7,
              decoration: BoxDecoration(color: AppColors.illuGras, shape: BoxShape.circle, border: Border.all(color: AppColors.illuGrasShade, width: 3)),
            ),
          ),
        ],
      ),
    );
  }
}
