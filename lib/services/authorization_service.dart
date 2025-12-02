import 'package:safe_allergy/config/auth_config.dart';
import 'package:safe_allergy/utils/logger.dart';
import 'package:safe_allergy/utils/validators.dart';

class AuthorizationService {
  AuthorizationService._();

  static final AuthorizationService _instance = AuthorizationService._();
  static AuthorizationService get instance => _instance;

  Future<bool> checkAuthorization(String email) async {
    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      await Logger.logAudit(
        'AUTHORIZATION_CHECK',
        email,
        'FAILED',
        details: 'Invalid email format',
      );
      return false;
    }

    final isAuthorized = AuthConfig.isAuthorized(email);

    await Logger.logAudit(
      'AUTHORIZATION_CHECK',
      email,
      isAuthorized ? 'SUCCESS' : 'FAILED',
    );

    return isAuthorized;
  }

  int getAuthorizedCount() {
    return AuthConfig.authorizedCount;
  }
}
