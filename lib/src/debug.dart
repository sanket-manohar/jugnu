import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'links/router_routes.dart';

/// Shares the live navigation stack with developer tools, such as the Jugnu
/// extension for VS Code.
///
/// Call [attach] once, after creating the router:
///
/// ```dart
/// final router = GoRouter(routes: [...]);
///
/// void main() {
///   JugnuDebug.attach(router);
///   runApp(MaterialApp.router(routerConfig: router));
/// }
/// ```
///
/// Nothing happens in release builds.
///
/// Tools talk to the app through the Dart VM service:
///
/// * A `jugnu.navigation` event is posted on every route change.
/// * `ext.jugnu.getStack` returns the current stack.
/// * `ext.jugnu.getRoutes` returns the route tree.
/// * `ext.jugnu.go` and `ext.jugnu.push` navigate to the `location`
///   parameter.
///
/// Every payload carries a `version` field, currently [protocolVersion].
abstract final class JugnuDebug {
  /// The version of the payloads sent to tools.
  static const protocolVersion = 1;

  static GoRouter? _router;
  static bool _registered = false;

  /// Starts reporting navigation for [router].
  ///
  /// Calling it again with another router switches to that router.
  static void attach(GoRouter router) {
    if (kReleaseMode) return;
    detach();
    _router = router;
    router.routerDelegate.addListener(_post);
    _register();
    _post();
  }

  /// Stops reporting navigation.
  static void detach() {
    _router?.routerDelegate.removeListener(_post);
    _router = null;
  }

  /// The current navigation stack, root first, in the shape sent to tools.
  ///
  /// Returns null when no router is attached.
  static Map<String, Object?>? snapshot() {
    final router = _router;
    if (router == null) return null;
    final matches = router.routerDelegate.currentConfiguration;
    final stack = <Map<String, Object?>>[];

    void visit(List<RouteMatchBase> entries) {
      for (final match in entries) {
        if (match is ShellRouteMatch) {
          visit(match.matches);
        } else if (match is ImperativeRouteMatch) {
          final pushed = match.matches;
          stack.add(
            _entry(
              router,
              pushed.last.route,
              pushed.uri,
              pushed.pathParameters,
            ),
          );
        } else if (match is RouteMatch) {
          stack.add(
            _entry(
              router,
              match.route,
              Uri.parse(match.matchedLocation),
              matches.pathParameters,
            ),
          );
        }
      }
    }

    visit(matches.matches);

    return {
      'version': protocolVersion,
      'location': stack.isEmpty ? '${matches.uri}' : stack.last['location'],
      'stack': stack,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, Object?> _entry(
    GoRouter router,
    GoRoute route,
    Uri uri,
    Map<String, String> pathParameters,
  ) {
    final fullPath = router.configuration.locationForRoute(route) ?? route.path;
    return {
      'location': uri.toString(),
      'path': route.path,
      'fullPath': fullPath,
      if (route.name != null) 'name': route.name,
      'pathParameters': {
        for (final MapEntry(:key, :value) in pathParameters.entries)
          if (fullPath.contains(':$key')) key: value,
      },
      'queryParameters': uri.queryParameters,
    };
  }

  static void _post() {
    final data = snapshot();
    if (data != null) developer.postEvent('jugnu.navigation', data);
  }

  static void _register() {
    if (_registered) return;
    _registered = true;

    void handle(String method, Object? Function(Map<String, String>) answer) {
      developer.registerExtension(method, (_, parameters) async {
        try {
          return developer.ServiceExtensionResponse.result(
            jsonEncode(answer(parameters)),
          );
        } on Object catch (error) {
          return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.extensionError,
            '$error',
          );
        }
      });
    }

    handle(
      'ext.jugnu.getStack',
      (_) => snapshot() ?? {'version': protocolVersion},
    );
    handle(
      'ext.jugnu.getRoutes',
      (_) => {
        'version': protocolVersion,
        'routes': [
          for (final route in _router?.describeRoutes() ?? const [])
            route.toJson(),
        ],
      },
    );
    handle('ext.jugnu.go', (parameters) {
      _router!.go(parameters['location']!);
      return {'version': protocolVersion, 'ok': true};
    });
    handle('ext.jugnu.push', (parameters) {
      _router!.push<Object?>(parameters['location']!);
      return {'version': protocolVersion, 'ok': true};
    });
  }
}
