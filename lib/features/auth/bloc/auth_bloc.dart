import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/models/outlet_summary.dart';
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
  final String? cashierName;

  const AuthLoginKasirRequested({
    required this.pin,
    this.cashierName,
  });

  @override
  List<Object?> get props => [pin, cashierName];
}

class AuthOwnerLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String? tenantSlug;

  const AuthOwnerLoginRequested({
    required this.email,
    required this.password,
    this.tenantSlug,
  });

  @override
  List<Object?> get props => [email, password, tenantSlug];
}

class AuthSelectOutletRequested extends AuthEvent {
  final String outletId;
  const AuthSelectOutletRequested(this.outletId);

  @override
  List<Object?> get props => [outletId];
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
  final bool hasOutlet;
  const AuthUnauthenticated({
    this.biometricAvailable = false,
    this.hasOutlet = true,
  });

  @override
  List<Object?> get props => [biometricAvailable, hasOutlet];
}

/// Owner logged in and the tenant's outlet list is ready to pick from.
class AuthOwnerOutletsLoaded extends AuthState {
  final List<OutletSummary> outlets;
  const AuthOwnerOutletsLoaded(this.outlets);

  @override
  List<Object?> get props => [outlets];
}

/// Device is now bound to an outlet; cashier PIN login can proceed.
class AuthOutletConfigured extends AuthState {
  final String outletId;
  const AuthOutletConfigured(this.outletId);

  @override
  List<Object?> get props => [outletId];
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
  final AnalyticsService? _analytics;

  AuthBloc({
    required AuthRepository authRepository,
    required SecureStorageService storage,
    AnalyticsService? analytics,
  })  : _authRepository = authRepository,
        _storage = storage,
        _analytics = analytics,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginKasirRequested>(_onLoginKasir);
    on<AuthOwnerLoginRequested>(_onOwnerLogin);
    on<AuthSelectOutletRequested>(_onSelectOutlet);
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
      final outletId = await _storage.getActiveOutletId();
      emit(AuthUnauthenticated(
        biometricAvailable: biometric,
        hasOutlet: outletId != null && outletId.isNotEmpty,
      ));
    }
  }

  Future<void> _onLoginKasir(AuthLoginKasirRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.loginKasir(
        pin: event.pin,
        cashierName: event.cashierName,
      );
      _analytics?.log('login_kasir', {'role': user.role});
      emit(AuthKasirAuthenticated(user));
    } catch (e) {
      _analytics?.log('login_kasir_failed');
      final biometric = await _authRepository.canCheckBiometrics();
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
      emit(AuthUnauthenticated(biometricAvailable: biometric));
    }
  }

  Future<void> _onOwnerLogin(AuthOwnerLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.loginOwner(
        email: event.email,
        password: event.password,
        tenantSlug: event.tenantSlug,
      );
      final outlets = await _authRepository.fetchOutlets();
      emit(AuthOwnerOutletsLoaded(outlets));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSelectOutlet(AuthSelectOutletRequested event, Emitter<AuthState> emit) async {
    await _storage.saveActiveOutletId(event.outletId);
    try {
      await _authRepository.fetchOutletPricing(event.outletId);
    } catch (_) {
      // Non-fatal: cashier login still works; pricing falls back to defaults.
    }
    emit(AuthOutletConfigured(event.outletId));
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
    _analytics?.log('logout');
    await _authRepository.logout();
    final biometric = await _authRepository.canCheckBiometrics();
    emit(AuthUnauthenticated(biometricAvailable: biometric));
  }
}
