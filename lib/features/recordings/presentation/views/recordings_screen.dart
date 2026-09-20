import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/recording.dart';
import '../../domain/repositories/recording_repository.dart';
import '../viewmodels/recording_viewmodel.dart';
import '../widgets/recording_player.dart';

/// Screen presenting the user's preserved voice recordings retrieved from Supabase.
/// Allows streaming playback of archived audio directly from Supabase Storage.
class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  late final RecordingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RecordingViewModel(
      repository: getIt<RecordingRepository>(),
    );
    _viewModel.loadRecordings();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Recording recording) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text(
          'This will permanently delete this audio recording from Supabase Storage and database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _viewModel.deleteRemoteRecording(recording);
    }
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
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOICE ARCHIVE',
                  style: AppTypography.labelSm.copyWith(
                    letterSpacing: 1.5,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'My Recordings',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh Recordings',
                icon: const Icon(Icons.refresh),
                onPressed: _viewModel.loadRecordings,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildBody(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await context.push('/record');
              _viewModel.loadRecordings();
            },
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            icon: const Icon(Icons.mic),
            label: const Text('New Recording'),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoadingRecordings && _viewModel.recordings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Retrieving recordings from Supabase...'),
          ],
        ),
      );
    }

    if (_viewModel.errorMessage != null && _viewModel.recordings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load recordings',
                style: AppTypography.headlineSm,
              ),
              const SizedBox(height: 8),
              Text(
                _viewModel.errorMessage!,
                style: AppTypography.bodySm.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _viewModel.loadRecordings,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewModel.recordings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                ),
                child: const Icon(
                  Icons.mic_none,
                  size: 36,
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No recordings preserved yet',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Record your first dialect echo and archive it safely into Supabase.',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/record');
                  _viewModel.loadRecordings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.mic),
                label: const Text('Start First Recording'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _viewModel.loadRecordings,
      color: AppColors.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: _viewModel.recordings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final rec = _viewModel.recordings[index];
              final isActive = _viewModel.activeTrackId == rec.id;
              final isPlaying = isActive && _viewModel.isPlaying;

              return RecordingPlayer(
                recording: rec,
                isActive: isActive,
                isPlaying: isPlaying,
                currentPosition: isActive
                    ? _viewModel.playbackPosition
                    : Duration.zero,
                totalDuration: isActive
                    ? _viewModel.playbackDuration
                    : Duration(seconds: rec.durationSeconds ?? 0),
                onPlayPause: () => _viewModel.playRemoteRecording(rec),
                onSeek: isActive ? _viewModel.seekPlayback : null,
                onDelete: () => _confirmDelete(rec),
              );
            },
          ),
        ),
      ),
    );
  }
}
