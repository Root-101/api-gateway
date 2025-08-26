import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class LogsScreenNavigator {
  String get name => 'logs';

  String get path => '/logs';

  Widget builder(BuildContext context, GoRouterState state) {
    return const LogsScreen();
  }

  void neglectGo() {
    Router.neglect(app.context, () {
      app.navigator.go(name);
    });
  }
}

class LogsScreen extends StatefulWidget {
  static final LogsScreenNavigator navigator = LogsScreenNavigator();

  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late final LogsCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = app.di.find();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogsCubit, LogsState>(
      listener: (context, state) {},
      buildWhen: (previous, current) => current is LogsSearchState,
      builder: (context, state) {
        if (state is LogsInitialState) {
          cubit.init();
          return const LoadingPage();
        } else if (state is LogsSearchingState) {
          return const LoadingPage();
        } else if (state is LogsSearchOkState) {
          return Scaffold(
            appBar: CustomAppBar.build(title: app.intl.logs),
            body: SizedBox.expand(
              child: CustomPaint(
                painter: GridDotPainter(),
                child: Padding(
                  padding: EdgeInsets.all(app.dimensions.padding.l),
                  child: PagingListener(
                    controller: state.pagingController,
                    builder: (context, scrollState, fetchNextPage) =>
                        _buildPagedListView(scrollState, fetchNextPage),
                  ),
                ),
              ),
            ),
          );
        } else if (state is LogsSearchErrorState) {
          return ErrorPage(
            errorMessage: state.exception.message,
            buttonText: app.intl.tryAgain,
            onPressed: cubit.reloadPage,
          );
        } else {
          return ErrorPage(
            buttonText: app.intl.tryAgain,
            onPressed: cubit.reloadPage,
          );
        }
      },
    );
  }

  PagedListView<int, HttpLogModel> _buildPagedListView(
    PagingState<int, HttpLogModel> pagingState,
    void Function() fetchNextPage,
  ) {
    return PagedListView<int, HttpLogModel>(
      shrinkWrap: true,
      state: pagingState,
      physics: const ClampingScrollPhysics(),
      fetchNextPage: fetchNextPage,
      builderDelegate: PagedChildBuilderDelegate<HttpLogModel>(
        animateTransitions: true,
        noItemsFoundIndicatorBuilder: (context) => const NoDataPage(),
        noMoreItemsIndicatorBuilder: (context) => const NoMoreItemsIndicator(),
        firstPageProgressIndicatorBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        newPageProgressIndicatorBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        itemBuilder: (context, item, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: app.dimensions.padding.s),
            child: Text(item.id),
          );
        },
      ),
    );
  }
}

class NoMoreItemsIndicator extends StatelessWidget {
  const NoMoreItemsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    Color color = app.colors.neutral.grey2.darken(0.1);

    return Padding(
      padding: EdgeInsets.only(
        left: app.dimensions.padding.sm,
        right: app.dimensions.padding.sm,
        top: app.dimensions.padding.s,
        bottom: 4 * app.dimensions.padding.xxl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Divider(color: color)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: app.dimensions.padding.sm,
            ),
            child: Text(
              'No more items to show', //TODO: intl
              style: app.textTheme.titleSmall?.copyWith(color: color),
            ),
          ),
          Expanded(child: Divider(color: color)),
        ],
      ),
    );
  }
}
