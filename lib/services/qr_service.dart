import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safe_allergy/models/patient.dart';
import 'package:safe_allergy/services/encryption_service.dart';
import 'package:safe_allergy/utils/constants.dart';
import 'package:safe_allergy/utils/logger.dart';

class QrService {
  QrService._();

  static final QrService _instance = QrService._();
  static QrService get instance => _instance;
  Future<String> generateQrData(Patient patient) async {
    try {
      await Logger.logInfo('QR code generation started');

      final jsonString = patient.toJsonString();
      final encryptedData = await EncryptionService.instance.encrypt(
        jsonString,
      );

      await Logger.logInfo('QR code generation completed');
      return encryptedData;
    } catch (e) {
      await Logger.logError('QR code generation failed', error: e);
      throw QrException('Failed to generate QR code data: $e');
    }
  }

  Future<Patient> parseQrData(String qrData) async {
    try {
      await Logger.logInfo('QR code parsing started');

      if (qrData.isEmpty) {
        throw QrException('QR code data is empty');
      }

      String jsonString;
      try {
        jsonString = await EncryptionService.instance.decrypt(qrData);
      } catch (e) {
        await Logger.logWarning('QR data not encrypted, trying plain text');
        try {
          jsonString = qrData;
          jsonDecode(jsonString);
        } catch (jsonError) {
          throw QrException('Invalid QR code data format');
        }
      }

      final patient = Patient.fromJsonString(jsonString);

      await Logger.logInfo('QR code parsing completed successfully');
      return patient;
    } catch (e) {
      await Logger.logError('QR code parsing failed', error: e);
      if (e is QrException) {
        rethrow;
      }
      throw QrException('${AppConstants.errorQrScanFailed}: $e');
    }
  }

  QrImageView createQrWidget(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      padding: const EdgeInsets.all(8),
    );
  }
}

class QrException implements Exception {
  final String message;
  QrException(this.message);

  @override
  String toString() => 'QrException: $message';
}
