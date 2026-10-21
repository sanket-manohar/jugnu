import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jugnu/jugnu.dart';
import 'package:jugnu/testing.dart';

void main() {
  GoRouter buildRouter() => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (_, _) => const SizedBox(),
        routes: [
          GoRoute(
            path: 'users/:id',
            name: 'user',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      ),
      GoRoute(path: '/sheet', builder: (_, _) => const SizedBox()),
    ],
  );

  tearDown(JugnuDebug.detach);

  test('snapshot is null until a router is attached', () {
    expect(JugnuDebug.snapshot(), isNull);
  });

  testWidgets('snapshot lists the stack, root first', (tester) async {
    final router = buildRouter();
    JugnuDebug.attach(router);
    await pumpRouter(tester, router);
    router.go('/users/42?tab=posts');
    await tester.pumpAndSettle();
    unawaitedPush(router);
    await tester.pumpAndSettle();

    final snapshot = JugnuDebug.snapshot()!;
    expect(snapshot['version'], JugnuDebug.protocolVersion);
    expect(snapshot['location'], '/sheet');

    final stack = (snapshot['stack']! as List).cast<Map<String, Object?>>();
    expect(stack.map((entry) => entry['fullPath']), [
      '/',
      '/users/:id',
      '/sheet',
    ]);
    expect(stack[1]['name'], 'user');
    expect(stack[1]['pathParameters'], {'id': '42'});
    expect(stack[0]['pathParameters'], isEmpty);
  });

  testWidgets('describeRoutes flattens the route tree', (tester) async {
    final routes = buildRouter().describeRoutes();
    expect(
      routes.expand((route) => route.flattened).map((route) => route.fullPath),
      ['/', '/users/:id', '/sheet'],
    );
  });
}

void unawaitedPush(GoRouter router) => router.push<void>('/sheet');
