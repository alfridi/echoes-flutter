import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Archival brand emblem with circular acoustic seal and frequency bars.
/// Represents the living voice preservation seal of Echoes.
class EchoesEmblemWidget extends StatelessWidget {
  final double size;

  const EchoesEmblemWidget({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: EchoesEmblemPainter(),
      ),
    );
  }
}

class EchoesEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circle
    final bgPaint = Paint()..color = AppColors.primaryContainer;
    canvas.drawCircle(center, radius, bgPaint);

    // Dashed inner ring
    final dashedPaint = Paint()
      ..color = AppColors.surfaceContainerLow.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.85, dashedPaint);

    // Soundwave frequency bars
    final barPaint = Paint()
      ..color = AppColors.surface
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    final centerBarPaint = Paint()
      ..color = AppColors.secondaryContainer
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final heights = [0.15, 0.3, 0.5, 0.7, 0.95, 0.7, 0.5, 0.3, 0.15];
    final barSpacing = size.width * 0.055;
    final startX = center.dx - (heights.length ~/ 2) * barSpacing;

    for (int i = 0; i < heights.length; i++) {
      final x = startX + i * barSpacing;
      final h = heights[i] * (size.height * 0.5);
      final p = (i == heights.length ~/ 2) ? centerBarPaint : barPaint;
      canvas.drawLine(Offset(x, center.dy - h / 2), Offset(x, center.dy + h / 2), p);
    }

    // Center pivot node
    final nodePaint = Paint()..color = AppColors.surface;
    canvas.drawCircle(center, size.width * 0.04, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
