import 'package:api_gateway_front/app_exporter.dart';
import 'package:api_gateway_front/features/language/view/language_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

///este es el screen base con el bottom-nav-bar
class BaseScreen extends StatefulWidget {
  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  const BaseScreen(this.navigationShell, {super.key});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  bool _isRailExpanded = false;

  void _toggleRail() {
    setState(() {
      _isRailExpanded = !_isRailExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: NavigationRail(
              extended: _isRailExpanded,
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              //leading: const SizedBox.shrink(),
              leading: IconButton(
                icon: Icon(_isRailExpanded ? Icons.arrow_back_ios : Icons.menu),
                onPressed: _toggleRail,
              ),
              destinations: [
                NavigationRailDestination(
                  icon: app.assets.icons.gateway.build(),
                  label: Text(app.intl.routes),
                ),
                NavigationRailDestination(
                  icon: app.assets.icons.logs.build(),
                  label: Text(app.intl.logs),
                ),
              ],
              trailing: Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const LanguageWidget(),
                    app.dimensions.padding.m.gap(),
                    PrimaryButton.svgIcon(
                      onPressed: () {
                        app.di.find<AuthCubit>().logout();
                      },
                      buttonSize: 38,
                      icon: app.assets.icons.actions.logout,
                      iconColor: app.colors.neutral.white,
                    ),
                    app.dimensions.padding.l.gap(),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(index);
  }
}
