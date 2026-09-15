import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small set of custom-drawn, kindergarten-themed icons replacing the
/// generic Material icon set in the most visible spots (bottom nav, Feed
/// quick actions) — warm rounded strokes matching the flat-illustration
/// style already used in `illustrations.dart`, rather than the default
/// sharp/technical Material icon shapes.
enum KitaIcon { feed, gruppen, chat, spielen, team, profil, thermometer, playdate, megaphone }

class KitaIconWidget extends StatelessWidget {
  const KitaIconWidget(this.icon, {super.key, this.size = 20, this.color = Colors.black, this.strokeWidth = 1.7});
  final KitaIcon icon;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KitaIconPainter(icon, color, strokeWidth)),
    );
  }
}

class _KitaIconPainter extends CustomPainter {
  _KitaIconPainter(this.icon, this.color, this.strokeWidth);
  final KitaIcon icon;
  final Color color;
  final double strokeWidth;

  Paint get _stroke => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get _fill => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    switch (icon) {
      case KitaIcon.feed:
        _paintFeed(canvas, s);
      case KitaIcon.gruppen:
        _paintGruppen(canvas, s);
      case KitaIcon.chat:
        _paintChat(canvas, s);
      case KitaIcon.spielen:
        _paintSpielen(canvas, s);
      case KitaIcon.team:
        _paintTeam(canvas, s);
      case KitaIcon.profil:
        _paintProfil(canvas, s);
      case KitaIcon.thermometer:
        _paintThermometer(canvas, s);
      case KitaIcon.playdate:
        _paintPlaydate(canvas, s);
      case KitaIcon.megaphone:
        _paintMegaphone(canvas, s);
    }
  }

  // Open storybook — two curved pages meeting at a spine, for "Aktuelles".
  void _paintFeed(Canvas canvas, double s) {
    final left = Path()
      ..moveTo(s * 0.5, s * 0.24)
      ..cubicTo(s * 0.36, s * 0.16, s * 0.2, s * 0.16, s * 0.1, s * 0.22)
      ..lineTo(s * 0.1, s * 0.74)
      ..cubicTo(s * 0.2, s * 0.68, s * 0.36, s * 0.68, s * 0.5, s * 0.76)
      ..close();
    final right = Path()
      ..moveTo(s * 0.5, s * 0.24)
      ..cubicTo(s * 0.64, s * 0.16, s * 0.8, s * 0.16, s * 0.9, s * 0.22)
      ..lineTo(s * 0.9, s * 0.74)
      ..cubicTo(s * 0.8, s * 0.68, s * 0.64, s * 0.68, s * 0.5, s * 0.76)
      ..close();
    canvas.drawPath(left, _stroke);
    canvas.drawPath(right, _stroke);
  }

  // Two child figures (head + shoulders) standing apart, for "Gruppen" —
  // kept to two, non-overlapping, so the reading stays clear at icon size
  // (a third overlapping figure just merged into a blob).
  void _paintGruppen(Canvas canvas, double s) {
    void figure(double cx, double headR) {
      canvas.drawCircle(Offset(cx, s * 0.34), headR, _stroke);
      final shoulders = Path()
        ..moveTo(cx - headR * 1.5, s * 0.86)
        ..cubicTo(cx - headR * 1.5, s * 0.58, cx + headR * 1.5, s * 0.58, cx + headR * 1.5, s * 0.86);
      canvas.drawPath(shoulders, _stroke);
    }

    figure(s * 0.3, s * 0.15);
    figure(s * 0.72, s * 0.13);
  }

  // Rounded speech bubble with a small heart inside — warm, family chat.
  void _paintChat(Canvas canvas, double s) {
    final bubble = RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.1, s * 0.16, s * 0.8, s * 0.54), Radius.circular(s * 0.2));
    canvas.drawRRect(bubble, _stroke);
    final tail = Path()
      ..moveTo(s * 0.3, s * 0.68)
      ..lineTo(s * 0.24, s * 0.86)
      ..lineTo(s * 0.44, s * 0.7)
      ..close();
    canvas.drawPath(tail, _fill);
    // small heart
    final hp = Path();
    final cx = s * 0.5, cy = s * 0.42, r = s * 0.07;
    hp.moveTo(cx, cy + r * 0.8);
    hp.cubicTo(cx - r * 1.6, cy - r * 0.6, cx - r * 0.4, cy - r * 1.6, cx, cy - r * 0.4);
    hp.cubicTo(cx + r * 0.4, cy - r * 1.6, cx + r * 1.6, cy - r * 0.6, cx, cy + r * 0.8);
    canvas.drawPath(hp, _fill);
  }

  // Pinwheel (Windrad) — playful classic kindergarten toy, for "Spielen".
  void _paintSpielen(Canvas canvas, double s) {
    final center = Offset(s * 0.5, s * 0.48);
    final r = s * 0.28;
    for (var i = 0; i < 4; i++) {
      final angle = (i * 90) * math.pi / 180;
      final tip = Offset(center.dx + r * _cos(angle), center.dy + r * _sin(angle));
      final petal = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          center.dx + r * 0.55 * _cos(angle + 0.9),
          center.dy + r * 0.55 * _sin(angle + 0.9),
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          center.dx + r * 0.55 * _cos(angle - 0.9),
          center.dy + r * 0.55 * _sin(angle - 0.9),
          center.dx,
          center.dy,
        )
        ..close();
      canvas.drawPath(petal, _stroke);
    }
    canvas.drawCircle(center, s * 0.05, _fill);
    canvas.drawLine(center, Offset(s * 0.5, s * 0.92), _stroke);
  }

  // ID badge on a lanyard, with a small star — for the Kita team's tab.
  void _paintTeam(Canvas canvas, double s) {
    canvas.drawLine(Offset(s * 0.36, s * 0.08), Offset(s * 0.46, s * 0.24), _stroke);
    canvas.drawLine(Offset(s * 0.64, s * 0.08), Offset(s * 0.54, s * 0.24), _stroke);
    final badge = RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.22, s * 0.24, s * 0.56, s * 0.66), Radius.circular(s * 0.12));
    canvas.drawRRect(badge, _stroke);
    canvas.drawCircle(Offset(s * 0.5, s * 0.42), s * 0.1, _stroke);
    final starCenter = Offset(s * 0.5, s * 0.68);
    canvas.drawPath(_star(starCenter, s * 0.09, s * 0.04), _fill);
  }

  // Simple rounded parent+child silhouette, for "Profil".
  void _paintProfil(Canvas canvas, double s) {
    canvas.drawCircle(Offset(s * 0.4, s * 0.28), s * 0.16, _stroke);
    final bigBody = Path()
      ..moveTo(s * 0.14, s * 0.86)
      ..cubicTo(s * 0.14, s * 0.6, s * 0.66, s * 0.6, s * 0.66, s * 0.86);
    canvas.drawPath(bigBody, _stroke);
    canvas.drawCircle(Offset(s * 0.76, s * 0.46), s * 0.1, _stroke);
    final smallBody = Path()
      ..moveTo(s * 0.6, s * 0.9)
      ..cubicTo(s * 0.6, s * 0.72, s * 0.92, s * 0.72, s * 0.92, s * 0.9);
    canvas.drawPath(smallBody, _stroke);
  }

  // Thermometer with a rounded bulb — for Krankmelden.
  void _paintThermometer(Canvas canvas, double s) {
    final tube = RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.42, s * 0.1, s * 0.16, s * 0.52), Radius.circular(s * 0.08));
    canvas.drawRRect(tube, _stroke);
    canvas.drawCircle(Offset(s * 0.5, s * 0.74), s * 0.16, _stroke);
    canvas.drawCircle(Offset(s * 0.5, s * 0.74), s * 0.08, _fill);
    canvas.drawLine(Offset(s * 0.5, s * 0.26), Offset(s * 0.5, s * 0.58), _stroke..strokeWidth = strokeWidth * 0.8);
  }

  // Paper airplane — inviting another family to play.
  void _paintPlaydate(Canvas canvas, double s) {
    final plane = Path()
      ..moveTo(s * 0.12, s * 0.5)
      ..lineTo(s * 0.88, s * 0.16)
      ..lineTo(s * 0.56, s * 0.88)
      ..lineTo(s * 0.46, s * 0.58)
      ..close();
    canvas.drawPath(plane, _stroke);
    canvas.drawLine(Offset(s * 0.46, s * 0.58), Offset(s * 0.88, s * 0.16), _stroke..strokeWidth = strokeWidth * 0.8);
  }

  // Rounded megaphone — announcements / Erzieher schreiben.
  void _paintMegaphone(Canvas canvas, double s) {
    final body = Path()
      ..moveTo(s * 0.18, s * 0.42)
      ..lineTo(s * 0.58, s * 0.18)
      ..lineTo(s * 0.58, s * 0.7)
      ..lineTo(s * 0.18, s * 0.58)
      ..close();
    canvas.drawPath(body, _stroke);
    canvas.drawLine(Offset(s * 0.18, s * 0.42), Offset(s * 0.18, s * 0.58), _stroke);
    canvas.drawArc(Rect.fromLTWH(s * 0.56, s * 0.2, s * 0.3, s * 0.48), -1.0, 2.0, false, _stroke);
    canvas.drawLine(Offset(s * 0.3, s * 0.6), Offset(s * 0.34, s * 0.82), _stroke..strokeWidth = strokeWidth * 0.8);
  }

  Path _star(Offset c, double outerR, double innerR) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * 36 - 90) * math.pi / 180;
      final p = Offset(c.dx + r * _cos(angle), c.dy + r * _sin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  double _cos(double radians) => math.cos(radians);
  double _sin(double radians) => math.sin(radians);

  @override
  bool shouldRepaint(covariant _KitaIconPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
