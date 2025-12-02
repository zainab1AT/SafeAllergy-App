import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:safe_allergy/models/patient.dart';
import 'package:safe_allergy/services/qr_service.dart';
import 'package:safe_allergy/utils/logger.dart';

abstract class QrState extends Equatable {
  const QrState();

  @override
  List<Object?> get props => [];
}

class QrInitial extends QrState {}

class QrGenerating extends QrState {}

class QrGenerated extends QrState {
  final String qrData;

  const QrGenerated(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

class QrGenerationError extends QrState {
  final String message;

  const QrGenerationError(this.message);

  @override
  List<Object?> get props => [message];
}

class QrScanning extends QrState {}

class QrScanSuccess extends QrState {
  final Patient patient;

  const QrScanSuccess(this.patient);

  @override
  List<Object?> get props => [patient];
}

class QrScanError extends QrState {
  final String message;

  const QrScanError(this.message);

  @override
  List<Object?> get props => [message];
}

class QrCubit extends Cubit<QrState> {
  QrCubit() : super(QrInitial());

  final QrService _qrService = QrService.instance;

  Future<void> generateQrCode(Patient patient) async {
    emit(QrGenerating());

    try {
      final qrData = await _qrService.generateQrData(patient);
      emit(QrGenerated(qrData));
    } on QrException catch (e) {
      emit(QrGenerationError(e.message));
    } catch (e) {
      await Logger.logError('QR code generation failed', error: e);
      emit(QrGenerationError('Failed to generate QR code: $e'));
    }
  }

  Future<void> parseQrData(String qrData) async {
    emit(QrScanning());

    try {
      final patient = await _qrService.parseQrData(qrData);
      emit(QrScanSuccess(patient));
    } on QrException catch (e) {
      emit(QrScanError(e.message));
    } catch (e) {
      await Logger.logError('QR code parsing failed', error: e);
      emit(QrScanError('Failed to parse QR code: $e'));
    }
  }

  void reset() {
    emit(QrInitial());
  }
}
