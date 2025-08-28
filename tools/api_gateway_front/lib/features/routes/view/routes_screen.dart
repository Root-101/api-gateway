import 'dart:math';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:api_gateway_front/features/routes/view/form/routes_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RoutesScreenNavigator {
  String get name => 'routes';

  String get path => '/routes';

  Widget builder(BuildContext context, GoRouterState state) {
    return const RoutesScreen();
  }

  void neglectGo() {
    Router.neglect(app.context, () {
      app.navigator.go(name);
    });
  }
}

class RoutesScreen extends StatefulWidget {
  static final RoutesScreenNavigator navigator = RoutesScreenNavigator();

  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late final RoutesCubit cubit;

  @override
  void initState() {
    super.initState();
    cubit = app.di.find();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    int maxTiles = size.width ~/ 475;
    int realOccupied = maxTiles * 500;
    double missing = max(
      size.width - realOccupied - 50,
      app.dimensions.padding.xxl,
    );

    return BlocConsumer<RoutesCubit, RoutesState>(
      listener: (context, state) {
        if (state is RoutesBackupState) {
          if (state is RoutesBackupProcessingState) {
            app.loading.show();
          } else if (state is RoutesBackupOkState) {
            app.loading.hide();
          } else if (state is RoutesBackupErrorState) {
            app.loading.hide();
            app.snack.showError(
              message: state.exception.message,
              context: context,
            );
          }
        } else if (state is RoutesDeleteState) {
          if (state is RoutesDeleteProcessingState) {
            app.loading.show();
          } else if (state is RoutesDeleteOkState) {
            app.loading.hide();
          } else if (state is RoutesDeleteErrorState) {
            app.loading.hide();
            app.snack.showError(
              message: state.exception.message,
              context: context,
            );
          }
        }
      },
      buildWhen: (previous, current) => current is RoutesSearchState,
      builder: (context, state) {
        if (state is RoutesInitialState) {
          cubit.search();
          return const LoadingPage();
        } else if (state is RoutesSearchingState) {
          return const LoadingPage();
        } else if (state is RoutesSearchOkState) {
          return Scaffold(
            appBar: CustomAppBar.build(
              title: app.intl.routes,
              actions: [
                PrimaryButton.secondary(
                  onPressed: () => RoutesFormScreen.navigator.create(),
                  title: app.intl.create,
                  icon: app.assets.icons.actions.add,
                ),
                app.dimensions.padding.m.gap(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: app.dimensions.padding.m,
                  ),
                  child: VerticalDivider(color: app.colors.neutral.grey5),
                ),
                app.dimensions.padding.m.gap(),
                PrimaryButton.secondary(
                  onPressed: cubit.backup,
                  title: app.intl.backup,
                  icon: app.assets.icons.actions.download,
                ),
                app.dimensions.padding.m.gap(),
                PrimaryButton.secondary(
                  onPressed: () {
                    RoutesRestoreDialog.show();
                  },
                  title: app.intl.restore,
                  icon: app.assets.icons.actions.upload,
                ),
                app.dimensions.padding.xl.gap(),
              ],
            ),
            body: SizedBox.expand(
              child: CustomPaint(
                painter: GridDotPainter(),
                child: Padding(
                  padding: EdgeInsets.all(app.dimensions.padding.l),
                  child: state.routes.isEmpty
                      ? const NoDataPage()
                      : Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: missing / 2,
                            vertical: app.dimensions.padding.xxl,
                          ),
                          child: GridView(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: maxTiles,
                                  childAspectRatio: 2.1,
                                  crossAxisSpacing: app.dimensions.padding.l,
                                  mainAxisSpacing: app.dimensions.padding.l,
                                ),
                            children: state.routes
                                .map(
                                  (model) =>
                                      _buildSingleRouteTile(model: model),
                                )
                                .toList(),
                          ),
                        ),
                ),
              ),
            ),
          );
        } else if (state is RoutesSearchErrorState) {
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

  Widget _buildSingleRouteTile({required RouteModel model}) {
    return SelectionArea(
      child: Container(
        decoration: BoxDecoration(
          color: app.colors.primary.background2,
          borderRadius: app.dimensions.border.borderRadius.m,
          border: Border.all(color: app.colors.neutral.grey5),
        ),
        child: Padding(
          padding: EdgeInsets.all(app.dimensions.padding.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: model.name,
                        child: Text(
                          model.name,
                          style: app.textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PrimaryButton.svgIcon(
                          tooltipMessage: app.intl.edit,
                          onPressed: () =>
                              RoutesFormScreen.navigator.edit(model: model),
                          icon: app.assets.icons.actions.edit,
                        ),
                        app.dimensions.padding.s.gap(),
                        PrimaryButton.svgIcon(
                          tooltipMessage: app.intl.duplicate,
                          onPressed: () => RoutesFormScreen.navigator.duplicate(
                            model: model,
                          ),
                          icon: app.assets.icons.actions.duplicate,
                        ),
                        app.dimensions.padding.s.gap(),
                        PrimaryButton.svgIcon(
                          tooltipMessage: app.intl.delete,
                          onPressed: () {
                            cubit.delete(route: model);
                          },
                          icon: app.assets.icons.actions.delete,
                        ),
                      ],
                    ),
                  ],
                ),
                app.dimensions.padding.m.gap(),
                Divider(
                  height: 0.5,
                  color: app.colors.neutral.grey5.withValues(alpha: 0.5),
                ),
              ],
              app.dimensions.padding.m.gap(),
              Text(
                app.intl.requestTo,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey4,
                ),
              ),
              Text(model.enterPoint, style: app.textTheme.titleSmall),
              app.dimensions.padding.s.gap(),
              Text(
                app.intl.redirectedTo,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey4,
                ),
              ),
              Text(model.redirectTo, style: app.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
