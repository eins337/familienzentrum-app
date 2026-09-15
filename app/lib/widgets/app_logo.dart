import 'package:flutter/material.dart';

/// The Familienzentrum Lank brand mark — a tree (family/growth) inside a
/// circle, with a large leaf overlapping the canopy. Recreated as vector
/// paths from the logo artwork the Kita sent (a hand-drawn-style grey/black
/// line mark), matching the illustration technique already used for the
/// Login/Feed scenes in `illustrations.dart` rather than a bundled bitmap.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.showRing = true});
  final double size;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(showRing: showRing)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.showRing});
  final bool showRing;

  static const _ink = Color(0xFF15171C);
  static const _trunkFill = Color(0xFF9A9EA6);
  static const _leafFill = Color(0xFF9A9EA6);
  static const _grassBack = Color(0xFFC7C7C7);
  static const _grassFront = Color(0xFFB3B3B3);

  Paint get _outline => Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, s, s)));

    // Grass / rolling ground band, back layer then front layer — sized to
    // clearly span the lower third like the reference artwork.
    final grassBack = Path()
      ..moveTo(-s * 0.05, s * 0.8)
      ..cubicTo(s * 0.16, s * 0.7, s * 0.32, s * 0.9, s * 0.54, s * 0.8)
      ..cubicTo(s * 0.76, s * 0.7, s * 0.9, s * 0.86, s * 1.05, s * 0.76)
      ..lineTo(s * 1.05, s * 1.05)
      ..lineTo(-s * 0.05, s * 1.05)
      ..close();
    canvas.drawPath(grassBack, Paint()..color = _grassBack);

    final grassFront = Path()
      ..moveTo(-s * 0.05, s * 0.9)
      ..cubicTo(s * 0.12, s * 0.82, s * 0.28, s * 0.98, s * 0.48, s * 0.88)
      ..cubicTo(s * 0.68, s * 0.79, s * 0.84, s * 0.96, s * 1.05, s * 0.86)
      ..lineTo(s * 1.05, s * 1.05)
      ..lineTo(-s * 0.05, s * 1.05)
      ..close();
    canvas.drawPath(grassFront, Paint()..color = _grassFront);

    // Trunk: a straight band running from the top down to the base, with
    // a slight root-flare kink near the bottom.
    final trunk = Path()
      ..moveTo(s * 0.36, s * 0.0)
      ..lineTo(s * 0.46, s * 0.0)
      ..lineTo(s * 0.46, s * 0.7)
      ..lineTo(s * 0.4, s * 1.0)
      ..lineTo(s * 0.3, s * 1.0)
      ..lineTo(s * 0.36, s * 0.66)
      ..close();
    canvas.drawPath(trunk, Paint()..color = _trunkFill);
    canvas.drawPath(trunk, _outline..strokeWidth = s * 0.014);
    canvas.drawLine(Offset(s * 0.44, s * 0.04), Offset(s * 0.44, s * 0.66), _outline..strokeWidth = s * 0.009);

    // Branch forking off toward the upper-left edge of the circle.
    final branch = Path()
      ..moveTo(s * 0.36, s * 0.28)
      ..lineTo(s * 0.1, s * 0.16)
      ..lineTo(s * 0.14, s * 0.24)
      ..lineTo(s * 0.36, s * 0.36)
      ..close();
    canvas.drawPath(branch, Paint()..color = _trunkFill);
    canvas.drawPath(branch, _outline..strokeWidth = s * 0.014);

    // Leaf / canopy — a big teardrop overlapping the upper-right, with the
    // trunk's fork tucked under its lower-left point.
    final leaf = Path()
      ..moveTo(s * 0.42, s * 0.66)
      ..cubicTo(s * 0.3, s * 0.52, s * 0.28, s * 0.3, s * 0.44, s * 0.18)
      ..cubicTo(s * 0.6, s * 0.05, s * 0.82, s * 0.1, s * 0.92, s * 0.28)
      ..cubicTo(s * 1.0, s * 0.44, s * 0.94, s * 0.6, s * 0.78, s * 0.66)
      ..cubicTo(s * 0.64, s * 0.72, s * 0.5, s * 0.72, s * 0.42, s * 0.66)
      ..close();
    canvas.drawPath(leaf, Paint()..color = _leafFill);
    canvas.drawPath(leaf, _outline..strokeWidth = s * 0.014);

    // Veins inside the leaf.
    final veinPaint = _outline..strokeWidth = s * 0.011;
    final mainVein = Path()
      ..moveTo(s * 0.44, s * 0.62)
      ..cubicTo(s * 0.56, s * 0.5, s * 0.62, s * 0.4, s * 0.62, s * 0.24);
    canvas.drawPath(mainVein, veinPaint);
    final veinBranchA = Path()
      ..moveTo(s * 0.6, s * 0.42)
      ..cubicTo(s * 0.68, s * 0.4, s * 0.74, s * 0.34, s * 0.76, s * 0.24);
    canvas.drawPath(veinBranchA, veinPaint);
    final veinBranchB = Path()
      ..moveTo(s * 0.58, s * 0.5)
      ..cubicTo(s * 0.68, s * 0.52, s * 0.78, s * 0.5, s * 0.86, s * 0.42);
    canvas.drawPath(veinBranchB, veinPaint);
    final veinLeft = Path()
      ..moveTo(s * 0.46, s * 0.56)
      ..cubicTo(s * 0.4, s * 0.46, s * 0.4, s * 0.36, s * 0.46, s * 0.28);
    canvas.drawPath(veinLeft, veinPaint);

    canvas.restore();

    if (showRing) {
      canvas.drawCircle(Offset(s / 2, s / 2), s / 2 - s * 0.01, _outline..strokeWidth = s * 0.02);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.showRing != showRing;
}
