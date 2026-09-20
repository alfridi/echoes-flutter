import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/map_pin.dart';
import '../../../../shared_widgets/dialect_pin.dart';

/// Interactive archival parchment map canvas.
/// Plots dialect pins dynamically using normalized coordinates (top_percent, left_percent).
class ArchivalMapCanvas extends StatelessWidget {
  final List<DialectPinModel> pins;
  final ValueChanged<String> onPinSelected;

  const ArchivalMapCanvas({
    super.key,
    required this.pins,
    required this.onPinSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      width: double.infinity,
      color: AppColors.mapWaterBase,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mapWidth = constraints.maxWidth;
          final mapHeight = constraints.maxHeight;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Archival Parchment & Landmass Canvas Painter
              Positioned.fill(
                child: CustomPaint(
                  painter: ArchivalMapPainter(),
                ),
              ),

              // 2. Living Atlas Header Badge
              Positioned(
                top: 14,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.92),
                    borderRadius: AppRadii.full,
                    boxShadow: AppShadows.paperCard,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.explore,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVING ATLAS',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Dynamic Dialect Pins loaded from Supabase
              for (final pin in pins)
                Positioned(
                  top: (pin.topPercent * mapHeight).clamp(10.0, mapHeight - 50.0),
                  left: (pin.leftPercent * mapWidth).clamp(10.0, mapWidth - 110.0),
                  child: DialectPinWidget(
                    countryEmoji: pin.countryEmoji,
                    dialectName: pin.languageName,
                    echoesCount: pin.echoesCount,
                    isFeatured: pin.isFeatured,
                    onTap: () => onPinSelected(pin.languageId),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom Painter for Archival Coordinate Grid & Stylized Geographic Silhouettes
class ArchivalMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.outline.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    // Archival Latitude & Longitude Coordinate Lines
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Stylized landmass polygons (warm paper landmasses)
    final landPaint = Paint()
      ..color = AppColors.mapLandMass
      ..style = PaintingStyle.fill;

    // Stylized Americas Landmass
    final americasPath = Path()
      ..moveTo(size.width * 0.12, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.16,
        size.width * 0.26,
        size.height * 0.32,
      )
      ..lineTo(size.width * 0.20, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.60,
        size.width * 0.22,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.75,
        size.width * 0.14,
        size.height * 0.50,
      )
      ..close();
    canvas.drawPath(americasPath, landPaint);

    // Stylized Eurasia & Africa
    final eurasiaAfricaPath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.14,
        size.width * 0.82,
        size.height * 0.22,
      )
      ..lineTo(size.width * 0.86, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.46,
        size.width * 0.64,
        size.height * 0.58,
      )
      // African continent southward
      ..quadraticBezierTo(
        size.width * 0.58,
        size.height * 0.78,
        size.width * 0.52,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.64,
        size.width * 0.44,
        size.height * 0.45,
      )
      ..close();
    canvas.drawPath(eurasiaAfricaPath, landPaint);

    // Stylized Japan / East Asia archipelago
    final islandPaint = Paint()
      ..color = AppColors.mapLandMass
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.84, size.height * 0.34),
        width: size.width * 0.08,
        height: size.height * 0.12,
      ),
      islandPaint,
    );

    // Stylized Oceania / Australia
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.80, size.height * 0.76),
        width: size.width * 0.14,
        height: size.height * 0.14,
      ),
      islandPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
