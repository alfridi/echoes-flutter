import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../shared_widgets/echoes_emblem.dart';

enum AuthMode { signIn, signUp }

/// Login and registration screen for Echoes Living Dialect Archive.
/// Integrates with Supabase Auth for custodians and anonymous dialect explorers.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  AuthMode _mode = AuthMode.signIn;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dialectController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _dialectController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    if (_mode != mode) {
      setState(() {
        _mode = mode;
      });
      _animController.reset();
      _animController.forward();
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<AuthCubit>();
    if (_mode == AuthMode.signIn) {
      cubit.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      cubit.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        nativeDialect: _dialectController.text.trim().isNotEmpty
            ? _dialectController.text.trim()
            : null,
      );
    }
  }

  void _continueAsGuest() {
    context.read<AuthCubit>().signInAnonymously();
  }

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(text: _emailController.text);
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
          title: Text(
            'Recover Archival Passphrase',
            style: AppTypography.headlineSm.copyWith(color: AppColors.primary),
          ),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the email address registered with your Echo Keeper account. We will send a secure link to reset your passphrase.',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyMd,
                  decoration: const InputDecoration(
                    labelText: 'Archival Email',
                    hintText: 'custodian@echoes.org',
                    prefixIcon: Icon(Icons.alternate_email, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.labelLg.copyWith(color: AppColors.outline),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  final email = resetEmailController.text.trim();
                  Navigator.of(dialogContext).pop();
                  context.read<AuthCubit>().resetPassword(email);
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, EchoesAuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          final name = state.profile.displayName;
          final isGuest = state.isAnonymous;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primaryContainer,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
              content: Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.primaryFixed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isGuest
                          ? 'Welcome, Guest Dialect Explorer!'
                          : 'Welcome back, Custodian $name!',
                      style: AppTypography.labelLg.copyWith(color: AppColors.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          );
          // Navigate to explore screen
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/explore');
          }
        } else if (state is AuthPasswordResetSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
              content: Row(
                children: [
                  const Icon(Icons.mark_email_read, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Passphrase reset link sent to ${state.email}.',
                      style: AppTypography.labelLg.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top header with Back Button & Seal Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (context.canPop())
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.arrow_back),
                              tooltip: 'Back',
                            )
                          else
                            const SizedBox(width: 48),

                          // Living Audio Archive Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer.withValues(alpha: 0.15),
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
                                Text(
                                  'CUSTODIAN ACCESS',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.secondary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Archival Card Container
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppRadii.xl,
                          boxShadow: AppShadows.paperCard,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Pulsing Brand Emblem
                              const Center(
                                child: EchoesEmblemWidget(size: 76),
                              ),
                              const SizedBox(height: 16),

                              // Editorial Header
                              Text(
                                'ECHOES',
                                textAlign: TextAlign.center,
                                style: AppTypography.headlineLg.copyWith(
                                  letterSpacing: 3.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _mode == AuthMode.signIn
                                    ? '“Return to your dialect expeditions.”'
                                    : '“Preserve your heritage for future generations.”',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMd.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Mode Switcher (Segmented Tab Bar)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainerHighest,
                                  borderRadius: AppRadii.md,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildSegmentButton(
                                        title: 'Sign In',
                                        isSelected: _mode == AuthMode.signIn,
                                        onTap: () => _switchMode(AuthMode.signIn),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildSegmentButton(
                                        title: 'Join Archive',
                                        isSelected: _mode == AuthMode.signUp,
                                        onTap: () => _switchMode(AuthMode.signUp),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Error Banner
                              if (state is AuthError) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: AppRadii.md,
                                    border: Border.all(
                                      color: AppColors.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppColors.onErrorContainer,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.message,
                                          style: AppTypography.bodySm.copyWith(
                                            color: AppColors.onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Success Sign Up Banner
                              if (state is AuthSignUpSuccess) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryFixed.withValues(alpha: 0.3),
                                    borderRadius: AppRadii.md,
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.mark_email_read_outlined,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.message,
                                          style: AppTypography.bodySm.copyWith(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Form Fields with fade transition
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (_mode == AuthMode.signUp) ...[
                                      TextFormField(
                                        controller: _nameController,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        style: AppTypography.bodyMd,
                                        decoration: const InputDecoration(
                                          labelText: 'Custodian Full Name',
                                          hintText: 'e.g., Alistair MacLeod',
                                          prefixIcon: Icon(
                                            Icons.person_outline,
                                            size: 20,
                                          ),
                                        ),
                                        validator: (val) {
                                          if (_mode == AuthMode.signUp &&
                                              (val == null || val.trim().isEmpty)) {
                                            return 'Please enter your custodian name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _dialectController,
                                        style: AppTypography.bodyMd,
                                        decoration: const InputDecoration(
                                          labelText: 'Mother Tongue / Dialect Heritage',
                                          hintText: 'e.g., Scottish Gaelic, Malayalam',
                                          prefixIcon: Icon(
                                            Icons.record_voice_over_outlined,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // Email Field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      style: AppTypography.bodyMd,
                                      decoration: const InputDecoration(
                                        labelText: 'Archival Email',
                                        hintText: 'custodian@echoes.org',
                                        prefixIcon: Icon(
                                          Icons.alternate_email,
                                          size: 20,
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!val.contains('@') || !val.contains('.')) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Password Field
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: AppTypography.bodyMd,
                                      decoration: InputDecoration(
                                        labelText: _mode == AuthMode.signIn
                                            ? 'Secret Passphrase'
                                            : 'Create Secret Passphrase',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.isEmpty) {
                                          return 'Please enter your passphrase';
                                        }
                                        if (val.length < 6) {
                                          return 'Passphrase must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Forgot password link in Sign In mode
                              if (_mode == AuthMode.signIn) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: Text(
                                      'Forgot secret passphrase?',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.secondary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 16),
                              ],

                              const SizedBox(height: 12),

                              // Submit Primary Button
                              ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppColors.primaryContainer,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _mode == AuthMode.signIn
                                                ? Icons.login
                                                : Icons.badge_outlined,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _mode == AuthMode.signIn
                                                ? 'Sign In as Custodian'
                                                : 'Register Echo Keeper Account',
                                            style: AppTypography.labelLg.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 18),

                              // Divider with text
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: AppColors.outlineVariant),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'OR DISCOVER ANONYMOUSLY',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.outline,
                                        fontSize: 10,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: AppColors.outlineVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Guest Explorer Button
                              OutlinedButton.icon(
                                onPressed: isLoading ? null : _continueAsGuest,
                                icon: const Icon(
                                  Icons.explore_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                label: Text(
                                  'Continue as Guest Explorer',
                                  style: AppTypography.labelLg.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceContainer,
                                  side: BorderSide.none,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadii.md,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Archival Trust Footer Note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 15,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Powered by Supabase Auth with Row-Level Security',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 12,
                                color: AppColors.outline,
                              ),
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
      },
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: AppRadii.sm,
          boxShadow: isSelected ? AppShadows.paperCard : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.labelLg.copyWith(
            color: isSelected ? AppColors.primary : AppColors.outline,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
