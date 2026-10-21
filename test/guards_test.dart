import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jugnu/jugnu.dart';
import 'package:jugnu/testing.dart';

GoRouter _router(List<RouteGuard> list) => GoRouter(
  redirect: guards(list),
  routes: [
    for (final path in ['/', '/login', '/a', '/b', '/admin'])
      GoRoute(path: path, builder: (_, _) => Text(path)),
  ],
);

void main() {
  testWidgets('the first guard to redirect wins', (tester) async {
    final visited = <String>[];
    final router = _router([
      (context, state) {
        visited.add(state.uri.path);
        return null;
      },
      (context, state) async => state.uri.path == '/admin' ? '/login' : null,
      (context, state) {
        if (state.uri.path == '/admin') visited.add('third guard ran');
        return null;
      },
    ]);
    await pumpRouter(tester, router);
    await expectRedirect(tester, router, from: '/admin', to: '/login');
    expect(visited, ['/', '/admin', '/login']);
  });

  testWidgets('a redirect to the current location is ignored', (tester) async {
    final router = _router([(context, state) => '/login']);
    await pumpRouter(tester, router);
    expectRoute(router, '/login');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a bounce between two locations is stopped', (tester) async {
    final router = _router([
      (context, state) => switch (state.uri.path) {
        '/a' => '/b',
        '/b' => '/a',
        _ => null,
      },
    ]);
    await pumpRouter(tester, router);
    router.go('/a');
    await tester.pumpAndSettle();
    expectRoute(router, '/b');
    expect(tester.takeException(), isNull);
  });
}
