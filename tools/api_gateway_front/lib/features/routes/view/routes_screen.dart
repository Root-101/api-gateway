import 'dart:math';

import 'package:api_gateway_front/app_exporter.dart';
import 'package:api_gateway_front/features/routes/view/form/routes_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  //local filter: the api has no search for routes and the list is small
  List<RouteModel> _filter(List<RouteModel> routes) => _query.isEmpty
      ? routes
      : routes
            .where(
              (r) => [
                r.name,
                r.path,
                r.uri,
                r.description,
              ].any((field) => field.toLowerCase().contains(_query)),
            )
            .toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    cubit = app.di.find();
    if (cubit.state is RoutesInitialState) {
      cubit.search();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    //same tile width in both calculations; at least one column
    int maxTiles = max(1, size.width ~/ 500);
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
          return const LoadingPage();
        } else if (state is RoutesSearchingState) {
          return const LoadingPage();
        } else if (state is RoutesSearchOkState) {
          return Scaffold(
            appBar: CustomAppBar.build(
              title: app.intl.routes.routes,
              actions: [
                PrimaryButton.secondary(
                  onPressed: () => RoutesFormScreen.navigator.create(),
                  title: app.intl.actions.create,
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
                  title: app.intl.actions.backup,
                  icon: app.assets.icons.actions.download,
                ),
                app.dimensions.padding.m.gap(),
                PrimaryButton.secondary(
                  onPressed: () {
                    RoutesRestoreDialog.show();
                  },
                  title: app.intl.actions.restore,
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
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 450,
                          child: EMTextSearchField(
                            controller: _searchCtrl,
                            hint: app.intl.routes.searchRoutes,
                            onSearch: (value) => setState(
                              () => _query = value.trim().toLowerCase(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _filter(state.routes).isEmpty
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
                                        crossAxisSpacing:
                                            app.dimensions.padding.l,
                                        mainAxisSpacing:
                                            app.dimensions.padding.l,
                                      ),
                                  children: _filter(state.routes)
                                      .map(
                                        (model) =>
                                            _buildSingleRouteTile(model: model),
                                      )
                                      .toList(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (state is RoutesSearchErrorState) {
          return ErrorPage(
            errorMessage: state.exception.message,
            buttonText: app.intl.actions.tryAgain,
            onPressed: cubit.search,
          );
        } else {
          return ErrorPage(
            buttonText: app.intl.actions.tryAgain,
            onPressed: cubit.search,
          );
        }
      },
    );
  }

  Future<void> _confirmDelete(RouteModel model) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(app.intl.actions.delete),
        content: Text(app.intl.actions.deleteRouteConfirm(name: model.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(app.intl.actions.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              app.intl.actions.delete,
              style: TextStyle(color: app.colors.primary.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      cubit.delete(route: model);
    }
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
                        //the card has a fixed height: the description lives in the tooltip
                        message: model.description.isEmpty
                            ? model.name
                            : [model.name, model.description].join('\n'),
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
                          tooltipMessage: app.intl.actions.edit,
                          onPressed: () =>
                              RoutesFormScreen.navigator.edit(model: model),
                          icon: app.assets.icons.actions.edit,
                        ),
                        app.dimensions.padding.s.gap(),
                        PrimaryButton.svgIcon(
                          tooltipMessage: app.intl.actions.duplicate,
                          onPressed: () => RoutesFormScreen.navigator.duplicate(
                            model: model,
                          ),
                          icon: app.assets.icons.actions.duplicate,
                        ),
                        app.dimensions.padding.s.gap(),
                        PrimaryButton.svgIcon(
                          tooltipMessage: app.intl.actions.delete,
                          onPressed: () => _confirmDelete(model),
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
                app.intl.routes.requestTo,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey4,
                ),
              ),
              _buildUrl(model.enterPoint),
              app.dimensions.padding.s.gap(),
              Text(
                app.intl.routes.redirectedTo,
                style: app.textTheme.bodySmall?.copyWith(
                  color: app.colors.neutral.grey4,
                ),
              ),
              _buildUrl(model.redirectTo),
            ],
          ),
        ),
      ),
    );
  }

  //fixed-height card: one line, full url on hover, copy button
  Widget _buildUrl(String url) {
    return Row(
      children: [
        Flexible(
          child: Tooltip(
            message: url,
            child: Text(
              url,
              style: app.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        app.dimensions.padding.s.gap(),
        Tooltip(
          message: app.intl.actions.copy,
          child: InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!mounted) return;
              app.snack.showSuccess(
                message: app.intl.actions.copiedToClipboard,
                context: context,
              );
            },
            child: Icon(Icons.copy, size: 14, color: app.colors.neutral.grey4),
          ),
        ),
      ],
    );
  }
}
