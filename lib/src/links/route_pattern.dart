final _parameter = RegExp(r':(\w+)(\((?:\\.|[^\\()])+\))?');

/// A go_router path pattern, such as `/users/:id/posts/:postId`.
///
/// Knows which path parameters a pattern expects and how to fill them in.
class RoutePattern {
  /// Creates a pattern from a go_router path such as `/users/:id`.
  RoutePattern(this.pattern)
    : parameters = [
        for (final match in _parameter.allMatches(pattern)) match.group(1)!,
      ];

  /// The raw pattern, for example `/users/:id`.
  final String pattern;

  /// The names of the path parameters, in the order they appear.
  final List<String> parameters;

  /// Replaces every `:name` segment with the matching value from
  /// [pathParameters].
  ///
  /// Values are percent-encoded, so `'a b'` becomes `a%20b`. Throws an
  /// [ArgumentError] when a parameter is missing.
  String fill(Map<String, String> pathParameters) {
    return pattern.replaceAllMapped(_parameter, (match) {
      final name = match.group(1)!;
      final value = pathParameters[name];
      if (value == null) {
        throw ArgumentError.value(
          pathParameters,
          'pathParameters',
          'Missing "$name" for $pattern',
        );
      }
      return Uri.encodeComponent(value);
    });
  }

  /// Joins a parent route path with a child path the way go_router does.
  ///
  /// ```dart
  /// RoutePattern.join('/', 'users'); // '/users'
  /// RoutePattern.join('/users', ':id'); // '/users/:id'
  /// ```
  static String join(String parent, String child) {
    if (child.startsWith('/') || parent.isEmpty) return child;
    if (parent.endsWith('/')) return '$parent$child';
    return '$parent/$child';
  }

  @override
  String toString() => pattern;
}
