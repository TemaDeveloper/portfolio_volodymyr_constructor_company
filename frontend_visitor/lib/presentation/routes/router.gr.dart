import 'package:auto_route/auto_route.dart' as _i2;
import 'package:flutter/material.dart' as _i3;

import '../pages/home/home_page.dart' as _i1;
import '../pages/projects/projects_page.dart' as _i4;
import '../pages/project_details/project_details_page.dart' as _i5;

class AppRouter extends _i2.RootStackRouter {
  AppRouter([_i3.GlobalKey<_i3.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i2.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData, child: _i1.HomePage());
    },
    ProjectsRoute.name: (routeData) {
      final args = routeData.argsAs<ProjectsRouteArgs>();
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i4.ProjectsPage(
            title: args.title,
            description: args.description,
          ));
    },
    ProjectDetailsRoute.name: (routeData) {
      final args = routeData.argsAs<ProjectDetailsRouteArgs>();
      return _i2.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i5.ProjectDetailsPage(
            projectId: args.projectId,
          ));
    },
  };

  @override
  List<_i2.RouteConfig> get routes => [
        _i2.RouteConfig(HomeRoute.name, path: '/'),
        _i2.RouteConfig(ProjectsRoute.name, path: '/projects'),
        _i2.RouteConfig(ProjectDetailsRoute.name, path: '/project-details'),
      ];
}

/// generated route for
/// [_i1.HomePage]
class HomeRoute extends _i2.PageRouteInfo<void> {
  const HomeRoute() : super(HomeRoute.name, path: '/');

  static const String name = 'HomeRoute';
}

/// generated route for
/// [_i4.ProjectsPage]
class ProjectsRoute extends _i2.PageRouteInfo<ProjectsRouteArgs> {
  ProjectsRoute({required String title, required String description})
      : super(
          ProjectsRoute.name,
          path: '/projects',
          args: ProjectsRouteArgs(title: title, description: description),
        );

  static const String name = 'ProjectsRoute';
}

class ProjectsRouteArgs {
  final String title;
  final String description;

  ProjectsRouteArgs({required this.title, required this.description});
}

/// generated route for
/// [_i5.ProjectDetailsPage]
class ProjectDetailsRoute extends _i2.PageRouteInfo<ProjectDetailsRouteArgs> {
  ProjectDetailsRoute({required int projectId})
      : super(
          ProjectDetailsRoute.name,
          path: '/project-details',
          args: ProjectDetailsRouteArgs(projectId: projectId),
        );

  static const String name = 'ProjectDetailsRoute';
}

class ProjectDetailsRouteArgs {
  final int projectId;

  ProjectDetailsRouteArgs({required this.projectId});
}
