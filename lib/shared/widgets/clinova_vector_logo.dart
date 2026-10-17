import 'package:flutter/material.dart';
import '../../core/theme/clinova_colors.dart';

/// Reusable vector-style Heart + ECG + Leaf logo for Clinova
class ClinovaVectorLogo extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final Color fillColor;
  final double progress; // 0.0 to 1.0 for ECG drawing animation

  const ClinovaVectorLogo({
    super.key,
    this.size = 120,
    this.primaryColor = ClinovaColors.primaryAccent,
    this.secondaryColor = ClinovaColors.secondaryAccent,
    this.fillColor = const Color(0xFFD4EBD9),
    this.progress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ClinovaLogoPainter(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          fillColor: fillColor,
          progress: progress,
        ),
      ),
    );
  }
}

class _ClinovaLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color fillColor;
  final double progress;

  _ClinovaLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.fillColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;

    // Heart Path
    final heartPath = Path();
    final scale = width / 100.0;

    // Adjusted heart bezier curves
    heartPath.moveTo(50 * scale, 28 * scale);
    heartPath.cubicTo(
      40 * scale, 12 * scale,
      14 * scale, 12 * scale,
      14 * scale, 34 * scale,
    );
    heartPath.cubicTo(
      14 * scale, 52 * scale,
      32 * scale, 68 * scale,
      50 * scale, 86 * scale,
    );
    heartPath.cubicTo(
      68 * scale, 68 * scale,
      86 * scale, 52 * scale,
      86 * scale, 34 * scale,
    );
    heartPath.cubicTo(
      86 * scale, 12 * scale,
      60 * scale, 12 * scale,
      50 * scale, 28 * scale,
    );
    heartPath.close();

    // 1. Draw subtle soft background glow / fill of the heart
    final fillPaint = Paint()
      ..color = fillColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(heartPath, fillPaint);

    // 2. Heart stroke
    final heartStrokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(heartPath, heartStrokePaint);

    // 3. ECG Pulse line across the heart
    final ecgPath = Path();
    ecgPath.moveTo(12 * scale, 50 * scale);
    ecgPath.lineTo(34 * scale, 50 * scale);
    ecgPath.lineTo(40 * scale, 58 * scale);
    ecgPath.lineTo(48 * scale, 30 * scale);
    ecgPath.lineTo(54 * scale, 64 * scale);
    ecgPath.lineTo(60 * scale, 42 * scale);
    ecgPath.lineTo(66 * scale, 50 * scale);
    ecgPath.lineTo(88 * scale, 50 * scale);

    if (progress > 0) {
      final ecgPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Extract animated portion of ECG path
      final pathMetrics = ecgPath.computeMetrics();
      for (final metric in pathMetrics) {
        final extractLength = metric.length * progress.clamp(0.0, 1.0);
        final animatedPath = metric.extractPath(0.0, extractLength);
        canvas.drawPath(animatedPath, ecgPaint);
      }
    }

    // 4. Little botanical leaf accent on the top left curve
    final leafPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(38 * scale, 18 * scale);
    leafPath.quadraticBezierTo(44 * scale, 10 * scale, 48 * scale, 8 * scale);
    leafPath.quadraticBezierTo(48 * scale, 16 * scale, 42 * scale, 22 * scale);
    leafPath.close();

    canvas.save();
    canvas.drawPath(leafPath, leafPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ClinovaLogoPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.fillColor != fillColor;
  }
}
