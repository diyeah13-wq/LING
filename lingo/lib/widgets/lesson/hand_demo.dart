import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/sign.dart';

/// An animated, stylized hand demonstration for a sign.
///
/// This is a lightweight cartoon illustration that conveys the handshape and,
/// for motion signs, an animated path hint. It is NOT a video; real
/// demonstration footage can later replace this widget without affecting
/// anything else in the app.
class AnimatedSignDemo extends StatefulWidget {
  final Sign sign;
  final double size;

  const AnimatedSignDemo({super.key, required this.sign, this.size = 200});

  @override
  State<AnimatedSignDemo> createState() => _AnimatedSignDemoState();
}

class _AnimatedSignDemoState extends State<AnimatedSignDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration:
          widget.sign.type == SignType.motion ? const Duration(seconds: 2) : const Duration(seconds: 1),
    )..repeat(reverse: widget.sign.type == SignType.motion);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _HandDemoPainter(
        controller: _controller,
        sign: widget.sign,
      ),
    );
  }
}

class _HandDemoPainter extends CustomPainter {
  final Animation<double> controller;
  final Sign sign;

  _HandDemoPainter({required this.controller, required this.sign});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.width / 200;

    // Background disc
    final bgPaint = Paint()
      ..color = LingoColors.primary.withValues(alpha: 0.08);
    canvas.drawCircle(center, size.width * 0.44, bgPaint);

    // Draw a simplified flat hand (open/neutral pose).
    final handPaint = Paint()..color = const Color(0xFFFFB74D);
    _drawPalm(canvas, center, unit, handPaint);

    if (sign.type == SignType.motion) {
      _drawMotionArc(canvas, center, unit);
    }

    // Label chip
    final labelStyle = TextStyle(
      color: LingoColors.textSecondary,
      fontSize: 13 * unit.clamp(0.8, 1.2),
      fontWeight: FontWeight.w600,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: sign.type == SignType.motion ? '⟳ motion' : 'static',
        style: labelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        center.dx - tp.width / 2,
        center.dy + size.width * 0.34,
      ),
    );
  }

  void _drawPalm(Canvas canvas, Offset center, double unit, Paint paint) {
    // Palm body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: 72 * unit,
          height: 84 * unit,
        ),
        Radius.circular(26 * unit),
      ),
      paint,
    );

    // Fingers (open hand).
    const fingerOffset = [-26.0, -9.0, 9.0, 26.0];
    for (final dx in fingerOffset) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center.dx + dx * unit - 9 * unit,
            center.dy - 78 * unit,
            18 * unit,
            48 * unit,
          ),
          Radius.circular(9 * unit),
        ),
        paint,
      );
    }

    // Thumb
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx - 78 * unit,
          center.dy - 8 * unit,
          40 * unit,
          22 * unit,
        ),
        Radius.circular(11 * unit),
      ),
      paint,
    );
  }

  void _drawMotionArc(Canvas canvas, Offset center, double unit) {
    // Animated arc showing the direction of motion.
    final t = controller.value;
    final arcPaint = Paint()
      ..color = LingoColors.primary.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * unit
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCenter(
      center: center.translate(0, 8 * unit),
      width: 92 * unit,
      height: 92 * unit,
    );
    final arcAngle = (0.15 + 0.7 * t) * 2 * math.pi;
    canvas.drawArc(arcRect, 0.2 * math.pi, arcAngle, false, arcPaint);

    // Motion arrowhead
    final headPos = Offset(
      arcRect.center.dx + arcRect.width / 2 * math.cos(arcAngle + 0.2 * math.pi),
      arcRect.center.dy + arcRect.height / 2 * math.sin(arcAngle + 0.2 * math.pi),
    );
    final headPaint = Paint()..color = LingoColors.primary;
    canvas.drawCircle(headPos, 4 * unit, headPaint);
  }

  @override
  bool shouldRepaint(covariant _HandDemoPainter oldDelegate) {
    return oldDelegate.controller.value != controller.value;
  }
}