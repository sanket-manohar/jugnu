import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../links/route_pattern.dart';

/// The kind of a [NavigationCall].
enum NavigationKind {
  /// `go` or `goNamed`.
  go,

  /// `push` or `pushNamed`.
  push,

  /// `pushReplacement` or `pushReplacementNamed`.
  pushReplacement,

  /// `replace` or `replaceNamed`.
  replace,

  /// `pop`.
  pop,
}

/// One navigation call recorded by a [MockGoRouter].
@immutable
class NavigationCall {
  /// Creates a record of a navigation call.
  const NavigationCall(this.kind, this.location, {this.extra, this.result});

  /// What kind of call it was.
  final NavigationKind kind;

  /// The location navigated to. For [NavigationKind.pop], the location that
  /// was closed.
  final String location;

  /// The `extra` passed with the call.
  final Object? extra;

  /// The value passed to `pop`.
  final Object? result;

  @override
  bool operator ==(Object other) =>
      other is NavigationCall &&
      other.kind == kind &&
      other.location == location &&
      other.extra == extra &&
      other.result == result;

  @override
  int get hashCode => Object.hash(kind, location, extra, result);

  @override
  String toString() => '${kind.name}($location)';
}

/// A stand-in [GoRouter] for widget tests that records every navigation
/// call instead of building pages.
///
/// Wrap the widget under test with [MockGoRouterProvider] so that
/// `context.go`, `context.push` and friends reach the mock:
///
/// ```dart
/// final router = MockGoRouter(routes: {'user': '/users/:id'});
///
/// await tester.pumpWidget(
///   MaterialApp(home: MockGoRouterProvider(router: router, child: const ProfileButton())),
/// );
/// await tester.tap(find.text('Open profile'));
///
/// expect(router.location, '/users/42');
/// expect(router.calls.last, const NavigationCall(NavigationKind.push, '/users/42'));
/// ```
class MockGoRouter extends Fake implements GoRouter {
  /// Creates a mock that starts at [initialLocation].
  ///
  /// [routes] maps route names to path patterns, so the named methods such
  /// as `goNamed` can build locations.
  MockGoRouter({String initialLocation = '/', this.routes = const {}})
    : _stack = [_Entry(initialLocation)];

  /// Route names mapped to path patterns, such as `{'user': '/users/:id'}`.
  final Map<String, String> routes;

  /// Every navigation call, oldest first.
  final List<NavigationCall> calls = [];

  final List<_Entry> _stack;
  final Map<String, Object?> _results = {};

  /// The location on top of the stack.
  String get location => _stack.last.location;

  /// Every location on the stack, bottom first.
  List<String> get stack => [for (final entry in _stack) entry.location];

  /// Makes a `push` to [location] complete right away with [result], as if
  /// the pushed page had popped with it.
  void stubResult(String location, Object? result) =>
      _results[location] = result;

  /// Forgets all recorded [calls].
  void clearCalls() => calls.clear();

  @override
  void go(String location, {Object? extra}) {
    calls.add(NavigationCall(NavigationKind.go, location, extra: extra));
    for (final entry in _stack) {
      entry.complete(null);
    }
    _stack
      ..clear()
      ..add(_Entry(location));
  }

  @override
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
    String? fragment,
  }) => go(
    namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      fragment: fragment,
    ),
    extra: extra,
  );

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    calls.add(NavigationCall(NavigationKind.push, location, extra: extra));
    if (_results.containsKey(location)) {
      return Future.value(_results[location] as T?);
    }
    final entry = _Entry(location);
    _stack.add(entry);
    return entry.result.then((value) => value as T?);
  }

  @override
  Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) => push<T>(
    namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    ),
    extra: extra,
  );

  @override
  Future<T?> pushReplacement<T extends Object?>(
    String location, {
    Object? extra,
  }) {
    calls.add(
      NavigationCall(NavigationKind.pushReplacement, location, extra: extra),
    );
    _stack.removeLast().complete(null);
    final entry = _Entry(location);
    _stack.add(entry);
    return entry.result.then((value) => value as T?);
  }

  @override
  Future<T?> pushReplacementNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) => pushReplacement<T>(
    namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    ),
    extra: extra,
  );

  @override
  Future<T?> replace<T>(String location, {Object? extra}) {
    calls.add(NavigationCall(NavigationKind.replace, location, extra: extra));
    final entry = _stack.removeLast();
    _stack.add(_Entry(location, entry));
    return entry.result.then((value) => value as T?);
  }

  @override
  Future<T?> replaceNamed<T>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) => replace<T>(
    namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    ),
    extra: extra,
  );

  @override
  bool canPop() => _stack.length > 1;

  @override
  void pop<T extends Object?>([T? result]) {
    calls.add(NavigationCall(NavigationKind.pop, location, result: result));
    if (canPop()) _stack.removeLast().complete(result);
  }

  @override
  String namedLocation(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    String? fragment,
  }) {
    final pattern = routes[name];
    if (pattern == null) {
      throw StateError('MockGoRouter has no route named "$name".');
    }
    return Uri(
      path: RoutePattern(pattern).fill(pathParameters),
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      fragment: fragment,
    ).toString();
  }

  @override
  void refresh() {}
}

class _Entry {
  _Entry(this.location, [_Entry? replacing])
    : _completer = replacing?._completer ?? Completer<Object?>();

  final String location;
  final Completer<Object?> _completer;

  Future<Object?> get result => _completer.future;

  void complete(Object? value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }
}

/// Makes a [MockGoRouter] (or any [GoRouter]) available to [child], so
/// `GoRouter.of(context)` and the `context.go` style helpers find it.
class MockGoRouterProvider extends StatelessWidget {
  /// Provides [router] to [child].
  const MockGoRouterProvider({
    required this.router,
    required this.child,
    super.key,
  });

  /// The router handed to [child].
  final GoRouter router;

  /// The widget under test.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      InheritedGoRouter(goRouter: router, child: child);
}
