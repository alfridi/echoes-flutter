import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../cubits/audio_player/audio_player_cubit.dart';
import '../../../../cubits/audio_player/audio_player_state.dart';
import '../../../../models/language.dart';
import '../../../../models/word_entry.dart';
import '../../../../shared_widgets/tactile_waveform.dart';

/// Featured Echo of the Day card with playable audio waveform preview.
class FeaturedEchoCard extends StatelessWidget {
  final WordEntry word;
  final Language? language;
  final VoidCallback onDetailsTap;

  const FeaturedEchoCard({
    super.key,
    required this.word,
    this.language,
    required this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioPlayerCubit, AudioPlaybackState>(
      builder: (context, audioState) {
        final audioCubit = context.read<AudioPlayerCubit>();
        final isPlayingThisTrack =
            audioState.activeTrackId == word.id && audioState.isPlaying;

        final langName = language?.name ?? 'Malayalam';
        final countryEmoji = language?.countryEmoji ?? '🇮🇳';
        final branch = language?.branch.isNotEmpty == true
            ? language!.branch
            : 'Heritage';

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadii.xl,
            boxShadow: AppShadows.floatingSheet,
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Featured Header Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryFixed,
                        borderRadius: AppRadii.full,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.graphic_eq,
                            size: 14,
                            color: AppColors.onSecondaryFixed,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'FEATURED ECHO OF THE DAY',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSecondaryFixed,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Selection',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Language & Native Word Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              countryEmoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              langName,
                              style: AppTypography.headlineSm.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.tertiaryFixed,
                                borderRadius: AppRadii.sm,
                              ),
                              child: Text(
                                branch,
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              word.englishWord,
                              style: AppTypography.displayLgMobile,
                            ),
                            Text(
                              word.nativeScript,
                              style: AppTypography.headlineMd.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        if (word.transliteration.isNotEmpty)
                          Text(
                            '(${word.transliteration})',
                            style: AppTypography.bodySm.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Play Button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isPlayingThisTrack
                          ? AppColors.secondary
                          : AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadii.lg,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      audioCubit.playTrack(
                        audioUrl: word.sampleAudioUrl,
                        trackId: word.id,
                      );
                    },
                    icon: Icon(
                      isPlayingThisTrack ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(
                      isPlayingThisTrack ? 'Playing' : 'Listen',
                      style: AppTypography.labelMd.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Acoustic Waveform visualization groove
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest.withValues(alpha: 0.7),
                  borderRadius: AppRadii.lg,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Acoustic Waveform',
                            style: AppTypography.labelSm,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '48 kHz · Lossless Archival Audio',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TactileWaveformWidget(
                      isPlaying: isPlayingThisTrack,
                      height: 32,
                      barCount: 28,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 4. Contributor attribution & Details CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: word.contributorAvatarUrl.isNotEmpty
                              ? NetworkImage(word.contributorAvatarUrl)
                              : null,
                          child: word.contributorAvatarUrl.isEmpty
                              ? const Icon(Icons.person, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recorded by ${word.contributorName}',
                            style: AppTypography.bodySm,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDetailsTap,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      'Explore Word',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
