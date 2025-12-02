import 'dart:convert';
import 'package:equatable/equatable.dart';

class Patient extends Equatable {
  final String fullName;

  final String medicalFileNumber;

  final String department;

  final List<String> allergies;

  final String emergencyContact;

  final String emergencyNumber;

  final String hospitalName;

  const Patient({
    required this.fullName,
    required this.medicalFileNumber,
    required this.department,
    required this.allergies,
    required this.emergencyContact,
    required this.emergencyNumber,
    required this.hospitalName,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      fullName: json['fullName'] as String,
      medicalFileNumber: json['medicalFileNumber'] as String,
      department: json['department'] as String,
      allergies: List<String>.from(json['allergies'] as List),
      emergencyContact: json['emergencyContact'] as String,
      emergencyNumber: json['emergencyNumber'] as String,
      hospitalName: json['hospitalName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'medicalFileNumber': medicalFileNumber,
      'department': department,
      'allergies': allergies,
      'emergencyContact': emergencyContact,
      'emergencyNumber': emergencyNumber,
      'hospitalName': hospitalName,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory Patient.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Patient.fromJson(json);
  }

  Patient copyWith({
    String? fullName,
    String? medicalFileNumber,
    String? department,
    List<String>? allergies,
    String? emergencyContact,
    String? emergencyNumber,
    String? hospitalName,
  }) {
    return Patient(
      fullName: fullName ?? this.fullName,
      medicalFileNumber: medicalFileNumber ?? this.medicalFileNumber,
      department: department ?? this.department,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyNumber: emergencyNumber ?? this.emergencyNumber,
      hospitalName: hospitalName ?? this.hospitalName,
    );
  }

  @override
  List<Object?> get props => [
    fullName,
    medicalFileNumber,
    department,
    allergies,
    emergencyContact,
    emergencyNumber,
    hospitalName,
  ];

  @override
  String toString() {
    return 'Patient(fullName: $fullName, medicalFileNumber: $medicalFileNumber, '
        'department: $department, allergies: $allergies, '
        'emergencyContact: $emergencyContact, emergencyNumber: $emergencyNumber, '
        'hospitalName: $hospitalName)';
  }
}
