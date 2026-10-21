import 'package:flutter_test/flutter_test.dart';
import 'package:jugnu/jugnu.dart';

void main() {
  const routes = [
    RouteInfo(
      path: '/users',
      fullPath: '/users',
      name: 'users',
      children: [RouteInfo(path: ':id', fullPath: '/users/:id', name: 'user')],
    ),
  ];

  group('RoutePattern', () {
    test('lists parameters', () {
      expect(RoutePattern('/a/:id/b/:slug').parameters, ['id', 'slug']);
      expect(RoutePattern(r'/a/:id(\d+)').parameters, ['id']);
    });

    test('fills and encodes parameters', () {
      expect(RoutePattern('/users/:id').fill({'id': 'a b'}), '/users/a%20b');
    });

    test('throws on a missing parameter', () {
      expect(() => RoutePattern('/users/:id').fill({}), throwsArgumentError);
    });

    test('joins paths like go_router', () {
      expect(RoutePattern.join('/', 'users'), '/users');
      expect(RoutePattern.join('/users', ':id'), '/users/:id');
      expect(RoutePattern.join('', '/feed'), '/feed');
    });
  });

  group('DeepLinkGenerator', () {
    test('builds a location without a scheme', () {
      final links = DeepLinkGenerator(routes);
      expect(
        links.build('user', pathParameters: {'id': 42}).toString(),
        '/users/42',
      );
    });

    test('builds full URLs with query parameters', () {
      final links = DeepLinkGenerator(
        routes,
        scheme: 'https',
        host: 'example.com',
      );
      final link = links.build(
        '/users/:id',
        pathParameters: {'id': 7},
        queryParameters: {
          'tab': 'posts',
          'tag': ['a', 'b'],
          'skip': null,
        },
      );
      expect(
        link.toString(),
        'https://example.com/users/7?tab=posts&tag=a&tag=b',
      );
    });

    test('supports custom schemes', () {
      final links = DeepLinkGenerator(routes, scheme: 'myapp', host: 'open');
      expect(links.build('users').toString(), 'myapp://open/users');
    });

    test('keeps encoded path values intact', () {
      final links = DeepLinkGenerator(routes);
      expect(
        links.build('user', pathParameters: {'id': 'a/b c'}).toString(),
        '/users/a%2Fb%20c',
      );
    });

    test('throws for unknown routes', () {
      expect(
        () => DeepLinkGenerator(routes).build('nope'),
        throwsArgumentError,
      );
    });

    test('round-trips RouteInfo through JSON', () {
      final copy = RouteInfo.fromJson(routes.first.toJson());
      expect(copy.flattened.map((route) => route.fullPath), [
        '/users',
        '/users/:id',
      ]);
    });
  });
}
