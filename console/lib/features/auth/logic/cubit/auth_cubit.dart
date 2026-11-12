import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState>
    with GlobalEventBusCommunication<AuthState> {
  final AuthRepo repo;

  String? _token;
  String? _username;
  bool _rememberMe = false;
  bool _sessionExpired = false;

  String? get token => _token;

  bool get isLoggedIn => _token != null;

  ///only known after a login in this tab: a remembered token doesn't say who it belongs to
  String? get username => _username;

  bool get sessionExpired => _sessionExpired;

  //the header and the 401/403 logout are done by AuthInterceptor
  AuthCubit({required this.repo}) : super(const AuthInitialState());

  Future init() async {
    _token = await repo.loadCache();
    _rememberMe = _token != null;
  }

  Future<bool> isGatewayUp() => repo.isGatewayUp();

  void reset() {
    emit(const AuthInitialState());
  }

  Future login({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      emit(AuthLoginInProgressState());

      //if this runs without problem, the login is successfully, if something is wrong an exception is thrown
      //store in memory credential for later use
      _token = await repo.login(
        username: username,
        password: password,
        rememberMe: rememberMe,
      );
      _username = username;
      _rememberMe = rememberMe;
      _sessionExpired = false;

      emit(AuthLoginOkState());
    } on Exception catch (exc) {
      emit(AuthLoginErrorState(ExceptionConverter.parse(exc)));
    }
  }

  ///the token stopped being valid: keep the user on the screen and ask for the password again
  void expireSession() {
    if (_token == null || _sessionExpired) return; //parallel 401s ask only once
    _sessionExpired = true;
    emit(AuthSessionExpiredState());
  }

  Future reauthenticate({
    required String username,
    required String password,
  }) async {
    try {
      emit(AuthReauthInProgressState());

      _token = await repo.login(
        username: username,
        password: password,
        rememberMe: _rememberMe,
      );
      _username = username;
      _sessionExpired = false;

      emit(AuthReauthOkState());
    } on Exception catch (exc) {
      emit(AuthReauthErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future logout() async {
    emit(AuthLogoutInProgressState());

    _token = null; //first, so parallel 401s don't trigger a second logout
    _username = null;
    _rememberMe = false;
    _sessionExpired = false;
    await repo.logout(); //clear cache

    emit(AuthLogoutOkState());
  }
}

abstract class AuthState {
  const AuthState();
}

class AuthInitialState extends AuthState {
  const AuthInitialState();
}

//------------------------- LOGIN -------------------------\\
//login
abstract class AuthLoginState extends AuthState {
  AuthLoginState();
}

class AuthLoginInProgressState extends AuthLoginState {
  AuthLoginInProgressState();
}

class AuthLoginOkState extends AuthLoginState {
  AuthLoginOkState();
}

class AuthLoginErrorState extends AuthLoginState {
  GlobalException exception;

  AuthLoginErrorState(this.exception);
}

//------------------------- SESSION -------------------------\\
class AuthSessionExpiredState extends AuthState {
  AuthSessionExpiredState();
}

class AuthReauthInProgressState extends AuthState {
  AuthReauthInProgressState();
}

class AuthReauthOkState extends AuthState {
  AuthReauthOkState();
}

class AuthReauthErrorState extends AuthState {
  GlobalException exception;

  AuthReauthErrorState(this.exception);
}

//------------------------- LOGOUT -------------------------\\
//logout
abstract class AuthLogoutState extends AuthState {
  AuthLogoutState();
}

class AuthLogoutInProgressState extends AuthLogoutState {
  AuthLogoutInProgressState();
}

class AuthLogoutOkState extends AuthLogoutState {
  AuthLogoutOkState();
}

class AuthLogoutErrorState extends AuthLogoutState {
  GlobalException exception;

  AuthLogoutErrorState(this.exception);
}
