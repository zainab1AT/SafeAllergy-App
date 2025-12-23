import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_allergy/services/authorization_service.dart';
import 'package:safe_allergy/utils/logger.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthorized extends AuthState {
  final String email;

  const AuthAuthorized(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthUnauthorized extends AuthState {
  final String message;

  const AuthUnauthorized(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final AuthorizationService _authService = AuthorizationService.instance;

  Future<void> checkAuthorization(String email) async {
    emit(AuthLoading());

    try {
      final isAuthorized = await _authService.checkAuthorization(email);

      if (isAuthorized) {
        _authService.setCurrentAuthorizedEmail(email);
        emit(AuthAuthorized(email));
      } else {
        emit(AuthUnauthorized('Email not authorized for write access'));
      }
    } catch (e) {
      await Logger.logError('Authorization check failed', error: e);
      emit(AuthError('An error occurred during authorization'));
    }
  }

  void reset() {
    emit(AuthInitial());
  }
}
