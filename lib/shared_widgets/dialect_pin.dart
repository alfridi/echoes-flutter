import 'package:flutter/material.dart';
import '../core/constants/app_dimensions.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Archival Dialect Map Pin widget.
/// Renders an interactive geo-pin on the living atlas with country emoji,
/// dialect name, and featured status badge.
class DialectPinWidget extends StatelessWidget {
  final String countryEmoji;
  final String dialectName;
  final int echoesCount;
  final bool isFeatured;
  final VoidCallback onTap;

  const DialectPinWidget({
    super.key,
    required this.countryEmoji,
    required this.dialectName,
    required this.echoesCount,
    this.isFeatured = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isFeatured
                  ? AppColors.primary
                  : AppColors.surfaceContainerLowest,
              borderRadius: AppRadii.full,
              boxShadow: AppShadows.paperCard,
              border: Border.all(
                color: isFeatured
                    ? AppColors.surfaceBright
                    : AppColors.outlineVariant.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(countryEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    dialectName,
                    style: AppTypography.labelSm.copyWith(
                      color: isFeatured
                          ? AppColors.primaryFixed
                          : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Downward pointer tip
          CustomPaint(
            size: const Size(8, 4),
            painter: TrianglePainter(
              color: isFeatured
                  ? AppColors.primary
                  : AppColors.surfaceContainerLowest,
            ),
          ),
          if (isFeatured)
            Container(
              constraints: const BoxConstraints(maxWidth: 160),
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
                borderRadius: AppRadii.sm,
              ),
              child: Text(
                '$dialectName · $echoesCount echoes',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
