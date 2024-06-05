import 'package:auto_route/auto_route.dart' as _i2;
import 'package:flutter/material.dart' as _i3;

import '../pages/auth/auth_page.dart' as _i1;
import '../pages/home/home_page.dart' as _i4;
import '../pages/home/upgrade_project_page.dart' as _i5; // Import UpgradeProjectPage

class AppRouter extends _i2.RootStackRouter {
  AppRouter([_i3.GlobalKey<_i3.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i2.PageFactory> pagesMap = {
    AuthRoute.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i1.AuthPage());
    },
    HomeRoute.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i4.HomePage());
    },
    UpgradeProjectRoute.name: (routeData) {
      final args = routeData.argsAs<UpgradeProjectRouteArgs>();
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i5.UpgradeProjectPage(
            title: args.title,
            description: args.description,
          ));
    },
  };

  @override
  List<_i2.RouteConfig> get routes => [
        _i2.RouteConfig(AuthRoute.name, path: '/'),
        _i2.RouteConfig(HomeRoute.name, path: '/admin-home'),
        _i2.RouteConfig(UpgradeProjectRoute.name, path: '/upgrade-project'), // Add route
      ];
}

/// generated route for
/// [_i1.AuthPage]
class AuthRoute extends _i2.PageRouteInfo<void> {
  const AuthRoute() : super(AuthRoute.name, path: '/');

  static const String name = 'AuthRoute';
}

/// generated route for
/// [_i4.HomePage]
class HomeRoute extends _i2.PageRouteInfo<void> {
  const HomeRoute() : super(HomeRoute.name, path: '/admin-home');

  static const String name = 'HomeRoute';
}

/// generated route for
/// [_i5.UpgradeProjectPage]
class UpgradeProjectRoute extends _i2.PageRouteInfo<UpgradeProjectRouteArgs> {
  UpgradeProjectRoute({
    required String title,
    required String description,
  }) : super(
          UpgradeProjectRoute.name,
          path: '/upgrade-project',
          args: UpgradeProjectRouteArgs(
            title: title,
            description: description,
          ),
        );

  static const String name = 'UpgradeProjectRoute';
}

class UpgradeProjectRouteArgs {
  final String title;
  final String description;

  UpgradeProjectRouteArgs({
    required this.title,
    required this.description,
  });
}
