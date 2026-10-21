import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jugnu/src/links/route_scanner.dart';

void main() {
  final source = File('test/fixtures/app_router.dart.txt').readAsStringSync();
  final routes = const RouteScanner().scan(source, file: 'app_router.dart');
  final all = routes.expand((route) => route.flattened).toList();

  test('reads nested routes with full paths', () {
    expect(all.map((route) => route.fullPath), [
      '/',
      '/users/:id',
      '/users/:id/posts/:postId',
      '/feed',
      '/settings',
      '/search',
      '/about',
      '/about/team',
    ]);
  });

  test('reads names, including go_router_builder type names', () {
    expect(all.map((route) => route.name), [
      'home',
      'user',
      'post',
      'feed',
      null,
      'search',
      'AboutRoute',
      'TeamRoute',
    ]);
  });

  test('ignores commented-out routes and interpolated paths', () {
    expect(all.where((route) => route.fullPath.contains('hidden')), isEmpty);
    expect(all.where((route) => route.name == 'skipped'), isEmpty);
  });

  test('records file and line', () {
    final user = all.firstWhere((route) => route.name == 'user');
    expect(user.file, 'app_router.dart');
    expect(user.line, 9);
    expect(user.parameters, ['id']);
  });
}
