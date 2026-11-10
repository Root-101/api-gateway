import 'dart:async';

import 'package:console/app_exporter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GatewayStatus {
  final bool offline;
  final bool retrying;

  ///last time the gateway answered, shown in the offline banner
  final DateTime? lastLoadedAt;

  const GatewayStatus({
    this.offline = false,
    this.retrying = false,
    this.lastLoadedAt,
  });
}

///offline banner state: any unanswered request turns it on, the next answer turns it off
class GatewayStatusCubit extends Cubit<GatewayStatus> {
  static const Duration retryEvery = Duration(seconds: 10);

  final Future<bool> Function() ping;
  Timer? _timer;

  GatewayStatusCubit({required this.ping}) : super(const GatewayStatus());

  void markOnline() {
    _timer?.cancel();
    emit(GatewayStatus(lastLoadedAt: DateTime.now()));
  }

  void markOffline() {
    if (state.offline) return;
    emit(GatewayStatus(offline: true, lastLoadedAt: state.lastLoadedAt));
    _timer = Timer.periodic(retryEvery, (_) => retry());
  }

  Future<void> retry() async {
    if (!state.offline || state.retrying) return;
    emit(
      GatewayStatus(
        offline: true,
        retrying: true,
        lastLoadedAt: state.lastLoadedAt,
      ),
    );
    final up = await ping();
    if (up) {
      markOnline();
    } else if (state.offline) {
      emit(GatewayStatus(offline: true, lastLoadedAt: state.lastLoadedAt));
    }
  }

  void reset() {
    _timer?.cancel();
    emit(const GatewayStatus());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

class GatewayStatusInterceptor extends Interceptor {
  final GatewayStatusCubit status;
  final AuthCubit auth;

  GatewayStatusInterceptor({required this.status, required this.auth});

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    status.markOnline();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      status.markOnline(); //a 4xx/5xx is still the gateway answering
    } else if (auth.isLoggedIn &&
        err.type != DioExceptionType.cancel &&
        err.type != DioExceptionType.badCertificate) {
      status.markOffline();
    }
    handler.next(err);
  }
}
