

import '../utils/logger.dart';
import '../utils/validators.dart';
import 'firebase_service.dart';

class AuthorizationService {
  AuthorizationService._();

  static final AuthorizationService _instance = AuthorizationService._();
  static AuthorizationService get instance => _instance;

  String? _currentAuthorizedEmail;

  String? get currentAuthorizedEmail => _currentAuthorizedEmail;

  void setCurrentAuthorizedEmail(String email) {
    _currentAuthorizedEmail = email;
  }

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

    final normalizedEmail = email.trim().toLowerCase();
    final isAuthorized =
        await FirebaseService.instance.isEmailAuthorized(normalizedEmail);

    await Logger.logAudit(
      'AUTHORIZATION_CHECK',
      normalizedEmail,
      isAuthorized ? 'SUCCESS' : 'FAILED',
    );

    if (isAuthorized) {
      _currentAuthorizedEmail = normalizedEmail;
    }

    return isAuthorized;
  }
}

