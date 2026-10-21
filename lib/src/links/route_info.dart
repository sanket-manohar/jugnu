import 'route_pattern.dart';

/// A description of a single `GoRoute`, independent of Flutter.
///
/// Produced at runtime by `GoRouter.describeRoutes` and from source code by
/// the `deeplink` command, and consumed by [RouteInfo]-based tools such as
/// the deep link generator.
class RouteInfo {
  /// Creates a route description.
  const RouteInfo({
    required this.path,
    required this.fullPath,
    this.name,
    this.children = const [],
    this.file,
    this.line,
  });

  /// Reads a route from the map produced by [toJson].
  factory RouteInfo.fromJson(Map<String, Object?> json) => RouteInfo(
    path: json['path']! as String,
    fullPath: json['fullPath']! as String,
    name: json['name'] as String?,
    file: json['file'] as String?,
    line: json['line'] as int?,
    children: [
      for (final child in json['children'] as List? ?? const [])
        RouteInfo.fromJson((child as Map).cast<String, Object?>()),
    ],
  );

  /// The path as written on the route, for example `:id`.
  final String path;

  /// The path including every parent, for example `/users/:id`.
  final String fullPath;

  /// The route name, when the route has one.
  final String? name;

  /// Routes nested under this one.
  final List<RouteInfo> children;

  /// The source file the route was found in, when read from source.
  final String? file;

  /// The 1-based line of the route in [file], when read from source.
  final int? line;

  /// The path parameters this route needs, for example `['id']`.
  List<String> get parameters => RoutePattern(fullPath).parameters;

  /// This route followed by all of its descendants, depth first.
  Iterable<RouteInfo> get flattened sync* {
    yield this;
    for (final child in children) {
      yield* child.flattened;
    }
  }

  /// Converts this route and its children to a JSON-friendly map.
  Map<String, Object?> toJson() => {
    'path': path,
    'fullPath': fullPath,
    if (name != null) 'name': name,
    'parameters': parameters,
    if (file != null) 'file': file,
    if (line != null) 'line': line,
    'children': [for (final child in children) child.toJson()],
  };

  @override
  String toString() => name == null ? fullPath : '$name ($fullPath)';
}
