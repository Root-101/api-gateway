import 'dart:math';

import 'package:console/app_exporter.dart';
import 'package:console/features/routes/view/form/routes_form_screen.dart';
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
  static const double _minCardWidth = 400;
  static const double _gap = 16;

  late final RoutesCubit cubit;
  final TextEditingController _searchCtrl = TextEditingController();

  //local filter: the api has no search for routes and the list is small
  List<RouteModel> get _visible {
    final query = cubit.query.value.trim().toLowerCase();
    if (query.isEmpty) return cubit.routes;
    return cubit.routes
        .where(
          (r) => [
            r.name,
            r.path,
            r.uri,
            r.description,
          ].any((field) => field.toLowerCase().contains(query)),
        )
        .toList();
  }

  void _syncSearch() {
    if (_searchCtrl.text != cubit.query.value) {
      _searchCtrl.text = cubit.query.value;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    cubit = app.di.find();
    cubit.query.addListener(_syncSearch);
    _searchCtrl.text = cubit.query.value;
    if (cubit.state is RoutesInitialState) {
      cubit.search();
    }
  }

  @override
  void dispose() {
    cubit.query.removeListener(_syncSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onState(BuildContext context, RoutesState state) {
    final intl = context.intl;
    if (state is RoutesBackupProcessingState ||
        state is RoutesDeleteProcessingState) {
      app.loading.show();
    } else if (state is RoutesBackupOkState) {
      app.loading.hide();
      app.snack.showSuccess(
        message: intl.routes.backupSaved(count: state.count),
      );
    } else if (state is RoutesDeleteOkState) {
      app.loading.hide();
      app.snack.showSuccess(message: intl.routes.deleted(name: state.name));
    } else if (state is RoutesBackupErrorState) {
      app.loading.hide();
      app.snack.showError(message: state.exception.message);
    } else if (state is RoutesDeleteErrorState) {
      app.loading.hide();
      app.snack.showError(message: state.exception.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutesCubit, RoutesState>(
      listener: _onState,
      buildWhen: (previous, current) => current is RoutesSearchState,
      builder: (context, state) {
        if (state is RoutesSearchErrorState && !cubit.loaded) {
          return ErrorPage(
            errorMessage: state.exception.message,
            buttonText: context.intl.actions.tryAgain,
            onPressed: cubit.search,
          );
        }
        final loading = !cubit.loaded;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              AppSearchField(
                controller: _searchCtrl,
                hint: context.intl.routes.search,
                clearLabel: context.intl.actions.clearSearch,
                onChanged: (value) => cubit.query.value = value,
                onClear: () => cubit.query.value = '',
              ),
              const SizedBox(height: 20),
              if (loading)
                _buildGrid(List.generate(4, (_) => const _RouteCardSkeleton()))
              else
                _buildBody(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final count = cubit.routes.length;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              intl.routes.routes,
              style: TextStyle(
                fontSize: 26,
                height: 32 / 26,
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count == 1
                  ? intl.routes.oneRoute
                  : intl.routes.manyRoutes(count: count),
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: intl.routes.backup,
              icon: app.assets.icons.actions.download,
              kind: AppButtonKind.outlined,
              onPressed: cubit.backup,
            ),
            const SizedBox(width: 8),
            AppButton(
              label: intl.routes.restore,
              icon: app.assets.icons.actions.upload,
              kind: AppButtonKind.outlined,
              onPressed: RoutesRestoreDialog.show,
            ),
            Container(
              width: 1,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: c.outlineField,
            ),
            AppButton(
              label: intl.routes.createRoute,
              icon: app.assets.icons.actions.add,
              onPressed: RoutesFormScreen.navigator.create,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final intl = context.intl;
    final visible = _visible;
    if (visible.isEmpty) {
      final noRoutes = cubit.routes.isEmpty;
      return Padding(
        padding: const EdgeInsets.only(top: 44),
        child: Center(
          child: EmptyState(
            icon: app.assets.icons.general.search,
            title: noRoutes
                ? intl.routes.noRoutesYet
                : intl.routes.noMatches(query: cubit.query.value),
            subtitle: intl.routes.noMatchesHint,
            action: AppButton(
              label: intl.routes.createRoute,
              onPressed: RoutesFormScreen.navigator.create,
            ),
          ),
        ),
      );
    }
    return _buildGrid([
      for (final route in visible)
        _RouteCard(route: route, onDelete: () => _confirmDelete(route)),
    ]);
  }

  ///like a css auto-fill grid: as many 400 px+ columns as fit, cards of a row share their height
  Widget _buildGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = max(
          1,
          ((constraints.maxWidth + _gap) / (_minCardWidth + _gap)).floor(),
        );
        return Column(
          children: [
            for (var i = 0; i < cards.length; i += columns)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : _gap),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < columns; col++) ...[
                        if (col > 0) const SizedBox(width: _gap),
                        Expanded(
                          child: i + col < cards.length
                              ? cards[i + col]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(RouteModel route) async {
    final confirmed = await app.dialog.open<bool>(
      dialog: _DeleteRouteDialog(route: route),
    );
    if (confirmed == true) cubit.delete(route: route);
  }
}

class _RouteCard extends StatefulWidget {
  final RouteModel route;
  final VoidCallback onDelete;

  const _RouteCard({required this.route, required this.onDelete});

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool _hovered = false;

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    app.snack.showSuccess(message: app.intl.actions.copiedToClipboard);
  }

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final route = widget.route;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: motion(context, const Duration(milliseconds: 150)),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _hovered ? c.textTertiary : c.outlineCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19,
                          height: 26 / 19,
                          fontWeight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route.description.isEmpty
                            ? intl.routes.noDescription
                            : route.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppIconButton(
                  icon: app.assets.icons.actions.edit,
                  tooltip: intl.routes.edit,
                  onPressed: () =>
                      RoutesFormScreen.navigator.edit(model: route),
                ),
                AppIconButton(
                  icon: app.assets.icons.actions.duplicate,
                  tooltip: intl.routes.duplicate,
                  onPressed: () =>
                      RoutesFormScreen.navigator.duplicate(model: route),
                ),
                AppIconButton(
                  icon: app.assets.icons.actions.delete,
                  tooltip: intl.routes.delete,
                  hoverColor: c.softRed,
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 12),
                decoration: BoxDecoration(
                  color: c.night,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.outlineSoft),
                ),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _urlRow(
                        intl.routes.from,
                        route.enterPoint,
                        intl.routes.copyFrom,
                        false,
                      ),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.fromLTRB(0, 10, 6, 2),
                        color: c.outlineSoft,
                      ),
                      _urlRow(
                        intl.routes.to,
                        route.redirectTo,
                        intl.routes.copyTo,
                        true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _urlRow(String caption, String url, String copyLabel, bool accent) {
    final c = app.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CaptionText(caption, color: accent ? c.lilac : c.textTertiary),
            AppIconButton(
              icon: app.assets.icons.actions.duplicate,
              tooltip: copyLabel,
              size: 32,
              iconSize: 15,
              radius: 8,
              color: c.textTertiary,
              onPressed: () => _copy(url),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            url,
            style: monoStyle(size: 13, height: 20 / 13, color: c.text),
          ),
        ),
      ],
    );
  }
}

class _RouteCardSkeleton extends StatelessWidget {
  const _RouteCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.raised),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton(width: 140, height: 20),
              AppSkeleton(width: 110, height: 32, radius: 10),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.outlineSoft),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 40, height: 10, radius: 4),
                SizedBox(height: 8),
                AppSkeleton(width: double.infinity, height: 14),
                SizedBox(height: 14),
                AppSkeleton(width: 28, height: 10, radius: 4),
                SizedBox(height: 8),
                AppSkeleton(width: 260, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteRouteDialog extends StatelessWidget {
  final RouteModel route;

  const _DeleteRouteDialog({required this.route});

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    return DialogFrame(
      width: 420,
      radius: 28,
      color: c.toast,
      borderColor: c.outlineCard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xff8c1d18),
                shape: BoxShape.circle,
              ),
              child: app.assets.icons.actions.delete.build(
                size: 26,
                color: const Color(0xfff9dedc),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              intl.delete.title,
              style: TextStyle(
                fontSize: 22,
                height: 28 / 22,
                fontWeight: FontWeight.w500,
                color: c.text,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: '${intl.delete.descriptionStart} ',
                children: [
                  TextSpan(
                    text: route.path,
                    style: monoStyle(size: 14, color: c.text),
                  ),
                  TextSpan(text: ' ${intl.delete.descriptionEnd}'),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 20 / 14, color: c.label),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.outlineCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RouteUrlBlock(
                    caption: intl.routes.from,
                    url: route.enterPoint,
                    fontSize: 12,
                    urlColor: c.label,
                  ),
                  const SizedBox(height: 6),
                  RouteUrlBlock(
                    caption: intl.routes.to,
                    url: route.redirectTo,
                    accent: true,
                    fontSize: 12,
                    urlColor: c.label,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: intl.actions.cancel,
                    kind: AppButtonKind.outlined,
                    height: 46,
                    radius: 23,
                    autofocus: true, //so Enter doesn't delete by accident
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: intl.delete.confirm,
                    icon: app.assets.icons.actions.delete,
                    kind: AppButtonKind.softDanger,
                    height: 46,
                    radius: 23,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
