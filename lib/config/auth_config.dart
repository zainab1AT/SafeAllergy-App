
class AuthConfig {
  AuthConfig._();

  static const List<String> authorizedEmails = [
    'engzainabatwa1@gmail.com',
    'nurse2@hospital.com',
    'paramedic1@hospital.com',
    'paramedic2@hospital.com',
    'admin@hospital.com',
  ];

  static bool isAuthorized(String email) {
    if (email.isEmpty) {
      return false;
    }

    final normalizedEmail = email.trim().toLowerCase();
    return authorizedEmails.any(
      (authorizedEmail) => authorizedEmail.toLowerCase() == normalizedEmail,
    );
  }

  static int get authorizedCount => authorizedEmails.length;
}
