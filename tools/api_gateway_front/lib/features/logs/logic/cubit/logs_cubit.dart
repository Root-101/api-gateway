import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogsCubit extends Cubit<LogsState>
    with GlobalEventBusCommunication<LogsState> {
  static const int defaultPage = 0;
  static const int defaultSize = 20;

  final AuthCubit auth;
  final LogsRepo repo;

  int currentPage = 0;

  final List<HttpLogModel> items = [];

  LogsCubit({required this.auth, required this.repo})
    : super(const LogsInitialState());

  void reset() {
    emit(const LogsInitialState());
  }

  Future<void> init() async {
    emit(LogsSearchingState());

    HttpLogSearchModel response = await repo.findAll(
      credential: auth.current,
      page: currentPage++,
      size: defaultSize,
    );
    items.addAll(response.pageContent);

    emit(LogsSearchOkState(items: items));
  }

  Future<List<HttpLogModel>> fetchNextPage() async {
    HttpLogSearchModel response = await repo.findAll(
      credential: auth.current,
      page: currentPage++,
      size: defaultSize,
    );

    items.addAll(response.pageContent);

    return response.pageContent;
  }
}

abstract class LogsState {
  const LogsState();
}

class LogsInitialState extends LogsState {
  const LogsInitialState();
}

//------------------------- SEARCH -------------------------\\
abstract class LogsSearchState extends LogsState {
  LogsSearchState();
}

class LogsSearchingState extends LogsSearchState {
  LogsSearchingState();
}

class LogsSearchOkState extends LogsSearchState {
  List<HttpLogModel> items;

  LogsSearchOkState({required this.items});
}

class LogsSearchErrorState extends LogsSearchState {
  GlobalException exception;

  LogsSearchErrorState(this.exception);
}
