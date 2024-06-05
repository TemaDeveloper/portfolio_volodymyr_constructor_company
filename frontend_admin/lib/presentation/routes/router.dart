import 'package:nimbus/presentation/pages/auth/auth_page.dart';
import 'package:auto_route/annotations.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    // initial route is named "/"
    AutoRoute(page: AuthPage, initial: true)
  ],
)
class $AppRouter {}
