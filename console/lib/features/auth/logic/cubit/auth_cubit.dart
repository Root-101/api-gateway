import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState>
    with GlobalEventBusCommunication<AuthState> {
  final AuthRepo repo;

  String? _token;

  String? get token => _token;

  bool get isLoggedIn => _token != null;

  //the header and the 401/403 logout are done by AuthInterceptor
  AuthCubit({required this.repo}) : super(const AuthInitialState());

  Future init() async {
    _token = await repo.loadCache();
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

      emit(AuthLoginOkState());
    } on Exception catch (exc) {
      emit(AuthLoginErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future logout() async {
    emit(AuthLogoutInProgressState());

    _token = null; //first, so parallel 401s don't trigger a second logout
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
