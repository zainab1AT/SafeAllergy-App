import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:safe_allergy/models/patient.dart';
import 'package:safe_allergy/services/encryption_service.dart';
import 'package:safe_allergy/utils/constants.dart';
import 'package:safe_allergy/utils/logger.dart';

class NfcService {
  NfcService._();

  static final NfcService _instance = NfcService._();
  static NfcService get instance => _instance;

  Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      await Logger.logError('Failed to check NFC availability', error: e);
      return false;
    }
  }

  NdefRecord createDataRecord(String encrypted) {
    return NdefRecord(
      typeNameFormat: TypeNameFormat.media,
      type: Uint8List.fromList(utf8.encode('application/json')),
      identifier: Uint8List(0),
      payload: Uint8List.fromList(utf8.encode(encrypted)),
    );
  }

  Future<Patient> readPatientData() async {
    if (!await isAvailable()) {
      throw NfcException(AppConstants.errorNfcNotSupported);
    }

    await Logger.logInfo('NFC read operation started');
    final completer = Completer<Patient>();

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              throw NfcException('Tag does not support NDEF format');
            }

            final ndefMessage = await ndef.read();
            if (ndefMessage == null || ndefMessage.records.isEmpty) {
              throw NfcException('No data found on tag');
            }

            final record = ndefMessage.records.first;

            // We ALWAYS decode raw payload — no language bytes
            String dataString = utf8.decode(record.payload);

            // Try decrypting – but if it fails, treat as plain JSON
            try {
              dataString = await EncryptionService.instance.decrypt(dataString);
            } catch (e) {
              await Logger.logWarning('Data not encrypted, using plain text');
            }

            // Parse JSON into patient
            final patient = Patient.fromJsonString(dataString);

            await Logger.logInfo('NFC read operation completed successfully');
            await NfcManager.instance.stopSession();

            if (!completer.isCompleted) {
              completer.complete(patient);
            }
          } catch (e) {
            await NfcManager.instance.stopSession();
            if (!completer.isCompleted) {
              if (e is NfcException) {
                completer.completeError(e);
              } else {
                completer.completeError(
                  NfcException('${AppConstants.errorNfcReadFailed}: $e'),
                );
              }
            }
          }
        },
      );

      return await completer.future;
    } catch (e) {
      await Logger.logError('NFC read operation failed', error: e);
      if (e is NfcException) rethrow;
      throw NfcException('${AppConstants.errorNfcReadFailed}: $e');
    }
  }

  Future<void> writePatientData(Patient patient) async {
    if (!await isAvailable()) {
      throw NfcException(AppConstants.errorNfcNotSupported);
    }

    await Logger.logInfo('NFC write operation started');

    final completer = Completer<void>();

    try {
      final jsonString = patient.toJsonString();
      final encryptedData = await EncryptionService.instance.encrypt(
        jsonString,
      );

      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              throw NfcException('Tag does not support NDEF format');
            }

            if (!ndef.isWritable) {
              throw NfcException('NFC tag is not writable');
            }

            final record = createDataRecord(encryptedData);
            final message = NdefMessage(records: [record]);

            await ndef.write(message: message);

            await Logger.logInfo('NFC write completed successfully');
            await NfcManager.instance.stopSession();

            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e) {
            await NfcManager.instance.stopSession(
              errorMessageIos: e.toString(),
            );
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
      );

      return await completer.future;
    } catch (e) {
      await Logger.logError('NFC write operation failed', error: e);

      if (!completer.isCompleted) {
        completer.completeError(e);
      }

      rethrow;
    }
  }

  Future<void> stopSession() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Ignore errors
    }
  }
}

class NfcException implements Exception {
  final String message;
  NfcException(this.message);

  @override
  String toString() => 'NfcException: $message';
}
