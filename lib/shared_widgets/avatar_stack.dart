import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Overlapping Community Avatar Stack widget.
/// Displays a horizontal strip of contributor avatar circles with an overflow counter pill.
class AvatarStackWidget extends StatelessWidget {
  final String countText;
  final List<String>? avatarUrls;

  const AvatarStackWidget({
    super.key,
    required this.countText,
    this.avatarUrls,
  });

  @override
  Widget build(BuildContext context) {
    final images = (avatarUrls != null && avatarUrls!.isNotEmpty)
        ? avatarUrls!
        : const [
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
          ];

    return SizedBox(
      height: 32,
      width: (images.length * 18.0) + 36.0,
      child: Stack(
        children: [
          for (int i = 0; i < images.length; i++)
            Positioned(
              left: i * 18.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceContainerLow,
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(images[i]),
                ),
              ),
            ),
          Positioned(
            left: images.length * 18.0,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                countText,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onPrimaryContainer,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
