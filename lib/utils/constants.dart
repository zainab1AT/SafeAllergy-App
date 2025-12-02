class AppConstants {
  AppConstants._();

  static const String appName = 'SafeAllergy';

  static const String appTagline = 'Secure Emergency Patient Management';

  /// Default emergency number
  static const String defaultEmergencyNumber = '101';

  /// Maximum length for patient name
  static const int maxNameLength = 100;

  static const int maxMedicalFileNumberLength = 50;

  static const int maxDepartmentLength = 100;

  static const int maxEmergencyContactLength = 100;

  static const int maxHospitalNameLength = 100;

  static const int minMedicalFileNumberLength = 3;

  static const List<String> predefinedAllergies = [
    'Penicillin',
    'Latex',
    'Aspirin',
    'Ibuprofen',
    'Codeine',
    'Morphine',
    'Sulfa Drugs',
    'Tetracycline',
    'Erythromycin',
    'Vancomycin',
    'Insulin',
    'Contrast Dye',
    'Shellfish',
    'Peanuts',
    'Tree Nuts',
    'Eggs',
    'Milk',
    'Soy',
    'Wheat',
    'Fish',
    'Sesame',
    'Pollen',
    'Dust Mites',
    'Animal Dander',
    'Mold',
    'Nickel',
    'Fragrances',
    'None',
  ];

  static const int splashScreenDuration = 3000;

  static const int nfcReadTimeout = 30000;

  static const int nfcWriteTimeout = 30000;

  static const int qrScanTimeout = 30000;

  static const String encryptionAlgorithm = 'AES-256';

  static const String auditLogFileName = 'audit_log.txt';

  static const String errorNfcNotSupported =
      'NFC is not supported on this device';
  static const String errorNfcNotEnabled =
      'Please enable NFC in device settings';
  static const String errorNfcReadFailed = 'Failed to read NFC tag';
  static const String errorNfcWriteFailed = 'Failed to write to NFC tag';
  static const String errorQrScanFailed = 'Failed to scan QR code';
  static const String errorInvalidPatientData = 'Invalid patient data format';
  static const String errorUnauthorized =
      'You are not authorized to perform this action';
  static const String errorValidationFailed =
      'Please fill in all required fields';

  static const String successNfcRead = 'Patient data read successfully';
  static const String successNfcWrite = 'Patient data written successfully';
  static const String successQrScan = 'QR code scanned successfully';
  static const String successAuthorized = 'Authorization successful';

  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp medicalFileNumberRegex = RegExp(r'^[A-Za-z0-9\-_]+$');
}
