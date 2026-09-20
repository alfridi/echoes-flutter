import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_dimensions.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../cubits/auth/auth_cubit.dart';

/// Shows a responsive confirmation popup dialog for signing out.
///
/// Prompts the user with double confirmation before ending their active session.
/// When the user confirms sign out, it triggers [signOut()] and navigates directly
/// to the sign in / login screen using [context.go('/login')].
Future<bool?> showLogoutConfirmationDialog(
  BuildContext context, {
  String? displayName,
  Future<void> Function()? onConfirmed,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final mediaQuery = MediaQuery.of(dialogContext);
      final screenWidth = mediaQuery.size.width;
      final isCompact = screenWidth < 380;

      Future<void> handleConfirm() async {
        Navigator.of(dialogContext).pop(true);
        if (onConfirmed != null) {
          await onConfirmed();
        } else {
          try {
            await context.read<AuthCubit>().signOut();
          } catch (_) {}
          if (context.mounted) {
            context.go('/login');
          }
        }
      }

      return Dialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xl),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 24,
          vertical: 24,
        ),
        elevation: 6,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 18 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Icon Badge and Seal
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONFIRM SIGN OUT',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.error,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Depart Archive?',
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Editorial Confirmation Message
                Text(
                  displayName != null && displayName.trim().isNotEmpty
                      ? 'Custodian $displayName, are you sure you wish to sign out of the Living Audio Archive? Access to protected cartography and recording expedition tools will require signing in again.'
                      : 'Are you sure you wish to sign out of the Living Audio Archive? Access to protected cartography and recording expedition tools will require signing in again.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Responsive Action Buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    final shouldStack = constraints.maxWidth < 290;

                    if (shouldStack) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: handleConfirm,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Sign Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.onError,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadii.md,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                color: AppColors.outlineVariant,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadii.md,
                              ),
                            ),
                            child: Text(
                              'Stay in Archive',
                              style: AppTypography.labelLg.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTypography.labelLg.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: handleConfirm,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.onError,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadii.md,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
