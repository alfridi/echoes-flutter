import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/repositories/recording_repository.dart';
import '../viewmodels/recording_viewmodel.dart';
import '../widgets/recording_button.dart';
import '../widgets/recording_preview.dart';

/// Screen presenting the end-to-end voice recording expedition.
/// Implements strict MVVM separation: interacts solely through [RecordingViewModel].
class RecordingScreen extends StatefulWidget {
  final String? wordId;
  final String? languageId;

  const RecordingScreen({
    super.key,
    this.wordId,
    this.languageId,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late final RecordingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RecordingViewModel(
      repository: getIt<RecordingRepository>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _viewModel.deleteRecording();
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
            actions: [
              TextButton.icon(
                onPressed: () => context.push('/recordings'),
                icon: const Icon(Icons.library_music_outlined, size: 18),
                label: const Text('My Recordings'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // 1. Context Information Card (if word/language specified)
                      if (widget.wordId != null || widget.languageId != null)
                        _buildContextCard(),

                      // 2. Error Feedback Banner
                      if (_viewModel.errorMessage != null) ...[
                        _buildErrorCard(_viewModel.errorMessage!),
                        const SizedBox(height: 16),
                      ],

                      // 3. Success Banner (when state is Uploaded)
                      if (_viewModel.isUploaded) ...[
                        _buildSuccessCard(),
                        const SizedBox(height: 16),
                      ],

                      // 4. Main Body: Recording vs Preview vs Uploading Deck
                      if (_viewModel.isIdle || _viewModel.isRecording) ...[
                        _buildRecordingSection(),
                      ] else if (_viewModel.isRecorded || _viewModel.isUploading) ...[
                        if (_viewModel.recordedFile != null)
                          RecordingPreview(
                            file: _viewModel.recordedFile!,
                            duration: _viewModel.recordingDuration,
                            isPlaying: _viewModel.isPlaying,
                            currentPosition: _viewModel.playbackPosition,
                            totalDuration: _viewModel.playbackDuration,
                            isUploading: _viewModel.isUploading,
                            onPlayPause: _viewModel.togglePlayPausePreview,
                            onSeek: _viewModel.seekPlayback,
                            onDelete: _viewModel.deleteRecording,
                            onSubmit: _viewModel.submitRecording,
                          ),
                      ],

                      const SizedBox(height: 24),

                      // 5. Environmental Recording Guidelines
                      _buildGuidanceBox(),
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

  Widget _buildContextCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.lg,
        boxShadow: AppShadows.paperCard,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.history_edu,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PRESERVING ARCHIVE',
                      style: AppTypography.labelSm.copyWith(
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.wordId ?? 'Word Audio',
                  style: AppTypography.headlineSm,
                ),
              ],
            ),
          ),
          if (widget.languageId != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: AppRadii.full,
              ),
              child: Text(
                widget.languageId!.toUpperCase(),
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.xl,
        boxShadow: AppShadows.paperCard,
      ),
      child: RecordingButton(
        isRecording: _viewModel.isRecording,
        elapsedDuration: _viewModel.recordingDuration,
        currentAmplitude: _viewModel.currentAmplitude,
        onStart: _viewModel.startRecording,
        onStop: _viewModel.stopRecording,
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.3),
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording Notice',
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (_viewModel.recordedFile != null && !_viewModel.isRecording)
            TextButton(
              onPressed: _viewModel.retryUpload,
              child: const Text('Retry'),
            )
          else
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: _viewModel.clearError,
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.25),
        borderRadius: AppRadii.lg,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preserved to Supabase!',
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Audio file stored in Supabase Storage & database metadata cataloged.',
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  _viewModel.deleteRecording();
                },
                child: const Text('Record Another'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => context.push('/recordings'),
                icon: const Icon(Icons.library_music, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceBox() {
    return Container(
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
              Icons.lightbulb_outline,
              color: AppColors.onSecondaryFixed,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hold phone close and speak naturally. Lossless AAC (.m4a) audio will be securely archived into Supabase Storage with user-level RLS.',
              style: AppTypography.bodySm,
            ),
          ),
        ],
      ),
    );
  }
}
