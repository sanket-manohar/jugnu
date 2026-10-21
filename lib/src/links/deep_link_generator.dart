import 'route_info.dart';
import 'route_pattern.dart';

/// Builds deep links for the routes of an app.
///
/// Give it the app's routes, either from a live router with
/// `router.deepLinks()` or from any list of [RouteInfo], and ask for a link
/// by route name or path pattern:
///
/// ```dart
/// final links = router.deepLinks(scheme: 'https', host: 'example.com');
///
/// links.build('user', pathParameters: {'id': 42}, queryParameters: {'tab': 'posts'});
/// // https://example.com/users/42?tab=posts
/// ```
///
/// Without a [scheme] the result is a plain location such as
/// `/users/42?tab=posts`, ready for `context.go`.
class DeepLinkGenerator {
  /// Creates a generator for [routes].
  ///
  /// [scheme] and [host] are used for every link, for example `https` and
  /// `example.com`, or a custom scheme such as `myapp`.
  DeepLinkGenerator(this.routes, {this.scheme, this.host});

  /// The top-level routes of the app.
  final List<RouteInfo> routes;

  /// The URL scheme, such as `https` or `myapp`. When null, [build] returns
  /// a location without scheme or host.
  final String? scheme;

  /// The host, such as `example.com`.
  final String? host;

  /// Every route, depth first.
  Iterable<RouteInfo> get allRoutes =>
      routes.expand((route) => route.flattened);

  /// Finds a route by its name, or failing that by its full path pattern.
  ///
  /// Returns null when nothing matches.
  RouteInfo? find(String nameOrPath) {
    for (final route in allRoutes) {
      if (route.name == nameOrPath) return route;
    }
    for (final route in allRoutes) {
      if (route.fullPath == nameOrPath) return route;
    }
    return null;
  }

  /// Builds a link to the route called [nameOrPath].
  ///
  /// Values in [pathParameters] and [queryParameters] are converted with
  /// `toString()`. A query value may also be an [Iterable] to repeat the key,
  /// as in `?tag=a&tag=b`.
  ///
  /// Throws an [ArgumentError] when the route is unknown or a path parameter
  /// is missing.
  Uri build(
    String nameOrPath, {
    Map<String, Object?> pathParameters = const {},
    Map<String, Object?> queryParameters = const {},
    String? fragment,
  }) {
    final route = find(nameOrPath);
    if (route == null) {
      throw ArgumentError.value(nameOrPath, 'nameOrPath', 'Unknown route');
    }
    return link(
      route.fullPath,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      fragment: fragment,
    );
  }

  /// Builds a link from a path [pattern] such as `/users/:id`, without
  /// looking it up in [routes].
  Uri link(
    String pattern, {
    Map<String, Object?> pathParameters = const {},
    Map<String, Object?> queryParameters = const {},
    String? fragment,
  }) {
    final path = RoutePattern(pattern).fill({
      for (final MapEntry(:key, :value) in pathParameters.entries)
        if (value != null) key: '$value',
    });
    final query = <String, Object>{
      for (final MapEntry(:key, :value) in queryParameters.entries)
        if (value is Iterable)
          key: [for (final item in value) '$item']
        else if (value != null)
          key: '$value',
    };
    return Uri(
      scheme: scheme,
      host: scheme == null ? null : (host ?? ''),
      path: path,
      queryParameters: query.isEmpty ? null : query,
      fragment: fragment,
    );
  }
}
