import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../cubits/audio_player/audio_player_cubit.dart';
import '../../cubits/audio_player/audio_player_state.dart';
import '../../cubits/audio_recorder/audio_recorder_cubit.dart';
import '../../cubits/audio_recorder/audio_recorder_state.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../models/word_entry.dart';
import '../../repositories/word_repository.dart';
import '../../shared_widgets/tactile_waveform.dart';

/// Screen 5: Record Voice Expedition Screen.
/// Guides the user through voice capture, previewing local .m4a audio,
/// and uploading to Supabase Storage + PostgreSQL echo_recordings.
class RecordVoiceScreen extends StatefulWidget {
  final String wordId;
  final String languageId;

  const RecordVoiceScreen({
    super.key,
    this.wordId = 'welcome',
    this.languageId = 'malayalam',
  });

  @override
  State<RecordVoiceScreen> createState() => _RecordVoiceScreenState();
}

class _RecordVoiceScreenState extends State<RecordVoiceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  WordEntry? _word;
  final TextEditingController _accentController =
      TextEditingController(text: 'Regional Vernacular Accent');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadTargetWord();
  }

  Future<void> _loadTargetWord() async {
    try {
      final repo = context.read<WordRepository>();
      final word = await repo.getWordDetail(widget.wordId);
      if (mounted) {
        setState(() {
          _word = word;
          if (word.originTerritory.isNotEmpty) {
            _accentController.text = word.originTerritory;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _accentController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final s = seconds.toString().padLeft(2, '0');
    return '00:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioRecorderCubit, AudioRecorderState>(
      listener: (context, state) {
        if (state is RecorderUploadedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.primary,
              content: Text(
                '✨ Echo successfully preserved to Supabase Audio Archive!',
              ),
            ),
          );
          // Return to WordDetailScreen so it refreshes community recordings
          context.pop(true);
        } else if (state is RecorderFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Capture error: ${state.error}'),
            ),
          );
        }
      },
      builder: (context, state) {
        final recorderCubit = context.read<AudioRecorderCubit>();
        final isRecording = state is RecorderRecording;
        final isCaptured = state is RecorderCaptured;
        final isUploading = state is RecorderUploading;

        final elapsedSeconds = isRecording
            ? state.elapsedSeconds
            : (isCaptured ? state.duration.inSeconds : 0);
        final maxSeconds = isRecording ? state.maxSeconds : 5;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                recorderCubit.reset();
                context.pop();
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECORD EXPEDITION',
                  style: AppTypography.labelSm.copyWith(
                    letterSpacing: 1.5,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Preserve a Voice',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      // 1. Target Prompt Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppRadii.lg,
                          boxShadow: AppShadows.paperCard,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.history_edu,
                                        size: 16,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'YOU ARE PRESERVING',
                                          style: AppTypography.labelSm.copyWith(
                                            letterSpacing: 1.1,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: AppRadii.full,
                                  ),
                                  child: Text(
                                    widget.languageId.toUpperCase(),
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 8),
                      Text(
                        _word?.englishWord ?? 'Word',
                        style: AppTypography.headlineLg,
                      ),
                      if (_word != null && _word!.nativeScript.isNotEmpty)
                        Text(
                          _word!.nativeScript,
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer.withValues(alpha: 0.6),
                          borderRadius: AppRadii.md,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.graphic_eq,
                              size: 18,
                              color: AppColors.secondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _word != null && _word!.transliteration.isNotEmpty
                                    ? '[${_word!.transliteration}] · Say the word naturally, the way you know it.'
                                    : 'Say the word naturally, the way you know it.',
                                style: AppTypography.bodySm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Central Recording Canvas
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.xl,
                    boxShadow: AppShadows.paperCard,
                  ),
                  child: Column(
                    children: [
                      // Status Headline
                      Text(
                        isUploading
                            ? 'Uploading to Supabase Storage...'
                            : (isCaptured
                                ? 'Recording Captured · ${_formatDuration(elapsedSeconds)}'
                                : (isRecording
                                    ? '${_formatDuration(elapsedSeconds)} / ${_formatDuration(maxSeconds)} max'
                                    : 'Preserve a Voice')),
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRecording
                            ? 'Speak now with clarity...'
                            : (isCaptured
                                ? 'Review your voice preview below'
                                : 'Say the word naturally,\nthe way you know it.'),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Progress bar
                      SizedBox(
                        width: 140,
                        child: isUploading
                            ? const LinearProgressIndicator(
                                minHeight: 6,
                                color: AppColors.primary,
                              )
                            : LinearProgressIndicator(
                                value: isRecording
                                    ? (elapsedSeconds / maxSeconds).clamp(0.0, 1.0)
                                    : (isCaptured ? 1.0 : 0.0),
                                backgroundColor:
                                    AppColors.surfaceContainerHighest,
                                color: AppColors.secondaryContainer,
                                minHeight: 6,
                                borderRadius: AppRadii.full,
                              ),
                      ),
                      const SizedBox(height: 28),

                      // Concentric Pulse Microphone Button
                      GestureDetector(
                        onTap: () {
                          if (!isRecording && !isCaptured && !isUploading) {
                            recorderCubit.startRecording();
                          } else if (isRecording) {
                            recorderCubit.stopLocalCapture();
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isRecording)
                                  Container(
                                    width: 140 + (_pulseController.value * 24),
                                    height: 140 + (_pulseController.value * 24),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryFixed.withValues(
                                        alpha: 0.3 * (1 - _pulseController.value),
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCaptured
                                        ? AppColors.secondaryFixed
                                        : AppColors.surfaceContainerHighest,
                                  ),
                                ),
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isRecording
                                        ? AppColors.error
                                        : (isCaptured
                                            ? AppColors.secondary
                                            : AppColors.primary),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isRecording
                                                ? AppColors.error
                                                : AppColors.primary)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isRecording
                                        ? Icons.stop
                                        : (isCaptured ? Icons.check : Icons.mic),
                                    color: Colors.white,
                                    size: 38,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Live Dynamic Equalizer Bars
                      TactileWaveformWidget(
                        isPlaying: isRecording,
                        height: 44,
                        barCount: 22,
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.graphic_eq,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isRecording
                                ? 'Capturing audio: 48 kHz Pristine'
                                : (isCaptured
                                    ? 'Acoustic waveform ready'
                                    : 'Hold or tap to record'),
                            style: AppTypography.labelSm,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Captured Preview Audio Player (when state is RecorderCaptured)
                if (isCaptured)
                  BlocBuilder<AudioPlayerCubit, AudioPlaybackState>(
                    builder: (context, audioState) {
                      final audioCubit = context.read<AudioPlayerCubit>();
                      final isPreviewPlaying =
                          audioState.activeTrackId == 'preview_echo' &&
                              audioState.isPlaying;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppRadii.lg,
                          border: Border.all(
                            color: AppColors.secondaryContainer
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'PREVIEW CAPTURED ECHO',
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isPreviewPlaying
                                        ? AppColors.secondary
                                        : AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                  ),
                                  onPressed: () {
                                    audioCubit.playTrack(
                                      audioUrl: state.file.path,
                                      trackId: 'preview_echo',
                                    );
                                  },
                                  icon: Icon(
                                    isPreviewPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isPreviewPlaying ? 'Pause' : 'Play Preview',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),

                // 4. Accent / Origin input
                TextField(
                  controller: _accentController,
                  decoration: InputDecoration(
                    labelText: 'Accent or Regional Territory',
                    labelStyle: AppTypography.labelSm,
                    hintText: 'e.g. Central Travancore accent',
                    prefixIcon: const Icon(
                      Icons.place,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: const OutlineInputBorder(
                      borderRadius: AppRadii.md,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Preservation Guidance Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: AppRadii.lg,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb,
                          color: AppColors.onSecondaryFixed,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Speak directly into your phone microphone in a quiet space. Lossless AAC (.m4a) audio is uploaded directly to Supabase Storage.',
                          style: AppTypography.bodySm,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Action Controls: Discard & Upload / Record
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          recorderCubit.reset();
                          if (isCaptured) {
                            // Just resets to initial
                          } else {
                            context.pop();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadii.md,
                          ),
                        ),
                        child: Text(
                          isCaptured ? 'Re-record' : 'Discard',
                          style: AppTypography.labelLg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isUploading
                            ? null
                            : () {
                                if (isRecording) {
                                  recorderCubit.stopLocalCapture();
                                } else if (isCaptured) {
                                  final authState =
                                      context.read<AuthCubit>().state;
                                  String contributorName = 'Dialect Custodian';
                                  String avatarUrl =
                                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120';

                                  if (authState is Authenticated) {
                                    contributorName =
                                        authState.profile.displayName;
                                    if (authState.profile.avatarUrl != null) {
                                      avatarUrl = authState.profile.avatarUrl!;
                                    }
                                  }

                                  recorderCubit.uploadToSupabase(
                                    wordId: widget.wordId,
                                    languageId: widget.languageId,
                                    accentTerritory: _accentController.text.trim().isNotEmpty
                                        ? _accentController.text.trim()
                                        : 'Vernacular Accent',
                                    contributorName: contributorName,
                                    contributorAvatarUrl: avatarUrl,
                                  );
                                } else {
                                  recorderCubit.startRecording();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCaptured
                              ? AppColors.secondaryContainer
                              : AppColors.primary,
                          foregroundColor: isCaptured
                              ? AppColors.onSecondaryContainer
                              : AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(
                          isCaptured
                              ? Icons.cloud_upload
                              : (isRecording ? Icons.stop_circle : Icons.mic),
                          size: 20,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isUploading
                                ? 'Preserving...'
                                : (isCaptured
                                    ? 'Upload to Supabase'
                                    : (isRecording
                                        ? 'Stop & Review'
                                        : 'Start Recording')),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
      },
    );
  }
}
