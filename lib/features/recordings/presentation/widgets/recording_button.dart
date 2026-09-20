import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared_widgets/tactile_waveform.dart';

/// Interactive tactile recording button with animated audio pulsation rings
/// and live decibel visualization.
class RecordingButton extends StatefulWidget {
  final bool isRecording;
  final Duration elapsedDuration;
  final double currentAmplitude;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const RecordingButton({
    super.key,
    required this.isRecording,
    required this.elapsedDuration,
    this.currentAmplitude = -30.0,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer display
        Text(
          widget.isRecording
              ? _formatDuration(widget.elapsedDuration)
              : 'Tap to Record',
          style: widget.isRecording
              ? AppTypography.headlineLg.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                )
              : AppTypography.headlineSm.copyWith(
                  color: AppColors.primary,
                ),
        ),
        const SizedBox(height: 8),

        Text(
          widget.isRecording
              ? 'Preserving voice acoustically...'
              : 'Speak clearly in a quiet environment',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Animated Button Deck
        GestureDetector(
          onTap: () {
            if (widget.isRecording) {
              widget.onStop();
            } else {
              widget.onStart();
            }
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseSpread = widget.isRecording
                  ? _pulseController.value * 28.0
                  : 0.0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple ring
                  if (widget.isRecording)
                    Container(
                      width: 140 + pulseSpread,
                      height: 140 + pulseSpread,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withValues(
                          alpha: 0.25 * (1.0 - _pulseController.value),
                        ),
                      ),
                    ),

                  // Middle halo ring
                  Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRecording
                          ? AppColors.errorContainer.withValues(alpha: 0.4)
                          : AppColors.surfaceContainerHighest,
                    ),
                  ),

                  // Core Action Button
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRecording
                          ? AppColors.error
                          : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isRecording
                                  ? AppColors.error
                                  : AppColors.primary)
                              .withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 28),

        // Live Audio Equalizer Waveform
        TactileWaveformWidget(
          isPlaying: widget.isRecording,
          height: 48,
          barCount: 24,
        ),
        const SizedBox(height: 12),

        // Status Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording ? AppColors.error : AppColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.isRecording
                  ? 'Recording live: AAC 128 kbps · 44.1 kHz'
                  : 'Ready to capture lossless audio',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
