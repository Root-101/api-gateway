import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class LogsCubit extends Cubit<LogsState>
    with GlobalEventBusCommunication<LogsState> {
  static const int defaultPage = 0;
  static const int defaultSize = 20;

  final AuthCubit auth;
  final LogsRepo repo;

  int page = 0;
  late final PagingController<int, HttpLogModel> _pagingController;

  LogsCubit({required this.auth, required this.repo})
    : super(const LogsInitialState());

  void reset() {
    emit(const LogsInitialState());
  }

  Future<void> init() async {
    emit(LogsSearchingState());

    HttpLogSearchModel items = await repo.findAll(
      credential: auth.current,
      page: page++,
      size: defaultSize,
    );

    emit(LogsSearchOkState(items: items.pageContent));
  }

  Future<List<HttpLogModel>> fetchNextPage() async {
    List<HttpLogModel> items = (await repo.findAll(
      credential: auth.current,
      page: page++,
      size: defaultSize,
    )).pageContent;

    return items;
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
