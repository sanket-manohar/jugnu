import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jugnu/jugnu.dart';
import 'package:jugnu/testing.dart';

enum Tab { posts, likes }

void main() {
  final id = RouteParam.integer('id');
  final tab = RouteParam.enumeration(
    'tab',
    Tab.values,
    defaultValue: Tab.posts,
  );
  final since = RouteParam.dateTime('since');
  final draft = RouteParam.boolean('draft', defaultValue: false);
  final price = RouteParam.decimal('price');
  final query = RouteParam.string('q');

  late GoRouterState captured;

  GoRouter router() => GoRouter(
    initialLocation: '/users/1',
    routes: [
      GoRoute(
        path: '/users/:id',
        builder: (context, state) {
          captured = state;
          return const SizedBox();
        },
      ),
    ],
  );

  testWidgets('reads path and query values with their types', (tester) async {
    await pumpRouter(tester, router());
    await openDeepLink(
      tester,
      '/users/42?tab=likes&since=2026-01-02T00:00:00.000&draft=1&price=9.5&q=a%20b',
    );
    expect(id.read(captured), 42);
    expect(tab.read(captured), Tab.likes);
    expect(since.read(captured), DateTime(2026, 1, 2));
    expect(draft.read(captured), isTrue);
    expect(price.read(captured), 9.5);
    expect(query.read(captured), 'a b');
  });

  testWidgets('falls back to defaults and throws without one', (tester) async {
    await pumpRouter(tester, router());
    await openDeepLink(tester, '/users/x?tab=unknown');
    expect(tab.read(captured), Tab.posts);
    expect(draft.read(captured), isFalse);
    expect(id.readOrNull(captured), isNull);
    expect(() => id.read(captured), throwsFormatException);
  });

  test('encodes values for the URL', () {
    expect(id.encode(42), '42');
    expect(tab.encode(Tab.likes), 'likes');
    expect(since.encode(DateTime(2026)), '2026-01-01T00:00:00.000');
    final custom = RouteParam<Duration>(
      'wait',
      parse: (value) => Duration(seconds: int.parse(value)),
      encode: (value) => '${value.inSeconds}',
    );
    expect(custom.encode(const Duration(minutes: 1)), '60');
  });
}
