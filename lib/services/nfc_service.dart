import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:safe_allergy/models/patient.dart';
import 'package:safe_allergy/services/authorization_service.dart';
import 'package:safe_allergy/services/firebase_service.dart';
import 'package:safe_allergy/services/nfc_platform_adapter.dart';
import 'package:safe_allergy/utils/constants.dart';
import 'package:safe_allergy/utils/logger.dart';
import 'package:nfc_manager/ndef_record.dart' as nfc;


class NfcService {
  NfcService._internal({NfcPlatformAdapter? adapter})
      : _adapter = adapter ?? FlutterNfcPlatformAdapter();

  static final NfcService _instance = NfcService._internal();
  static NfcService get instance => _instance;

  NfcPlatformAdapter _adapter;

  @visibleForTesting
  void configureAdapter(NfcPlatformAdapter adapter) {
    _adapter = adapter;
  }

  Future<bool> isAvailable() async {
    try {
      final availability = await _adapter.getAvailability();
      return availability == NFCAvailability.available;
    } catch (e) {
      await Logger.logError('Failed to check NFC availability', error: e);
      return false;
    }
  }

  Future<Patient> readPatientData() async {
    if (!await isAvailable()) {
      throw NfcException(AppConstants.errorNfcNotSupported);
    }

    await Logger.logInfo('NFC read operation started');

    try {
      final tag = await _adapter.poll(timeout: const Duration(seconds: 20));
      final tagUid = tag.id;

      final payload = await _readPayloadWithFallbacks();

      if (payload.patient != null) {
        // Legacy tag migrated on the fly.
        await FirebaseService.instance.logAudit(
          action: 'NFC_READ_LEGACY',
          result: 'SUCCESS',
          patientDocId: payload.patient!.id,
          tagUid: tagUid,
        );
        return payload.patient!;
      }

      final documentId = payload.documentId;
      if (documentId == null || documentId.isEmpty) {
        throw NfcException('No document ID found on tag');
      }

      final patient =
          await FirebaseService.instance.getPatientById(documentId.trim());
      if (patient == null) {
        throw NfcException('No patient found for this NFC tag');
      }

      await FirebaseService.instance.logAudit(
        action: 'NFC_READ',
        result: 'SUCCESS',
        patientDocId: patient.id,
        tagUid: tagUid,
      );

      await Logger.logInfo('NFC read operation completed successfully');
      return patient;
    } catch (e) {
      await Logger.logError('NFC read operation failed', error: e);
      if (e is NfcException) rethrow;
      throw NfcException('${AppConstants.errorNfcReadFailed}: $e');
    } finally {
      await stopSession();
    }
  }

  Future<void> writePatientData(Patient patient) async {
    if (!await isAvailable()) {
      throw NfcException(AppConstants.errorNfcNotSupported);
    }

    final authService = AuthorizationService.instance;
    final actorEmail = authService.currentAuthorizedEmail;
    if (actorEmail == null || actorEmail.isEmpty) {
      throw NfcException('No authorized user found for write operation');
    }

    await Logger.logInfo('NFC write operation started');

    try {
      final documentId =
          await FirebaseService.instance.createOrUpdatePatient(patient);
      final tag = await _adapter.poll(timeout: const Duration(seconds: 20));
      final tagUid = tag.id;

      bool writeSucceeded = false;
      try {
        await _writeMifareClassicDocId(documentId);
        writeSucceeded = true;
      } catch (e) {
        await Logger.logWarning(
          'MIFARE Classic write failed, trying NDEF fallback',
          context: e.toString(),
        );
      }

      if (!writeSucceeded) {
        await _writeNdefDocId(documentId);
      }

      await FirebaseService.instance.logAudit(
        action: 'NFC_WRITE',
        result: 'SUCCESS',
        actorEmail: actorEmail,
        patientDocId: documentId,
        tagUid: tagUid,
      );

      await Logger.logInfo('NFC write completed successfully');
    } catch (e) {
      await FirebaseService.instance.logAudit(
        action: 'NFC_WRITE',
        result: 'FAILED',
        actorEmail: AuthorizationService.instance.currentAuthorizedEmail,
        details: e.toString(),
      );
      await Logger.logError('NFC write operation failed', error: e);
      if (e is NfcException) rethrow;
      throw NfcException('Failed to write to NFC tag: $e');
    } finally {
      await stopSession();
    }
  }

