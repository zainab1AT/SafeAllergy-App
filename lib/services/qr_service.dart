import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safe_allergy/models/patient.dart';
import 'package:safe_allergy/services/firebase_service.dart';
import 'package:safe_allergy/utils/constants.dart';
import 'package:safe_allergy/utils/logger.dart';
import 'package:image_picker/image_picker.dart';

class QrService {
  QrService._();

  static final QrService _instance = QrService._();
  static QrService get instance => _instance;

  final ImagePicker _picker = ImagePicker();
  final mlkit.BarcodeScanner _barcodeScanner = mlkit.BarcodeScanner(
    formats: [mlkit.BarcodeFormat.qrCode],
  );

  Future<String> generateQrData(Patient patient) async {
    try {
      await Logger.logInfo('QR code generation (docId) started');

      final docId = await FirebaseService.instance.createOrUpdatePatient(
        patient,
      );

      await Logger.logInfo('QR code generation (docId) completed');
      return docId;
    } catch (e) {
      await Logger.logError('QR code generation failed', error: e);
      throw QrException('Failed to generate QR code data: $e');
    }
  }

  /// Parse QR data which is expected to be a Firestore document ID.
  Future<Patient> parseQrData(String qrData) async {
    try {
      await Logger.logInfo('QR code parsing started');

      if (qrData.isEmpty) {
        throw QrException('QR code data is empty');
      }

      final patient = await FirebaseService.instance.getPatientById(
        qrData.trim(),
      );
      if (patient == null) {
        throw QrException('No patient found for this QR code');
      }

      await FirebaseService.instance.logAudit(
        action: 'QR_READ',
        result: 'SUCCESS',
        patientDocId: patient.id,
      );

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

  /// Capture a QR widget wrapped in a [RepaintBoundary] and save it to gallery.
  Future<void> saveQrToGallery(GlobalKey repaintKey) async {
    try {
      final status = await _ensureMediaPermission();
      if (!status.isGranted) {
        throw QrException('Storage permission is required to save QR code');
      }

      final boundary =
          repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw QrException('Failed to capture QR image');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) {
        throw QrException('Failed to encode QR image');
      }

      final pngBytes = byteData.buffer.asUint8List();
      await ImageGallerySaver.saveImage(
        Uint8List.fromList(pngBytes),
        quality: 100,
        name: 'safe_allergy_qr_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      await Logger.logError('Failed to save QR image', error: e);
      if (e is QrException) rethrow;
      throw QrException('Failed to save QR image: $e');
    }
  }

  /// Pick an image from gallery and try to decode a QR code from it.
  Future<String> scanQrFromGallery() async {
    try {
      final status = await _ensureMediaPermission();
      if (!status.isGranted) {
        throw QrException('Gallery permission is required');
      }

      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        throw QrException('No image selected');
      }

      final inputImage = mlkit.InputImage.fromFilePath(picked.path);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      for (final barcode in barcodes) {
        final value = barcode.rawValue;
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }

      throw QrException('No QR code found in selected image');
    } catch (e) {
      await Logger.logError('QR scan from gallery failed', error: e);
      if (e is QrException) rethrow;
      throw QrException('Failed to scan QR from gallery: $e');
    }
  }

  Future<PermissionStatus> _ensureMediaPermission() async {
    PermissionStatus status = await Permission.photos.request();
    if (status.isGranted) {
      return status;
    }

    if (Platform.isAndroid) {
      status = await Permission.storage.request();
    }
    return status;
  }
}

class QrException implements Exception {
  final String message;
  QrException(this.message);

  @override
  String toString() => 'QrException: $message';
}
