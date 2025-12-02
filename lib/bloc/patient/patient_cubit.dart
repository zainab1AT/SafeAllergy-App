import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:safe_allergy/models/patient.dart';

abstract class PatientState extends Equatable {
  const PatientState();

  @override
  List<Object?> get props => [];
}

class PatientInitial extends PatientState {}

class PatientLoaded extends PatientState {
  final Patient patient;

  const PatientLoaded(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientEditing extends PatientState {
  final Patient patient;

  const PatientEditing(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientCubit extends Cubit<PatientState> {
  PatientCubit() : super(PatientInitial());

  void setPatient(Patient patient) {
    emit(PatientLoaded(patient));
  }

  void updatePatient(Patient patient) {
    emit(PatientEditing(patient));
  }

  void reset() {
    emit(PatientInitial());
  }
}
