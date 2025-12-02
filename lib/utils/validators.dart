import 'package:safe_allergy/utils/constants.dart';

class Validators {
  Validators._();

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    final trimmedEmail = email.trim();
    if (!AppConstants.emailRegex.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validateFullName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Full name is required';
    }

    if (name.trim().length > AppConstants.maxNameLength) {
      return 'Name must be less than ${AppConstants.maxNameLength} characters';
    }

    return null;
  }

  static String? validateMedicalFileNumber(String? number) {
    if (number == null || number.trim().isEmpty) {
      return 'Medical file number is required';
    }

    final trimmedNumber = number.trim();
    if (trimmedNumber.length < AppConstants.minMedicalFileNumberLength) {
      return 'Medical file number must be at least ${AppConstants.minMedicalFileNumberLength} characters';
    }

    if (trimmedNumber.length > AppConstants.maxMedicalFileNumberLength) {
      return 'Medical file number must be less than ${AppConstants.maxMedicalFileNumberLength} characters';
    }

    if (!AppConstants.medicalFileNumberRegex.hasMatch(trimmedNumber)) {
      return 'Medical file number contains invalid characters';
    }

    return null;
  }

  static String? validateDepartment(String? department) {
    if (department == null || department.trim().isEmpty) {
      return 'Department is required';
    }

    if (department.trim().length > AppConstants.maxDepartmentLength) {
      return 'Department must be less than ${AppConstants.maxDepartmentLength} characters';
    }

    return null;
  }

  static String? validateEmergencyContact(String? contact) {
    if (contact == null || contact.trim().isEmpty) {
      return 'Emergency contact is required';
    }

    if (contact.trim().length > AppConstants.maxEmergencyContactLength) {
      return 'Emergency contact must be less than ${AppConstants.maxEmergencyContactLength} characters';
    }

    return null;
  }

  static String? validateEmergencyNumber(String? number) {
    if (number == null || number.trim().isEmpty) {
      return 'Emergency number is required';
    }

    return null;
  }

  static String? validateHospitalName(String? hospital) {
    if (hospital == null || hospital.trim().isEmpty) {
      return 'Hospital name is required';
    }

    if (hospital.trim().length > AppConstants.maxHospitalNameLength) {
      return 'Hospital name must be less than ${AppConstants.maxHospitalNameLength} characters';
    }

    return null;
  }

  static String? validateAllergies(List<String>? allergies) {
    if (allergies == null || allergies.isEmpty) {
      return 'At least one allergy must be selected (select "None" if no allergies)';
    }

    if (allergies.length == 1 && allergies.first == 'None') {
      return null;
    }

    if (allergies.contains('None') && allergies.length > 1) {
      return 'Cannot select "None" with other allergies';
    }

    return null;
  }
}
