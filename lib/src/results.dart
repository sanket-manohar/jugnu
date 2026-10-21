import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Push a page and get a typed value back when it closes.
extension JugnuResults on BuildContext {
  /// Pushes [location] and completes with the value the pushed page pops
  /// with.
  ///
  /// Completes with null when the page closes without a value, or with a
  /// value that is not a [T]. go_router's own `push<T>` throws in that case.
  ///
  /// ```dart
  /// final color = await context.pushForResult<Color>('/pick-color');
  /// ```
  Future<T?> pushForResult<T extends Object>(
    String location, {
    Object? extra,
  }) async {
    final result = await GoRouter.of(
      this,
    ).push<Object?>(location, extra: extra);
    return result is T ? result : null;
  }

  /// Same as [pushForResult], but finds the route by [name].
  Future<T?> pushNamedForResult<T extends Object>(
    String name, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) async {
    final result = await GoRouter.of(this).pushNamed<Object?>(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
    return result is T ? result : null;
  }

  /// Closes the current page and hands [result] to whoever pushed it.
  ///
  /// When there is nothing to pop, which happens after a web refresh or when
  /// the page was opened from a deep link, the app goes to [fallback]
  /// instead. Without a fallback, nothing happens.
  void popWithResult<T extends Object?>(T result, {String? fallback}) {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      router.pop<T>(result);
    } else if (fallback != null) {
      router.go(fallback);
    }
  }
}
