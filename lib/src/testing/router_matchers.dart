import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'mock_go_router.dart';

/// The current location of [router], for a real [GoRouter] or a
/// [MockGoRouter].
Uri currentLocation(GoRouter router) => router is MockGoRouter
    ? Uri.parse(router.location)
    : router.routerDelegate.currentConfiguration.uri;

/// Matches a [GoRouter] that is showing [location].
///
/// The path must match exactly. Query parameters are compared only when
/// [location] has some, and their order does not matter.
///
/// ```dart
/// expect(router, isAt('/users/42'));
/// expect(router, isAt('/search?q=shoes'));
/// ```
Matcher isAt(String location) => _IsAt(Uri.parse(location));

/// Checks that [router] is showing [location]. Same as
/// `expect(router, isAt(location))`.
void expectRoute(GoRouter router, String location, {String? reason}) =>
    expect(router, isAt(location), reason: reason);

/// Opens [from] and checks that the router ends up at [to].
///
/// Use it to test guards and redirects:
///
/// ```dart
/// testWidgets('signed-out users go to login', (tester) async {
///   await pumpRouter(tester, router);
///   await expectRedirect(tester, router, from: '/settings', to: '/login');
/// });
/// ```
Future<void> expectRedirect(
  WidgetTester tester,
  GoRouter router, {
  required String from,
  required String to,
}) async {
  router.go(from);
  await tester.pumpAndSettle();
  expect(router, isAt(to), reason: 'Expected $from to redirect to $to');
}

/// Pumps a `MaterialApp.router` driven by [router] and waits for the first
/// page to settle.
Future<void> pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

/// Delivers [link] to the app the way the operating system does when the user
/// taps a deep link, then waits for navigation to settle.
///
/// [link] may be a full URL such as `https://example.com/users/42` or
/// `myapp://open/users/42`, or a plain location such as `/users/42`. Only the
/// path, query and fragment reach the router, as on a real device.
///
/// The app must already be pumped, for example with [pumpRouter].
Future<void> openDeepLink(WidgetTester tester, String link) async {
  final uri = Uri.parse(link);
  final location = Uri(
    path: uri.path.isEmpty ? '/' : uri.path,
    query: uri.hasQuery ? uri.query : null,
    fragment: uri.hasFragment ? uri.fragment : null,
  ).toString();

  final message = const JSONMethodCodec().encodeMethodCall(
    MethodCall('pushRouteInformation', {'location': location, 'state': null}),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    message,
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// Opens [link] with [openDeepLink] and checks that [router] ends up at
/// [opens].
///
/// ```dart
/// await expectDeepLink(tester, router, 'myapp://open/users/42', opens: '/users/42');
/// ```
Future<void> expectDeepLink(
  WidgetTester tester,
  GoRouter router,
  String link, {
  required String opens,
}) async {
  await openDeepLink(tester, link);
  expect(router, isAt(opens), reason: 'Expected $link to open $opens');
}

class _IsAt extends Matcher {
  const _IsAt(this.expected);

  final Uri expected;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! GoRouter) return false;
    final actual = currentLocation(item);
    if (actual.path != expected.path) return false;
    if (!expected.hasQuery) return true;
    final want = expected.queryParametersAll;
    final got = actual.queryParametersAll;
    return want.length == got.length &&
        want.entries.every(
          (entry) =>
              got[entry.key]?.join('\u0000') == entry.value.join('\u0000'),
        );
  }

  @override
  Description describe(Description description) =>
      description.add('a GoRouter at $expected');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! GoRouter) return mismatchDescription.add('is not a GoRouter');
    return mismatchDescription.add('is at ${currentLocation(item)}');
  }
}
