import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jugnu/jugnu.dart';
import 'package:jugnu/testing.dart';

void main() {
  late StatefulNavigationShell shell;

  GoRouter buildRouter() => GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          shell = navigationShell;
          return navigationShell;
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const Text('home'),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (_, _) => const Text('detail'),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/other', builder: (_, _) => const Text('other')),
            ],
          ),
        ],
      ),
    ],
  );

  testWidgets('switching tabs keeps state, reselecting resets', (tester) async {
    final router = buildRouter();
    await pumpRouter(tester, router);
    router.go('/home/detail');
    await tester.pumpAndSettle();

    shell.switchTab(1);
    await tester.pumpAndSettle();
    expectRoute(router, '/other');

    shell.switchTab(0);
    await tester.pumpAndSettle();
    expectRoute(router, '/home/detail');

    shell.switchTab(0);
    await tester.pumpAndSettle();
    expectRoute(router, '/home');
  });

  testWidgets('resetTab goes back to the first page', (tester) async {
    final router = buildRouter();
    await pumpRouter(tester, router);
    router.go('/home/detail');
    await tester.pumpAndSettle();
    shell.resetTab();
    await tester.pumpAndSettle();
    expectRoute(router, '/home');
  });
}
