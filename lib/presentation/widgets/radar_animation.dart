import 'package:flutter/material.dart';
import 'dart:math' as math;

class RadarAnimation extends StatefulWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Duration duration;

  const RadarAnimation({
    super.key,
    this.size = 200.0,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.blueAccent,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation for radar sweep
    _rotationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Pulse animation for outer rings
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: RadarPainter(
              rotationAngle: _rotationAnimation.value,
              pulseValue: _pulseAnimation.value,
              primaryColor: widget.primaryColor,
              secondaryColor: widget.secondaryColor,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double rotationAngle;
  final double pulseValue;
  final Color primaryColor;
  final Color secondaryColor;

  RadarPainter({
    required this.rotationAngle,
    required this.pulseValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer pulse rings
    _drawPulseRings(canvas, center, radius);

    // Draw main radar circle
    _drawMainCircle(canvas, center, radius);

    // Draw radar grid lines
    _drawGridLines(canvas, center, radius);

    // Draw radar sweep
    _drawRadarSweep(canvas, center, radius);

    // Draw center dot
    _drawCenterDot(canvas, center);

    // Draw scanning dots
    _drawScanningDots(canvas, center, radius);
  }

  void _drawPulseRings(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw 3 pulse rings with different opacities
    for (int i = 0; i < 3; i++) {
      final ringRadius = radius * (0.3 + (i * 0.25)) * (1 + pulseValue * 0.3);
      final opacity = (1 - pulseValue) * (1 - i * 0.3);

      paint.color = primaryColor.withOpacity(opacity * 0.3);
      canvas.drawCircle(center, ringRadius, paint);
    }
  }

  void _drawMainCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.9, paint);

    // Border
    paint
      ..color = primaryColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.9, paint);
  }

  void _drawGridLines(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * 0.3 * i, paint);
    }

    // Draw cross lines
    canvas.drawLine(
      Offset(center.dx - radius * 0.9, center.dy),
      Offset(center.dx + radius * 0.9, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.9),
      Offset(center.dx, center.dy + radius * 0.9),
      paint,
    );

    // Draw diagonal lines
    final diagonal = radius * 0.9 * 0.707; // cos(45°)
    canvas.drawLine(
      Offset(center.dx - diagonal, center.dy - diagonal),
      Offset(center.dx + diagonal, center.dy + diagonal),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - diagonal, center.dy + diagonal),
      Offset(center.dx + diagonal, center.dy - diagonal),
      paint,
    );
  }

  void _drawRadarSweep(Canvas canvas, Offset center, double radius) {
    final sweepGradient = SweepGradient(
      startAngle: rotationAngle - math.pi / 6,
      endAngle: rotationAngle,
      colors: [
        primaryColor.withOpacity(0.0),
        primaryColor.withOpacity(0.3),
        primaryColor.withOpacity(0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 0.9),
      );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.9),
      rotationAngle - math.pi / 6,
      math.pi / 6,
      true,
      paint,
    );
  }

  void _drawCenterDot(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4.0, paint);

    // Outer ring
    paint
      ..color = primaryColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 8.0, paint);
  }

  void _drawScanningDots(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    // Draw animated dots at different positions
    for (int i = 0; i < 4; i++) {
      final angle = (rotationAngle + i * math.pi / 2) % (2 * math.pi);
      final dotRadius = radius * 0.6 * (0.3 + (i * 0.2));
      final x = center.dx + dotRadius * math.cos(angle);
      final y = center.dy + dotRadius * math.sin(angle);

      final opacity = 1.0 - (i * 0.2);
      paint.color = secondaryColor.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 3.0 - i * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.pulseValue != pulseValue;
  }
}
