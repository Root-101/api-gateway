import 'package:console/app_exporter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///the side menu: logo, a notch that opens and closes it, map / routes / logs, and at the bottom
///language, logout and the version
class AppRail extends StatefulWidget {
  ///the branch shown: 0 map, 1 routes, 2 logs
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const AppRail({
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  @override
  State<AppRail> createState() => _AppRailState();
}

class _AppRailState extends State<AppRail> {
  static const double _collapsed = 80;
  static const double _expanded = 256;

  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = app.colors;
    final intl = context.intl;
    final index = widget.currentIndex;
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
                      RailLabel(
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
          RailItem(
            icon: app.assets.icons.gateway,
            label: intl.map.title,
            open: _open,
            selected: index == 0,
            onTap: () => widget.onSelect(0),
          ),
          const SizedBox(height: 4),
          RailItem(
            icon: app.assets.icons.routes,
            label: intl.routes.routes,
            open: _open,
            selected: index == 1,
            onTap: () => widget.onSelect(1),
            trailing: BlocBuilder<RoutesCubit, RoutesState>(
              builder: (context, _) =>
                  RailCountBadge(app.di.find<RoutesCubit>().routes.length),
            ),
          ),
          const SizedBox(height: 4),
          RailItem(
            icon: app.assets.icons.logs,
            label: intl.logs.logs,
            open: _open,
            selected: index == 2,
            onTap: () => widget.onSelect(2),
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