  Future<_TagPayload> _readPayloadWithFallbacks() async {
    try {
      final raw = await _readMifareClassicDocId();
      final normalized = await _normalizePayload(raw);
      if (normalized.hasValue) return normalized;
    } catch (e) {
      await Logger.logWarning(
        'MIFARE Classic read failed, trying NDEF fallback',
        context: e.toString(),
      );
    }

    final ndefRaw = await _readNdefDocId();
    return _normalizePayload(ndefRaw);
  }

  Future<_TagPayload> _normalizePayload(String? raw) async {
    if (raw == null || raw.isEmpty) {
      return const _TagPayload.none();
    }

    final cleaned = raw.replaceAll('\u0000', '').trim();
    if (_looksLikeJson(cleaned)) {
      try {
        final legacyPatient = Patient.fromJsonString(cleaned);
        final migratedId =
            await FirebaseService.instance.createOrUpdatePatient(legacyPatient);
        final migratedPatient = legacyPatient.copyWith(id: migratedId);
        await FirebaseService.instance.logAudit(
          action: 'LEGACY_MIGRATION',
          result: 'SUCCESS',
          patientDocId: migratedId,
          details: 'Migrated legacy NFC payload to Firestore',
        );
        return _TagPayload(patient: migratedPatient);
      } catch (e) {
        await Logger.logError('Failed to migrate legacy payload', error: e);
        throw NfcException('Legacy payload could not be migrated: $e');
      }
    }

    return _TagPayload(documentId: cleaned);
  }

  Future<String?> _readMifareClassicDocId() async {
    try {
      await _adapter.transceive('60 04 ff ff ff ff ff ff');
      final result = await _adapter.transceive('30 04');
      final bytes = _hexToBytes(result);
      final ascii = utf8.decode(bytes, allowMalformed: true);
      return ascii.trim();
    } catch (e) {
      throw NfcException('Failed to read MIFARE Classic block: $e');
    }
  }

  Future<void> _writeMifareClassicDocId(String docId) async {
    try {
      final padded = docId.padRight(16).substring(0, 16);
      final hex = _bytesToHex(utf8.encode(padded));

      await _adapter.transceive('60 04 ff ff ff ff ff ff');
      await _adapter.transceive('A0 04');
      await _adapter.transceive(hex);
    } catch (e) {
      throw NfcException('Failed to write MIFARE Classic block: $e');
    }
  }

  Future<String?> _readNdefDocId() async {
    try {
      final records = await _adapter.readNdefRecords();
      if (records.isEmpty) return null;
      final payload = records.first.payload;
      if (payload == null) return null;
      return utf8.decode(payload, allowMalformed: true).trim();
    } catch (e) {
      return null;
    }
  }

Future<void> _writeNdefDocId(String docId) async {
  try {
    // Convert your string to NdefRecord
    final record = nfc.NdefRecord(
      type: Uint8List.fromList(utf8.encode('T')), // 'T' for Text record
      identifier: Uint8List(0),                  // empty ID
      payload: Uint8List.fromList(utf8.encode(docId)),
      typeNameFormat: nfc.TypeNameFormat.wellKnown,
    );

    await _adapter.writeNdefRecords([record]);
  } catch (e) {
    throw NfcException('Failed to write NDEF document ID: $e');
  }
}


  List<int> _hexToBytes(String hex) {
    final cleaned = hex.replaceAll(' ', '');
    final result = <int>[];
    for (var i = 0; i < cleaned.length; i += 2) {
      final byte = cleaned.substring(i, i + 2);
      result.add(int.parse(byte, radix: 16));
    }
    return result;
  }

  String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
      buffer.write(' ');
    }
    return buffer.toString().trim();
  }

  bool _looksLikeJson(String value) {
    final v = value.trim();
    return v.startsWith('{') && v.endsWith('}');
  }

  Future<void> stopSession() async {
    try {
      await _adapter.finish();
    } catch (_) {
      // Ignore errors
    }
  }
}

class _TagPayload {
  final String? documentId;
  final Patient? patient;
  const _TagPayload({this.documentId, this.patient});
  const _TagPayload.none() : this(documentId: null, patient: null);
  bool get hasValue => documentId != null || patient != null;
}

class NfcException implements Exception {
  final String message;
  NfcException(this.message);

  @override
  String toString() => 'NfcException: $message';
}


