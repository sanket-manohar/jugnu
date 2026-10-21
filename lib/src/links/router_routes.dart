import 'package:go_router/go_router.dart';

import 'deep_link_generator.dart';
import 'route_info.dart';
import 'route_pattern.dart';

/// Describes a live router's routes and builds deep links for them.
extension JugnuRoutes on GoRouter {
  /// The router's routes as [RouteInfo], with shell routes flattened away.
  List<RouteInfo> describeRoutes() => _describe(configuration.routes, '');

  /// A [DeepLinkGenerator] for this router's routes.
  ///
  /// ```dart
  /// final links = router.deepLinks(scheme: 'myapp', host: 'open');
  /// print(links.build('user', pathParameters: {'id': 42}));
  /// // myapp://open/users/42
  /// ```
  DeepLinkGenerator deepLinks({String? scheme, String? host}) =>
      DeepLinkGenerator(describeRoutes(), scheme: scheme, host: host);
}

List<RouteInfo> _describe(List<RouteBase> routes, String parentPath) => [
  for (final route in routes)
    if (route is GoRoute)
      _goRoute(route, RoutePattern.join(parentPath, route.path))
    else
      ..._describe(route.routes, parentPath),
];

RouteInfo _goRoute(GoRoute route, String fullPath) => RouteInfo(
  path: route.path,
  fullPath: fullPath,
  name: route.name,
  children: _describe(route.routes, fullPath),
);
