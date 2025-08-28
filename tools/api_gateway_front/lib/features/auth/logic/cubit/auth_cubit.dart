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
        message: app.intl.noAccess,
      );
    }
    return _currentUser!;
  }

  AuthCubit({required this.repo}) : super(const AuthInitialState()) {
    onBus<RoutesSearchErrorState>((event) {
      if (event.exception.type == GlobalExceptionType.auth) {
        logout();
      }
    });
  }

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
      logout();
      app.logger.e('Error login user with cache credentials');
    }
  }

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

    await repo.logout(); //clear cache
    _currentUser = null;

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
