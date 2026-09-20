import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Tactile Soundwave / Equalizer widget rendering rounded frequency bars.
/// Animated with harmonic rhythm when playing spoken archival audio.
class TactileWaveformWidget extends StatefulWidget {
  final bool isPlaying;
  final double height;
  final int barCount;

  const TactileWaveformWidget({
    super.key,
    required this.isPlaying,
    this.height = 36,
    this.barCount = 24,
  });

  @override
  State<TactileWaveformWidget> createState() => _TactileWaveformWidgetState();
}

class _TactileWaveformWidgetState extends State<TactileWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random(42);
  late List<double> _baseHeights;

  @override
  void initState() {
    super.initState();
    _baseHeights = List.generate(
      widget.barCount,
      (i) => 0.2 + _random.nextDouble() * 0.8,
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TactileWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.barCount, (index) {
              final scale = widget.isPlaying
                  ? (0.5 + 0.5 * sin(_controller.value * pi + index))
                  : 1.0;
              final barHeight = (widget.height * _baseHeights[index] * scale)
                  .clamp(4.0, widget.height);

              Color color;
              if (index % 5 == 0) {
                color = AppColors.secondaryContainer;
              } else if (index < widget.barCount * 0.6) {
                color = AppColors.primary;
              } else {
                color = AppColors.outlineVariant;
              }

              return Container(
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
