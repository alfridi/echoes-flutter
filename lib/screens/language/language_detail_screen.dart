import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../cubits/audio_player/audio_player_cubit.dart';
import '../../cubits/audio_player/audio_player_state.dart';
import '../../models/language.dart';
import '../../models/word_entry.dart';
import '../../repositories/language_repository.dart';
import '../../repositories/word_repository.dart';
import '../../shared_widgets/avatar_stack.dart';
import '../../shared_widgets/tactile_waveform.dart';

/// Screen 3: Language Detail screen displaying dialect catalog metadata,
/// preserved voices count, summary, and words loaded from Supabase.
class LanguageDetailScreen extends StatefulWidget {
  final String languageId;

  const LanguageDetailScreen({
    super.key,
    required this.languageId,
  });

  @override
  State<LanguageDetailScreen> createState() => _LanguageDetailScreenState();
}

class _LanguageDetailScreenState extends State<LanguageDetailScreen> {
  Language? _language;
  List<WordEntry> _words = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLanguageData();
  }

  Future<void> _loadLanguageData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final languageRepo = context.read<LanguageRepository>();
      final wordRepo = context.read<WordRepository>();

      final languageFuture = languageRepo.getLanguageById(widget.languageId);
      final wordsFuture = wordRepo.getWordsForLanguage(widget.languageId);

      final results = await Future.wait([languageFuture, wordsFuture]);

      if (mounted) {
        setState(() {
          _language = results[0] as Language;
          _words = results[1] as List<WordEntry>;
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
              'LANGUAGE',
              style: AppTypography.labelSm.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            Text(
              _language?.name ?? 'Language Detail',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
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

    if (_errorMessage != null || _language == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                "Failed to load language details",
                style: AppTypography.headlineSm,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Language not found',
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadLanguageData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final language = _language!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Classification & Region Breadcrumb
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text('Back to Atlas', style: AppTypography.labelMd),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLow,
                  side: BorderSide.none,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.full,
                  ),
                ),
              ),
              Container(
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
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${language.branch.toUpperCase()} BRANCH',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSecondaryFixed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Hero Section
          Row(
            children: [
              Text(language.countryEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                language.region.toUpperCase(),
                style: AppTypography.labelMd.copyWith(
                  letterSpacing: 1.1,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(language.name, style: AppTypography.headlineLg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: AppRadii.sm,
                ),
                child: Text(
                  'ISO 639-3: ${language.isoCode}',
                  style: AppTypography.labelSm.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          if (language.nativeScript.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              language.nativeScript,
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Language summary
          Text(
            language.summary,
            style: AppTypography.bodyMd.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),

          // 3. Contributor & Preservation Metric Strip (from Supabase values)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadii.lg,
              boxShadow: AppShadows.paperCard,
            ),
            child: Row(
              children: [
                AvatarStackWidget(
                  countText: '+${language.preservedPeopleCount}',
                  avatarUrls: language.contributorAvatarUrls,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preserved voices: ${language.preservedPeopleCount}',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Verified echoes: ${language.verifiedAudioCount}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.verified,
                  size: 22,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Divider
          Row(
            children: [
              const Expanded(
                child: Divider(
                  color: AppColors.surfaceContainerHighest,
                  thickness: 1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Divider(
                  color: AppColors.surfaceContainerHighest,
                  thickness: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Words & Expressions Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Words & Expressions',
                    style: AppTypography.headlineSm.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Listen to authentic pronunciations recorded by native custodians',
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: AppRadii.sm,
                ),
                child: Text(
                  '${_words.length} ROOTS',
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Word Cards list
          if (_words.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No preserved words found yet for this language.',
                  style: AppTypography.bodyMd,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _words.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final word = _words[index];
                return _buildWordCard(word);
              },
            ),

          const SizedBox(height: 24),

          // 5. Oral Preservation Drive Invitation Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadii.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: AppRadii.full,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mic,
                        size: 14,
                        color: AppColors.tertiaryFixed,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ORAL PRESERVATION DRIVE',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.tertiaryFixed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Know this tongue? Add your voice to ${language.name}\'s living heritage.',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Record everyday idioms, pronunciations, or regional accents. Your echo stays preserved for future generations.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.tertiaryFixedDim,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryContainer,
                      foregroundColor: AppColors.onSecondaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final firstWordId =
                          _words.isNotEmpty ? _words.first.id : 'welcome';
                      context.push(
                        '/record?wordId=$firstWordId&languageId=${language.id}',
                      );
                    },
                    icon: const Icon(Icons.mic),
                    label: Text('Record an Echo for ${language.name}'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWordCard(WordEntry word) {
    return BlocBuilder<AudioPlayerCubit, AudioPlaybackState>(
      builder: (context, audioState) {
        final audioCubit = context.read<AudioPlayerCubit>();
        final isPlayingThisTrack =
            audioState.activeTrackId == word.id && audioState.isPlaying;

        return GestureDetector(
          onTap: () => context.push('/word/${word.id}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadii.lg,
              boxShadow: AppShadows.paperCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Recordings Count Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      word.category.toUpperCase(),
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: AppRadii.full,
                      ),
                      child: Text(
                        '${word.availableRecordingsCount} recordings',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // English Word
                Text(word.englishWord, style: AppTypography.headlineMd),
                const SizedBox(height: 8),

                // Native Script & Transliteration Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppRadii.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.nativeScript,
                              style: AppTypography.headlineLg.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            if (word.transliteration.isNotEmpty)
                              Text(
                                word.transliteration,
                                style: AppTypography.labelMd,
                              ),
                          ],
                        ),
                      ),
                      if (word.phoneticIpa.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: AppRadii.sm,
                          ),
                          child: Text(
                            word.phoneticIpa,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Tactile Waveform
                TactileWaveformWidget(
                  isPlaying: isPlayingThisTrack,
                  height: 24,
                  barCount: 22,
                ),
                const SizedBox(height: 12),

                // Contributor Attribution, Duration & Play Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Archived by ${word.contributorName}',
                              style: AppTypography.labelSm,
                            ),
                            Text(
                              'Duration: ${_formatDuration(word.duration)}',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isPlayingThisTrack
                            ? AppColors.secondary
                            : AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.md,
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
                        size: 16,
                      ),
                      label: Text(isPlayingThisTrack ? 'Pause' : 'Listen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
