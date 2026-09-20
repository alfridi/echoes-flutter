import '../../core/auth/auth_controller.dart';

export '../../core/auth/auth_controller.dart';

/// Authentication Cubit extending [AuthController] to manage Supabase user sessions,
/// API token exchange, secure FlutterSecureStorage persistence, and route protection.
class AuthCubit extends AuthController {
  AuthCubit({
    super.supabase,
    super.secureStorage,
    super.apiClient,
    super.authRepository,
  });
}
