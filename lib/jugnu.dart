/// Small helpers for go_router.
///
/// * Typed results: [JugnuResults.pushForResult] and
///   [JugnuResults.popWithResult].
/// * Async route guards without redirect loops: [guards].
/// * Typed path and query parameters that live in the URL: [RouteParam].
/// * Tab helpers for `StatefulShellRoute`: [JugnuShell].
/// * Deep links for any route: [DeepLinkGenerator] and
///   [JugnuRoutes.deepLinks].
/// * A debug hook for developer tools: [JugnuDebug].
///
/// Testing helpers live in `package:jugnu/testing.dart`.
library;

export 'src/debug.dart';
export 'src/guards.dart';
export 'src/links/deep_link_generator.dart';
export 'src/links/route_info.dart';
export 'src/links/route_pattern.dart';
export 'src/links/router_routes.dart';
export 'src/params.dart';
export 'src/results.dart';
export 'src/shell.dart';
