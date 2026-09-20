import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../shared_widgets/echoes_emblem.dart';

/// Screen 1: Onboarding screen introducing the living audio archive.
/// Implements design and layout from FLUTTER_IMPLEMENTATION 2.md.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isPlayingSample = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Seal & Archival Paper Card
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppRadii.xl,
                      boxShadow: AppShadows.paperCard,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withValues(alpha: 0.2),
                            borderRadius: AppRadii.full,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'LIVING AUDIO ARCHIVE',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.secondary,
                                    letterSpacing: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Pulsing Brand Emblem
                        const EchoesEmblemWidget(size: 112),
                        const SizedBox(height: 24),
                        // Title & Motto
                        Text(
                          'ECHOES',
                          style: AppTypography.headlineLg.copyWith(
                            letterSpacing: 3.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '“Every voice carries a story.”',
                          style: AppTypography.bodyMd.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'A living acoustic archive dedicated to preserving endangered languages, vernacular dialects, and cultural memory through the authentic voices of native speakers.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm.copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 18),
                        // Core Purpose Pillars: Preserve Voices, Explore Dialects, Contribute Recordings
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.8),
                            borderRadius: AppRadii.lg,
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildPillarRow(
                                Icons.mic_external_on,
                                'Preserve Voices',
                                'Safeguard oral heritage with pristine lossless recordings.',
                              ),
                              const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                              _buildPillarRow(
                                Icons.public,
                                'Explore Dialects',
                                'Navigate living cartography across continents and indigenous roots.',
                              ),
                              const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                              _buildPillarRow(
                                Icons.record_voice_over,
                                'Contribute Recordings',
                                'Add your unique accent and vernacular cadence to history.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Counter Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: AppRadii.full,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mic, size: 18, color: AppColors.secondary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '14,280 living voices preserved across 89 regions',
                                  style: AppTypography.labelMd,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Metric Grid (3 cols)
                  Row(
                    children: [
                      _buildMetricTile(Icons.public, 'Global Scope', '89', AppColors.primaryContainer),
                      const SizedBox(width: 10),
                      _buildMetricTile(Icons.graphic_eq, 'Dialects', '420+', AppColors.secondary),
                      const SizedBox(width: 10),
                      _buildMetricTile(Icons.auto_stories, 'Folktales', '3.1k', AppColors.primaryContainer),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Daily Acoustic Tapestry Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppRadii.lg,
                      boxShadow: AppShadows.paperCard,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hearing, color: AppColors.secondary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DAILY ACOUSTIC TAPESTRY',
                                style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Gaelic Lullaby of Barra',
                                style: AppTypography.headlineSm,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Outer Hebrides • 01:42',
                                style: AppTypography.bodySm,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: AppColors.onPrimary,
                          ),
                          onPressed: () => setState(() => isPlayingSample = !isPlayingSample),
                          icon: Icon(isPlayingSample ? Icons.pause : Icons.play_arrow),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Primary CTA: Explore the Atlas navigating to /world-map (if authenticated) or /login
                  ElevatedButton.icon(
                    onPressed: () {
                      try {
                        final auth = context.read<AuthCubit>();
                        if (auth.state.isAuthenticated) {
                          context.go('/world-map');
                          return;
                        }
                      } catch (_) {}
                      context.go('/login');
                    },
                    label: const Text('Explore the Atlas'),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/login'),
                    icon: const Icon(Icons.record_voice_over, size: 18, color: AppColors.primary),
                    label: Text(
                      'Already an Echo Keeper? Sign In',
                      style: AppTypography.labelLg.copyWith(color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainer,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Curated by phonetic linguists & native heritage speakers',
                          style: AppTypography.bodySm,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String label, String value, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.md,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppTypography.headlineSm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.12),
            borderRadius: AppRadii.sm,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
