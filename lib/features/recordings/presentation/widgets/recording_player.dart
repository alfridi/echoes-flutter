import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared_widgets/tactile_waveform.dart';
import '../../domain/models/recording.dart';

/// Audio player card widget rendering a persisted voice recording item
/// with dynamic playback status and cloud streaming.
class RecordingPlayer extends StatelessWidget {
  final Recording recording;
  final bool isPlaying;
  final bool isActive;
  final Duration currentPosition;
  final Duration totalDuration;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onDelete;

  const RecordingPlayer({
    super.key,
    required this.recording,
    required this.isPlaying,
    required this.isActive,
    required this.currentPosition,
    required this.totalDuration,
    required this.onPlayPause,
    this.onSeek,
    this.onDelete,
  });

  String _formatDuration(int? seconds) {
    final s = seconds ?? 0;
    final minutes = (s ~/ 60).toString().padLeft(2, '0');
    final remSecs = (s % 60).toString().padLeft(2, '0');
    return '$minutes:$remSecs';
  }

  String _formatDurationObj(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Archived';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTotal = isActive && totalDuration > Duration.zero
        ? totalDuration
        : Duration(seconds: recording.durationSeconds ?? 0);

    final progress = isActive && effectiveTotal.inMilliseconds > 0
        ? (currentPosition.inMilliseconds / effectiveTotal.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.lg,
        boxShadow: AppShadows.paperCard,
        border: isActive
            ? Border.all(
                color: AppColors.secondaryContainer.withValues(alpha: 0.8),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Play/Pause circular button
              GestureDetector(
                onTap: onPlayPause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPlaying ? AppColors.secondary : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isPlaying
                                ? AppColors.secondary
                                : AppColors.primary)
                            .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Recording Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Recording · ${_formatDuration(recording.durationSeconds)}',
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: AppRadii.sm,
                          ),
                          child: Text(
                            _formatFileSize(recording.fileSize),
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy · HH:mm')
                          .format(recording.createdAt.toLocal()),
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete action button
              if (onDelete != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
            ],
          ),

          // Waveform & scrubber when active
          if (isActive) ...[
            const SizedBox(height: 14),
            TactileWaveformWidget(
              isPlaying: isPlaying,
              height: 36,
              barCount: 22,
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceContainerHighest,
                thumbColor: AppColors.secondaryContainer,
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: progress,
                onChanged: onSeek != null
                    ? (v) {
                        final ms = (v * effectiveTotal.inMilliseconds).toInt();
                        onSeek!(Duration(milliseconds: ms));
                      }
                    : null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDurationObj(currentPosition),
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _formatDurationObj(effectiveTotal),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
