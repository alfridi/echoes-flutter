import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared_widgets/tactile_waveform.dart';

/// Preview UI presenting a captured local voice recording with playback scrubber,
/// discard / re-record action, and cloud submission trigger.
class RecordingPreview extends StatelessWidget {
  final File file;
  final Duration duration;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isUploading;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const RecordingPreview({
    super.key,
    required this.file,
    required this.duration,
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    this.isUploading = false,
    required this.onPlayPause,
    required this.onSeek,
    required this.onDelete,
    required this.onSubmit,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTotal =
        totalDuration > Duration.zero ? totalDuration : duration;
    final progress = effectiveTotal.inMilliseconds > 0
        ? (currentPosition.inMilliseconds / effectiveTotal.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    final fileSize = file.existsSync() ? file.lengthSync() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.xl,
        boxShadow: AppShadows.paperCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECORDING READY',
                    style: AppTypography.labelSm.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: AppRadii.full,
                ),
                child: Text(
                  _formatFileSize(fileSize),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Central Playback Waveform
          TactileWaveformWidget(
            isPlaying: isPlaying,
            height: 60,
            barCount: 26,
          ),
          const SizedBox(height: 12),

          // Scrubber Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceContainerHighest,
              thumbColor: AppColors.secondaryContainer,
              trackHeight: 4,
            ),
            child: Slider(
              value: progress,
              onChanged: (v) {
                final seekMs = (v * effectiveTotal.inMilliseconds).toInt();
                onSeek(Duration(milliseconds: seekMs));
              },
            ),
          ),

          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(currentPosition),
                style: AppTypography.labelSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _formatDuration(effectiveTotal),
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Play / Pause Master Preview Trigger
          Center(
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : onPlayPause,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPlaying
                    ? AppColors.secondary
                    : AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.full,
                ),
              ),
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 22,
              ),
              label: Text(
                isPlaying ? 'Pause Preview' : 'Listen to Preview',
                style: AppTypography.labelLg.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: [ Delete ] & [ Submit ]
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.md,
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.md,
                    ),
                  ),
                  icon: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onSecondaryContainer,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: Text(
                    isUploading ? 'Uploading to Supabase...' : 'Submit Recording',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
