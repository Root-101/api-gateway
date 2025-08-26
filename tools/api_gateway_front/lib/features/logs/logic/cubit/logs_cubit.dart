import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class LogsCubit extends Cubit<LogsState>
    with GlobalEventBusCommunication<LogsState> {
  static const int defaultPage = 0;
  static const int defaultSize = 20;

  final AuthCubit auth;
  final LogsRepo repo;

  late final PagingController<int, HttpLogModel> _pagingController;

  LogsCubit({required this.auth, required this.repo})
    : super(const LogsInitialState());

  void reset() {
    emit(const LogsInitialState());
  }

  Future<void> init() async {
    _pagingController = PagingController<int, HttpLogModel>(
      getNextPageKey: (state) {
        int lastLoadedItems = state.pages?.last.length ?? 0;
        int lastPage = state.keys?.last ?? -1;

        if (lastPage == -1) {
          return 0;
        } else if (lastLoadedItems < defaultSize) {
          return null;
        }

        return lastPage + 1;
      },
      fetchPage: (pageKey) => fetchPage(pageKey: pageKey),
    );

    reloadPage();
  }

  Future<List<HttpLogModel>> fetchPage({required int pageKey}) async {
    try {
      //OJO: el fetch page no lanza estado, es el paging controller con sus builders
      //los que se encargan de actualizar la UI
      HttpLogSearchModel searchModel = await repo.findAll(
        credential: auth.current,
        page: pageKey,
        size: defaultSize,
      );

      return searchModel.pageContent;
    } on GlobalException catch (global) {
      emit(LogsSearchErrorState(global));
      return [];
    }
  }

  Future reloadPage() async {
    try {
      emit(LogsSearchingState());

      await Future.delayed(const Duration(milliseconds: 150));
      _pagingController.refresh();

      emit(LogsSearchOkState(pagingController: _pagingController));
    } on GlobalException catch (global) {
      emit(LogsSearchErrorState(global));
    }
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
  PagingController<int, HttpLogModel> pagingController;

  LogsSearchOkState({required this.pagingController});
}

class LogsSearchErrorState extends LogsSearchState {
  GlobalException exception;

  LogsSearchErrorState(this.exception);
}
