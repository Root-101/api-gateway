import 'package:api_gateway_front/app_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
          cubit.search();
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
                  child: state.logs.isEmpty
                      ? const NoDataPage()
                      : Center(child: Text('asd')),
                ),
              ),
            ),
          );
        } else if (state is LogsSearchErrorState) {
          return ErrorPage(
            errorMessage: state.exception.message,
            buttonText: app.intl.tryAgain,
            onPressed: cubit.search,
          );
        } else {
          return ErrorPage(
            buttonText: app.intl.tryAgain,
            onPressed: cubit.search,
          );
        }
      },
    );
  }
}
