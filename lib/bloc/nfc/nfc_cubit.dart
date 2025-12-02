import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:safe_allergy/models/patient.dart';
import 'package:safe_allergy/services/nfc_service.dart';
import 'package:safe_allergy/utils/logger.dart';

abstract class NfcState extends Equatable {
  const NfcState();

  @override
  List<Object?> get props => [];
}

class NfcInitial extends NfcState {}

class NfcChecking extends NfcState {}

class NfcAvailable extends NfcState {}

class NfcNotAvailable extends NfcState {
  final String message;

  const NfcNotAvailable(this.message);

  @override
  List<Object?> get props => [message];
}

class NfcReading extends NfcState {}

class NfcReadSuccess extends NfcState {
  final Patient patient;

  const NfcReadSuccess(this.patient);

  @override
  List<Object?> get props => [patient];
}

class NfcReadError extends NfcState {
  final String message;

  const NfcReadError(this.message);

  @override
  List<Object?> get props => [message];
}

class NfcWriting extends NfcState {}

class NfcWriteSuccess extends NfcState {}

class NfcWriteError extends NfcState {
  final String message;

  const NfcWriteError(this.message);

  @override
  List<Object?> get props => [message];
}

class NfcCubit extends Cubit<NfcState> {
  NfcCubit() : super(NfcInitial());

  final NfcService _nfcService = NfcService.instance;

  Future<void> checkAvailability() async {
    emit(NfcChecking());

    try {
      final isAvailable = await _nfcService.isAvailable();
      if (isAvailable) {
        emit(NfcAvailable());
      } else {
        emit(const NfcNotAvailable('NFC is not available on this device'));
      }
    } catch (e) {
      await Logger.logError('NFC availability check failed', error: e);
      emit(NfcNotAvailable('Failed to check NFC availability: $e'));
    }
  }

  Future<void> readPatientData() async {
    emit(NfcReading());

    try {
      final patient = await _nfcService.readPatientData();
      await _nfcService.stopSession();
      emit(NfcReadSuccess(patient));
    } on NfcException catch (e) {
      await _nfcService.stopSession();
      emit(NfcReadError(e.message));
    } catch (e) {
      await _nfcService.stopSession();
      emit(NfcReadError('Failed to read NFC tag: $e'));
    }
  }

  Future<void> writePatientData(Patient patient) async {
    emit(NfcWriting());

    try {
      await _nfcService.writePatientData(patient);
      await _nfcService.stopSession();
      emit(NfcWriteSuccess());
    } on NfcException catch (e) {
      await _nfcService.stopSession();
      emit(NfcWriteError(e.message));
    } catch (e) {
      await Logger.logError('NFC write operation failed', error: e);
      emit(NfcWriteError('Failed to write to NFC tag: $e'));
    }
  }

  Future<void> stopSession() async {
    await _nfcService.stopSession();
    emit(NfcInitial());
  }

  void reset() {
    emit(NfcInitial());
  }
}
