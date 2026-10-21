import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jugnu/jugnu.dart';
import 'package:jugnu/testing.dart';

void main() {
  late GoRouter router;
  Object? received;

  setUp(() {
    received = 'nothing yet';
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => TextButton(
            onPressed: () async =>
                received = await context.pushForResult<int>('/pick'),
            child: const Text('pick'),
          ),
        ),
        GoRoute(
          path: '/pick',
          builder: (context, state) => Column(
            children: [
              TextButton(
                onPressed: () => context.popWithResult(7, fallback: '/'),
                child: const Text('seven'),
              ),
              TextButton(
                onPressed: () => context.popWithResult('wrong type'),
                child: const Text('wrong'),
              ),
            ],
          ),
        ),
      ],
    );
  });

  testWidgets('pushForResult returns the popped value', (tester) async {
    await pumpRouter(tester, router);
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('seven'));
    await tester.pumpAndSettle();
    expect(received, 7);
    expectRoute(router, '/');
  });

  testWidgets('pushForResult returns null for the wrong type', (tester) async {
    await pumpRouter(tester, router);
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('wrong'));
    await tester.pumpAndSettle();
    expect(received, isNull);
  });

  testWidgets('popWithResult goes to the fallback when it cannot pop', (
    tester,
  ) async {
    await pumpRouter(tester, router);
    await openDeepLink(tester, '/pick');
    expect(router.canPop(), isFalse);
    await tester.tap(find.text('seven'));
    await tester.pumpAndSettle();
    expectRoute(router, '/');
  });
}
