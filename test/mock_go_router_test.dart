import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jugnu/jugnu.dart';
import 'package:jugnu/testing.dart';

void main() {
  test('records calls and keeps a stack', () async {
    final router = MockGoRouter(routes: {'user': '/users/:id'});

    router.go('/home');
    final result = router.push<String>('/edit');
    expect(router.stack, ['/home', '/edit']);
    expect(router.canPop(), isTrue);

    router.pop('saved');
    expect(await result, 'saved');
    expect(router, isAt('/home'));

    router.goNamed(
      'user',
      pathParameters: {'id': '7'},
      queryParameters: {'tab': 'a'},
    );
    expect(router.location, '/users/7?tab=a');
    expect(router.calls.map((call) => call.kind), [
      NavigationKind.go,
      NavigationKind.push,
      NavigationKind.pop,
      NavigationKind.go,
    ]);
  });

  test('stubbed results complete right away', () async {
    final router = MockGoRouter()..stubResult('/pick', 3);
    expect(await router.push<int>('/pick'), 3);
    expect(router.location, '/');
  });

  test('unknown route names throw', () {
    expect(() => MockGoRouter().goNamed('nope'), throwsStateError);
  });

  testWidgets('context helpers reach the mock', (tester) async {
    final router = MockGoRouter()..stubResult('/pick', 5);
    int? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: MockGoRouterProvider(
          router: router,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await context.pushForResult<int>('/pick');
                if (context.mounted) context.go('/done');
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();

    expect(picked, 5);
    expect(router.calls.last, const NavigationCall(NavigationKind.go, '/done'));
  });
}
