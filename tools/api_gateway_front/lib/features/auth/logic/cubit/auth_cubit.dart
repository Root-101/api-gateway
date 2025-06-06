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

  void reset() {
    emit(const AuthInitialState());
  }

  Future login({required String username, required String password}) async {
    try {
      emit(AuthLoginInProgressState());

      //if this runs without problem, the login is successfully, if something is wrong an exception is thrown
      await repo.login(username: username, password: password);

      //store in memory credential for later use
      _currentUser = CredentialsModel(username: username, password: password);

      emit(AuthLoginOkState());
    } on Exception catch (exc) {
      emit(AuthLoginErrorState(ExceptionConverter.parse(exc)));
    }
  }

  Future logout() async {
    emit(AuthLogoutInProgressState());
    _currentUser = null;
    FeaturesInit.reset(); //todo: another violation of architecture
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
