import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/remote/auth_repository.dart';

// --- Events ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {}

class AuthLoginKasirRequested extends AuthEvent {
  final String pin;
  final String cashierId;
  final String cashierName;

  const AuthLoginKasirRequested({
    required this.pin,
    required this.cashierId,
    required this.cashierName,
  });

  @override
  List<Object?> get props => [pin, cashierId, cashierName];
}

class AuthBiometricLoginRequested extends AuthEvent {
  final String cashierId;
  final String cashierName;

  const AuthBiometricLoginRequested({
    required this.cashierId,
    required this.cashierName,
  });

  @override
  List<Object?> get props => [cashierId, cashierName];
}

class AuthLogoutRequested extends AuthEvent {}

// --- States ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {
  final bool biometricAvailable;
  const AuthUnauthenticated({this.biometricAvailable = false});

  @override
  List<Object?> get props => [biometricAvailable];
}

class AuthKasirAuthenticated extends AuthState {
  final AuthUser user;
  const AuthKasirAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthOwnerAuthenticated extends AuthState {
  final AuthUser user;
  const AuthOwnerAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SecureStorageService _storage;

  AuthBloc({
    required AuthRepository authRepository,
    required SecureStorageService storage,
  })  : _authRepository = authRepository,
        _storage = storage,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginKasirRequested>(_onLoginKasir);
    on<AuthBiometricLoginRequested>(_onBiometricLogin);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final token = await _storage.getToken();
    final role = await _storage.getUserRole();
    final biometric = await _authRepository.canCheckBiometrics();

    if (token != null && token.isNotEmpty) {
      final user = AuthUser(
        id: 'user_active',
        name: role == 'owner' ? 'Owner Tumbuh' : 'Barista Rama',
        email: '',
        role: role ?? 'kasir',
      );

      if (role == 'owner') {
        emit(AuthOwnerAuthenticated(user));
      } else {
        emit(AuthKasirAuthenticated(user));
      }
    } else {
      emit(AuthUnauthenticated(biometricAvailable: biometric));
    }
  }

  Future<void> _onLoginKasir(AuthLoginKasirRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.loginKasir(
        pin: event.pin,
        cashierId: event.cashierId,
        cashierName: event.cashierName,
      );
      emit(AuthKasirAuthenticated(user));
    } catch (e) {
      final biometric = await _authRepository.canCheckBiometrics();
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
      emit(AuthUnauthenticated(biometricAvailable: biometric));
    }
  }

  Future<void> _onBiometricLogin(AuthBiometricLoginRequested event, Emitter<AuthState> emit) async {
    final authenticated = await _authRepository.authenticateBiometrics();
    if (authenticated) {
      emit(AuthLoading());
      final user = AuthUser(
        id: event.cashierId,
        name: event.cashierName,
        email: '',
        role: 'kasir',
        shiftTitle: 'Shift 1 Pagi',
      );
      await _storage.saveUserRole('kasir');
      emit(AuthKasirAuthenticated(user));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    final biometric = await _authRepository.canCheckBiometrics();
    emit(AuthUnauthenticated(biometricAvailable: biometric));
  }
}
