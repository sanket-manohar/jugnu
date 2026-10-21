import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A check that runs before a location is shown.
///
/// Return null to let navigation continue, or a location to redirect to.
/// A guard that always returns null works as middleware, for example to log
/// screen views.
typedef RouteGuard =
    FutureOr<String?> Function(BuildContext context, GoRouterState state);

/// Combines [guards] into one redirect for `GoRouter.redirect` or
/// `GoRoute.redirect`.
///
/// Guards run in order and may be async. The first one to return a location
/// wins, and the rest are skipped.
///
/// Two kinds of redirect loop are prevented:
///
/// * A redirect to the location being shown is ignored, so a guard such as
///   "send signed-out users to /login" is safe to run on /login itself.
/// * When guards bounce between locations, as in /a → /b → /a, the chain is
///   stopped and the current location is allowed. A warning is printed in
///   debug builds.
///
/// ```dart
/// GoRouter(
///   redirect: guards([
///     (context, state) => auth.signedIn ? null : '/login',
///     (context, state) async => await flags.maintenance ? '/maintenance' : null,
///   ]),
///   routes: [...],
/// );
/// ```
GoRouterRedirect guards(List<RouteGuard> guards) {
  final chain = <String>[];
  String? lastTarget;

  return (context, state) async {
    final current = state.uri.toString();
    if (current != lastTarget) chain.clear();
    chain.add(current);

    for (final guard in guards) {
      if (!context.mounted) break;
      final target = await guard(context, state);
      if (target == null || _isSameLocation(target, state.uri)) continue;

      if (chain.any((visited) => _isSameLocation(target, Uri.parse(visited)))) {
        debugPrint(
          'jugnu: redirect loop stopped at $current (${chain.join(' → ')} → $target)',
        );
        break;
      }
      lastTarget = target;
      return target;
    }

    chain.clear();
    lastTarget = null;
    return null;
  };
}

bool _isSameLocation(String target, Uri current) {
  final uri = Uri.parse(target);
  if (uri.path != current.path) return false;
  return uri.query.isEmpty || uri.query == current.query;
}
