import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Contexts where the mascot appears, driving its expression.
enum MascotMood {
  greeting,
  neutral,
  happy,
  encouraging,
  celebrating,
  thinking,
  sorry,
}

/// A friendly, round, hand-inspired mascot character.
///
/// The artwork is a simple custom-painted design so it can be replaced by a
/// Lottie animation or an asset later without changing any callers.
class Mascot extends StatelessWidget {
  final double size;
  final MascotMood mood;

  const Mascot({super.key, this.size = 72, this.mood = MascotMood.neutral});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MascotPainter(mood: mood),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;

  _MascotPainter({required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // Body
    final bodyPaint = Paint()..color = LingoColors.mascot;
    canvas.drawCircle(center, radius, bodyPaint);

    // Face
    final facePaint = Paint()..color = const Color(0xFFD1FAE5);
    canvas.drawCircle(
      center.translate(0, size.height * 0.06),
      radius * 0.72,
      facePaint,
    );

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF064E3B);
    final eyeOffset = radius * 0.22;
    final eyeY = center.dy + size.height * 0.05;
    canvas.drawCircle(Offset(center.dx - eyeOffset, eyeY), radius * 0.09, eyePaint);
    canvas.drawCircle(Offset(center.dx + eyeOffset, eyeY), radius * 0.09, eyePaint);

    // Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF064E3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    final frown = mood == MascotMood.sorry;
    final mouthRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size.height * 0.16),
      width: radius * 0.7,
      height: radius * (frown ? -0.5 : 0.45),
    );
    canvas.drawArc(
      mouthRect,
      frown ? -0.3 * math.pi : 0.2 * math.pi,
      frown ? 1.6 * math.pi : 1.35 * math.pi,
      false,
      mouthPaint,
    );

    // Cheeks
    final cheekPaint = Paint()..color = Colors.pink.withValues(alpha: 0.25);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.42, center.dy + size.height * 0.13),
      radius * 0.13,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.42, center.dy + size.height * 0.13),
      radius * 0.13,
      cheekPaint,
    );

    if (mood == MascotMood.celebrating) {
      final sparklePaint = Paint()..color = const Color(0xFFF59E0B);
      _drawSparkle(
          canvas, Offset(center.dx + radius * 0.9, center.dy - radius * 0.9), radius * 0.16, sparklePaint);
      _drawSparkle(
          canvas, Offset(center.dx - radius * 0.8, center.dy - radius * 1.05), radius * 0.12, sparklePaint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    const points = 8;
    for (int i = 0; i < points; i++) {
      final angle = i * (2 * math.pi / points);
      final rr = i.isEven ? r : r * 0.3;
      // Fallback: a 4-point star uses alternating radius on every 2nd vertex.
      final x = c.dx + math.cos(angle) * rr;
      final y = c.dy + math.sin(angle) * rr;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) {
    return oldDelegate.mood != mood;
  }
}