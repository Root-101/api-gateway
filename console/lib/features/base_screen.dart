import 'package:console/app_exporter.dart';
import 'package:console/features/language/view/language_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

///shell of the logged-in screens: collapsible rail + content (with the offline banner on top)
class BaseScreen extends StatefulWidget {
  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  const BaseScreen(this.navigationShell, {super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  static const double _collapsed = 80;
  static const double _expanded = 256;

  bool _open = false;

  void _onGatewayChange(BuildContext context, GatewayStatus status) {
    if (status.offline) return;
    app.snack.showSuccess(message: context.intl.offline.restored);
    app.di.find<RoutesCubit>().search(emitLoading: false);
    final logs = app.di.find<LogsCubit>();
    if (logs.state is! LogsInitialState) logs.search();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GatewayStatusCubit, GatewayStatus>(
      listenWhen: (previous, current) => previous.offline != current.offline,
      listener: _onGatewayChange,
      child: Scaffold(
        body: Row(
          children: [
            _buildRail(context),
            Expanded(
              child: GridBackground(
                child: BlocBuilder<GatewayStatusCubit, GatewayStatus>(
                  buildWhen: (previous, current) =>
                      previous.offline != current.offline ||
                      previous.retrying != current.retrying,
                  builder: (context, status) => Column(
                    children: [
                      if (status.offline) _OfflineBanner(status),
                      Expanded(
                        child: IgnorePointer(
                          ignoring: status.offline,
                          child: AnimatedOpacity(
                            opacity: status.offline ? 0.55 : 1,
                            duration: motion(
                              context,
                              const Duration(milliseconds: 200),
                            ),
                            child: widget.navigationShell,
                          ),
                        ),
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

  Widget _buildRail(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final index = widget.navigationShell.currentIndex;
    final duration = motion(context, const Duration(milliseconds: 280));
    return AnimatedContainer(
      width: _open ? _expanded : _collapsed,
      duration: duration,
      curve: appEase,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: c.rail,
        border: Border(right: BorderSide(color: c.raised)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: Stack(
              children: [
                Positioned(
                  left: 26,
                  top: 18,
                  child: Row(
                    children: [
                      const AppLogo(width: 28),
                      const SizedBox(width: 12),
                      _RailLabel(
                        open: _open,
                        child: const AppWordmark(size: 18, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 8,
                  child: _buildNotch(context, duration),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            color: c.raised,
          ),
          _RailItem(
            icon: app.assets.icons.routes,
            label: intl.routes.routes,
            open: _open,
            selected: index == 0,
            onTap: () => widget.navigationShell.goBranch(0),
            trailing: BlocBuilder<RoutesCubit, RoutesState>(
              builder: (context, _) =>
                  _CountBadge(app.di.find<RoutesCubit>().routes.length),
            ),
          ),
          const SizedBox(height: 4),
          _RailItem(
            icon: app.assets.icons.logs,
            label: intl.logs.logs,
            open: _open,
            selected: index == 1,
            onTap: () => widget.navigationShell.goBranch(1),
          ),
          const Spacer(),
          _buildFooter(context, duration),
        ],
      ),
    );
  }

  Widget _buildNotch(BuildContext context, Duration duration) {
    final c = app.colors;
    final label = _open
        ? context.intl.app.collapseMenu
        : context.intl.app.expandMenu;
    return Tooltip(
      message: label,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
          side: BorderSide(color: c.outlineCard),
        ),
        child: InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
          child: SizedBox(
            width: 16,
            height: 48,
            child: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: duration,
              curve: appEase,
              child: Center(
                child: app.assets.icons.general.chevronRight.build(
                  size: 12,
                  color: c.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ///collapsed the three controls stack in a column, expanded they line up in a row
  Widget _buildFooter(BuildContext context, Duration duration) {
    final c = app.colors;
    //shortcut: AnimatedPositioned has no delay, so the 0/40/80 ms stagger is done with longer durations
    Duration staggered(int extra) => duration == Duration.zero
        ? duration
        : Duration(milliseconds: 300 + extra);
    return AnimatedContainer(
      height: _open ? 44 : 128,
      duration: duration,
      curve: appEase,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedPositioned(
            left: 12,
            top: _open ? 2 : 0,
            duration: staggered(0),
            curve: appEase,
            child: const LanguageWidget(compact: true),
          ),
          AnimatedPositioned(
            left: _open ? 78 : 18,
            top: _open ? 0 : 54,
            duration: staggered(40),
            curve: appEase,
            child: AppIconButton(
              icon: app.assets.icons.actions.logout,
              tooltip: context.intl.app.logout,
              size: 44,
              background: c.raised,
              color: c.text,
              onPressed: () => app.di.find<AuthCubit>().logout(),
            ),
          ),
          AnimatedPositioned(
            left: _open ? 164 : 0,
            top: _open ? 14 : 110,
            width: 80,
            duration: staggered(80),
            curve: appEase,
            child: FutureBuilder<String?>(
              future: appVersion,
              builder: (context, snapshot) => Text(
                snapshot.data == null ? '' : 'v${snapshot.data}',
                textAlign: TextAlign.center,
                style: monoStyle(
                  size: 11,
                  height: 16 / 11,
                  color: c.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailLabel extends StatelessWidget {
  final bool open;
  final Widget child;

  const _RailLabel({required this.open, required this.child});

  @override
  Widget build(BuildContext context) {
    final duration = motion(context, const Duration(milliseconds: 280));
    return AnimatedOpacity(
      opacity: open ? 1 : 0,
      duration: duration,
      curve: open ? const Interval(0.35, 1) : Curves.linear,
      child: AnimatedSlide(
        offset: open ? Offset.zero : const Offset(-0.1, 0),
        duration: duration,
        curve: appEase,
        child: child,
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final SvgAsset icon;
  final String label;
  final bool open;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _RailItem({
    required this.icon,
    required this.label,
    required this.open,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final color = selected ? c.onSelected : c.label;
    final item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: selected ? c.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            //the row keeps its open width while the rail animates, the rail clips it
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: 232,
              child: SizedBox(
                width: 232,
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Center(child: icon.build(size: 22, color: color)),
                    ),
                    Expanded(
                      child: _RailLabel(
                        open: open,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _RailLabel(open: open, child: trailing!),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      selected: selected,
      child: open ? item : Tooltip(message: label, child: item),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.lilac.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: c.lilac,
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final GatewayStatus status;

  const _OfflineBanner(this.status);

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final time = status.lastLoadedAt == null
        ? '--:--'
        : app.dateFormatter.clock.format(status.lastLoadedAt!);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: c.offline.withValues(alpha: 0.10),
          border: Border(
            bottom: BorderSide(color: c.offline.withValues(alpha: 0.4)),
          ),
        ),
        child: Row(
          children: [
            app.assets.icons.general.wifiOff.build(size: 18, color: c.offline),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${intl.offline.title}  ',
                      style: TextStyle(
                        color: c.offline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text:
                          '${intl.offline.detail(time: time)} '
                          '${status.retrying ? intl.offline.retrying : intl.offline.retryAuto}',
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 13, height: 18 / 13, color: c.text),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: status.retrying
                  ? null
                  : app.di.find<GatewayStatusCubit>().retry,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.offline,
                disabledForegroundColor: c.offline,
                side: BorderSide(color: c.offline.withValues(alpha: 0.6)),
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status.retrying) ...[
                    SmallSpinner(color: c.offline),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    status.retrying
                        ? intl.offline.retryingButton
                        : intl.offline.retryNow,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
