import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../cubits/audio_player/audio_player_cubit.dart';
import '../../cubits/audio_player/audio_player_state.dart';
import '../../models/echo_recording.dart';
import '../../models/word_entry.dart';
import '../../repositories/recording_repository.dart';
import '../../repositories/word_repository.dart';
import '../../shared_widgets/tactile_waveform.dart';

/// Screen 4: Word Detail & Acoustic Player Screen.
/// Plays archival recording with scrubbable waveform, phonetic slow-motion (0.8x/1.0x),
/// and displays community echoes from echo_recordings table.
class WordDetailScreen extends StatefulWidget {
  final String wordId;

  const WordDetailScreen({super.key, required this.wordId});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  WordEntry? _word;
  List<EchoRecording> _communityRecordings = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadWordData();
  }

  Future<void> _loadWordData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wordRepo = context.read<WordRepository>();
      final recordingRepo = context.read<RecordingRepository>();

      final wordFuture = wordRepo.getWordDetail(widget.wordId);
      final recordingsFuture = recordingRepo.getRecordingsForWord(widget.wordId);

      final results = await Future.wait([wordFuture, recordingsFuture]);

      if (mounted) {
        setState(() {
          _word = results[0] as WordEntry;
          _communityRecordings = results[1] as List<EchoRecording>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WORD DETAIL',
              style: AppTypography.labelSm.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            Text(
              _word?.englishWord ?? 'Word Detail',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Archival link copied to clipboard')),
              );
            },
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.secondary : null,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null || _word == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                "Failed to load word entry",
                style: AppTypography.headlineSm,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Word not found',
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadWordData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final word = _word!;

    return BlocBuilder<AudioPlayerCubit, AudioPlaybackState>(
      builder: (context, audioState) {
        final audioCubit = context.read<AudioPlayerCubit>();
        final isArchivalPlaying =
            audioState.activeTrackId == word.id && audioState.isPlaying;
        final isSlowSpeed = audioState.playbackSpeed < 1.0;
        final isLooping = audioState.isLooping;

        // Calculate progress for scrubber
        final isArchivalActive = audioState.activeTrackId == word.id;
        final currentPosition =
            isArchivalActive ? audioState.currentPosition : Duration.zero;
        final totalDuration = isArchivalActive &&
                audioState.totalDuration.inMilliseconds > 0
            ? audioState.totalDuration
            : word.duration;
        final progress = totalDuration.inMilliseconds > 0
            ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Classification & Language ID Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: AppRadii.full,
                    ),
                    child: Text(
                      word.category.toUpperCase(),
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed.withValues(alpha: 0.5),
                      borderRadius: AppRadii.full,
                    ),
                    child: Text(
                      'ARCHIVE #${word.id.toUpperCase()}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Hero Section: English word, Native script, /transliteration/, IPA pronunciation
              Text(
                word.englishWord,
                style: AppTypography.displayLgMobile,
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    word.nativeScript,
                    style: AppTypography.headlineLg.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (word.transliteration.isNotEmpty)
                    Text(
                      '/${word.transliteration}/',
                      style: AppTypography.bodyMd.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              if (word.phoneticIpa.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppRadii.sm,
                  ),
                  child: Text(
                    word.phoneticIpa,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 3. Cultural Origin: cultural_etymology & origin_territory
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
                      children: [
                        const Icon(
                          Icons.auto_stories,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cultural origin',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word.culturalEtymology,
                      style: AppTypography.bodyMd.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: AppColors.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Origin territory: ${word.originTerritory}',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.outline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Archival Audio Player using AudioPlayerCubit and TactileWaveformWidget
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: AppRadii.xl,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.graphic_eq,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'ARCHIVAL MASTER RECORDING',
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
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: AppRadii.full,
                          ),
                          child: Text(
                            audioState.status == AudioPlayerStatus.loading &&
                                    isArchivalActive
                                ? 'Streaming...'
                                : '48 kHz Lossless',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Waveform Centerpiece
                    TactileWaveformWidget(
                      isPlaying: isArchivalPlaying,
                      height: 72,
                      barCount: 28,
                    ),
                    const SizedBox(height: 14),

                    // Seeking Scrubber Slider
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
                          final seekMs = (v * totalDuration.inMilliseconds).toInt();
                          audioCubit.seek(Duration(milliseconds: seekMs));
                        },
                      ),
                    ),

                    // Formatted Duration Display: 00:00 ━━━━━━━━━ 00:03
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(currentPosition),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDuration(totalDuration),
                          style: AppTypography.labelSm,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Player Controls Deck: 0.8x/1.0x Speed, Master Play/Pause, Loop
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Speed toggle
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: isSlowSpeed
                                ? AppColors.primaryFixed
                                : AppColors.surfaceContainerLow,
                            foregroundColor: isSlowSpeed
                                ? AppColors.onPrimaryFixed
                                : AppColors.onSurface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadii.full,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: audioCubit.togglePhoneticSpeed,
                          icon: const Icon(Icons.speed, size: 16),
                          label: Text(
                            isSlowSpeed ? '0.8x Slow' : '1.0x',
                            style: AppTypography.labelMd,
                          ),
                        ),

                        // Master Play / Pause Button ▶ / ❚❚
                        GestureDetector(
                          onTap: () {
                            audioCubit.playTrack(
                              audioUrl: word.sampleAudioUrl,
                              trackId: word.id,
                            );
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              isArchivalPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 34,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Loop toggle
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isLooping
                                ? AppColors.secondaryFixed
                                : AppColors.surfaceContainerLow,
                          ),
                          onPressed: audioCubit.toggleLoop,
                          icon: Icon(
                            Icons.repeat,
                            color: isLooping
                                ? AppColors.secondary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Community Recordings Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Community Echoes',
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_communityRecordings.length} Recordings',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_communityRecordings.isEmpty) ...[
                // Empty state
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.lg,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.mic_none,
                        size: 36,
                        color: AppColors.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No community echoes yet.',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first voice preserved for this word.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // List of Community Recordings
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _communityRecordings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final rec = _communityRecordings[index];
                    final isPlayingThisRec =
                        audioState.activeTrackId == rec.id &&
                            audioState.isPlaying;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppRadii.lg,
                        boxShadow: AppShadows.paperCard,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: rec.contributorAvatarUrl.isNotEmpty
                                ? NetworkImage(rec.contributorAvatarUrl)
                                : null,
                            child: rec.contributorAvatarUrl.isEmpty
                                ? const Icon(Icons.person, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rec.contributorName,
                                        style: AppTypography.labelLg,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: AppColors.surfaceContainerHigh,
                                          borderRadius: AppRadii.sm,
                                        ),
                                        child: Text(
                                          rec.acousticFidelity,
                                          style: AppTypography.labelSm.copyWith(
                                            color: AppColors.primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rec.accentTerritory,
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(rec.duration),
                                      style: AppTypography.labelSm.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        DateFormat('MMM d, yyyy')
                                            .format(rec.createdAt),
                                        style: AppTypography.labelSm.copyWith(
                                          color: AppColors.outline,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.thumb_up_outlined,
                                      size: 13,
                                      color: AppColors.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${rec.upvotesCount}',
                                      style: AppTypography.labelSm,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: isPlayingThisRec
                                  ? AppColors.secondary
                                  : AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                            ),
                            onPressed: () {
                              audioCubit.playTrack(
                                audioUrl: rec.audioUrl,
                                trackId: rec.id,
                              );
                            },
                            icon: Icon(
                              isPlayingThisRec
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),

              // 6. CTA: Record an Echo Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.push(
                      '/record?wordId=${word.id}&languageId=${word.languageId}',
                    );
                    // Refresh recordings when returning from recording expedition
                    _loadWordData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: AppColors.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.mic, size: 22),
                  label: const Text(
                    'Record an Echo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
