import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthCubit extends Cubit<AuthState>
    with GlobalEventBusCommunication<AuthState> {
  final AuthRepo repo;

  CredentialsModel? _currentUser;

  bool get isLoggedIn => _currentUser != null;

  CredentialsModel get current {
    if (_currentUser == null) {
      logout();
      throw GlobalException(
        type: GlobalExceptionType.auth,
        message: app.intl.common.noAccess,
      );
    }
    return _currentUser!;
  }

  //401/403 logout is done by the Dio interceptor in FeaturesInit
  AuthCubit({required this.repo}) : super(const AuthInitialState());

  Future init() async {
    try {
      ({String username, String password})? cache = await repo.loadCache();
      if (cache != null) {
        //try to login with credentials

        //if this runs without problem, the login is successfully, if something is wrong an exception is thrown
        await repo.login(
          username: cache.username,
          password: cache.password,
          rememberMe: false,
        );

        //store in memory credential for later use
        _currentUser = CredentialsModel(
          username: cache.username,
          password: cache.password,
        );
      }
    } on Exception catch (exc) {
      app.logger.e('Error login user with cache credentials');
      //only forget the remembered credentials when the server rejects them, not on network errors
      if (ExceptionConverter.parse(exc).type == GlobalExceptionType.auth) {
        await logout();
      }
    }
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
      await repo.login(
        username: username,
        password: password,
        rememberMe: rememberMe,
      );

      //store in memory credential for later use
      _currentUser = CredentialsModel(username: username, password: password);

      emit(AuthLoginOkState());
    } on Exception catch (exc) {
      emit(AuthLoginErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future logout() async {
    emit(AuthLogoutInProgressState());

    _currentUser = null; //first, so parallel 401s don't trigger a second logout
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
