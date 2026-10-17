import 'package:flutter/material.dart';

/// Crisp illustrated avatar widget matching the Aarav Sharma profile portrait
/// from the Clinova UI reference design.
class PatientAvatar extends StatelessWidget {
  final double size;

  const PatientAvatar({
    super.key,
    this.size = 72.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD6ECE0),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8D3C4).withValues(alpha: 0.5),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _AvatarPainter(),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Head / Neck skin tone
    final skinPaint = Paint()
      ..color = const Color(0xFFF6C8A6)
      ..style = PaintingStyle.fill;

    final shadowSkinPaint = Paint()
      ..color = const Color(0xFFE8B590)
      ..style = PaintingStyle.fill;

    // Hair color (Dark brown)
    final hairPaint = Paint()
      ..color = const Color(0xFF332014)
      ..style = PaintingStyle.fill;

    // Shirt color (Clinova forest green)
    final shirtPaint = Paint()
      ..color = const Color(0xFF28654F)
      ..style = PaintingStyle.fill;

    final shirtTrimPaint = Paint()
      ..color = const Color(0xFF1E523F)
      ..style = PaintingStyle.fill;

    // Feature paint (eyes/brows/smile)
    final featurePaint = Paint()
      ..color = const Color(0xFF26180E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    final eyePaint = Paint()
      ..color = const Color(0xFF26180E)
      ..style = PaintingStyle.fill;

    // 1. Shirt (bottom)
    final shirtPath = Path();
    shirtPath.moveTo(w * 0.12, h);
    shirtPath.quadraticBezierTo(w * 0.22, h * 0.68, w * 0.38, h * 0.68);
    shirtPath.lineTo(w * 0.62, h * 0.68);
    shirtPath.quadraticBezierTo(w * 0.78, h * 0.68, w * 0.88, h);
    shirtPath.close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Collar
    final collarPath = Path();
    collarPath.moveTo(w * 0.38, h * 0.68);
    collarPath.quadraticBezierTo(w * 0.5, h * 0.76, w * 0.62, h * 0.68);
    collarPath.lineTo(w * 0.60, h * 0.72);
    collarPath.quadraticBezierTo(w * 0.5, h * 0.79, w * 0.40, h * 0.72);
    collarPath.close();
    canvas.drawPath(collarPath, shirtTrimPaint);

    // 2. Neck
    final neckRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.62),
      width: w * 0.20,
      height: h * 0.20,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(neckRect, Radius.circular(w * 0.08)), shadowSkinPaint);

    // 3. Ears
    canvas.drawCircle(Offset(w * 0.28, h * 0.48), w * 0.08, skinPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.48), w * 0.08, skinPaint);

    // 4. Head/Face
    final faceRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.46),
      width: w * 0.42,
      height: h * 0.46,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(faceRect, Radius.circular(w * 0.20)), skinPaint);

    // 5. Hair (Base)
    final hairPath = Path();
    hairPath.moveTo(w * 0.25, h * 0.42);
    hairPath.cubicTo(w * 0.22, h * 0.22, w * 0.35, h * 0.16, w * 0.5, h * 0.16);
    hairPath.cubicTo(w * 0.68, h * 0.16, w * 0.78, h * 0.22, w * 0.75, h * 0.42);
    // Forehead bangs
    hairPath.quadraticBezierTo(w * 0.68, h * 0.30, w * 0.55, h * 0.28);
    hairPath.quadraticBezierTo(w * 0.42, h * 0.32, w * 0.32, h * 0.38);
    hairPath.close();
    canvas.drawPath(hairPath, hairPaint);

    // Side hair volume
    canvas.drawCircle(Offset(w * 0.28, h * 0.32), w * 0.07, hairPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.32), w * 0.07, hairPaint);

    // 6. Facial Features
    // Eyebrows
    final leftBrow = Path();
    leftBrow.moveTo(w * 0.37, h * 0.41);
    leftBrow.quadraticBezierTo(w * 0.41, h * 0.39, w * 0.45, h * 0.41);
    canvas.drawPath(leftBrow, featurePaint);

    final rightBrow = Path();
    rightBrow.moveTo(w * 0.55, h * 0.41);
    rightBrow.quadraticBezierTo(w * 0.59, h * 0.39, w * 0.63, h * 0.41);
    canvas.drawPath(rightBrow, featurePaint);

    // Eyes
    canvas.drawCircle(Offset(w * 0.41, h * 0.46), w * 0.026, eyePaint);
    canvas.drawCircle(Offset(w * 0.59, h * 0.46), w * 0.026, eyePaint);

    // Nose
    final nosePath = Path();
    nosePath.moveTo(w * 0.50, h * 0.47);
    nosePath.lineTo(w * 0.49, h * 0.52);
    nosePath.lineTo(w * 0.51, h * 0.52);
    canvas.drawPath(nosePath, featurePaint);

    // Smile
    final smilePath = Path();
    smilePath.moveTo(w * 0.44, h * 0.56);
    smilePath.quadraticBezierTo(w * 0.50, h * 0.61, w * 0.56, h * 0.56);
    canvas.drawPath(smilePath, featurePaint);

    // Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFF2A385).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.36, h * 0.51), w * 0.035, cheekPaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.51), w * 0.035, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
