import 'package:go_router/go_router.dart';

/// A typed route parameter, read from the path or the query string.
///
/// Values live in the URL, so unlike `extra` they survive a web refresh and
/// arrive intact from deep links.
///
/// ```dart
/// final userId = RouteParam.integer('id');
/// final tab = RouteParam.enumeration('tab', Tab.values, defaultValue: Tab.posts);
///
/// GoRoute(
///   path: '/users/:id',
///   builder: (context, state) => UserPage(
///     id: userId.read(state),
///     tab: tab.read(state),
///   ),
/// );
///
/// context.goNamed(
///   'user',
///   pathParameters: {userId.name: userId.encode(42)},
///   queryParameters: {tab.name: tab.encode(Tab.likes)},
/// );
/// ```
class RouteParam<T extends Object> {
  /// Creates a parameter with custom [parse] and [encode] functions.
  ///
  /// [parse] should throw a [FormatException] for values it does not
  /// understand. The built-in factories such as [RouteParam.integer] cover
  /// the common types.
  const RouteParam(
    this.name, {
    required this._parse,
    this._encode,
    this.defaultValue,
  });

  /// The parameter name, as used in the path (`:id`) or query (`?id=`).
  final String name;

  /// The value used when the parameter is missing or cannot be parsed.
  final T? defaultValue;

  final T Function(String value) _parse;
  final String Function(T value)? _encode;

  /// A text parameter.
  static RouteParam<String> string(String name, {String? defaultValue}) =>
      RouteParam(name, parse: (value) => value, defaultValue: defaultValue);

  /// A whole number parameter.
  static RouteParam<int> integer(String name, {int? defaultValue}) =>
      RouteParam(name, parse: int.parse, defaultValue: defaultValue);

  /// A decimal number parameter.
  static RouteParam<double> decimal(String name, {double? defaultValue}) =>
      RouteParam(name, parse: double.parse, defaultValue: defaultValue);

  /// A `true` / `false` parameter. `1` and `0` are accepted too.
  static RouteParam<bool> boolean(String name, {bool? defaultValue}) =>
      RouteParam(name, parse: _parseBool, defaultValue: defaultValue);

  /// A date and time parameter, written in ISO 8601.
  static RouteParam<DateTime> dateTime(String name, {DateTime? defaultValue}) =>
      RouteParam(
        name,
        parse: DateTime.parse,
        encode: (value) => value.toIso8601String(),
        defaultValue: defaultValue,
      );

  /// An enum parameter, written as the value's name.
  static RouteParam<E> enumeration<E extends Enum>(
    String name,
    List<E> values, {
    E? defaultValue,
  }) => RouteParam(
    name,
    parse: values.byName,
    encode: (value) => value.name,
    defaultValue: defaultValue,
  );

  /// Reads the parameter from [state], checking path parameters first and
  /// then the query string.
  ///
  /// Falls back to [defaultValue] when the value is missing or invalid, and
  /// throws a [FormatException] when there is no default.
  T read(GoRouterState state) {
    final value = readOrNull(state);
    if (value != null) return value;
    throw FormatException(
      'Missing or invalid route parameter "$name"',
      '${state.uri}',
    );
  }

  /// Like [read], but returns null instead of throwing.
  T? readOrNull(GoRouterState state) {
    final raw = state.pathParameters[name] ?? state.uri.queryParameters[name];
    if (raw == null) return defaultValue;
    try {
      return _parse(raw);
    } on FormatException {
      return defaultValue;
    } on ArgumentError {
      return defaultValue;
    }
  }

  /// Turns [value] into the text stored in the URL.
  String encode(T value) => _encode?.call(value) ?? '$value';
}

bool _parseBool(String value) => switch (value.toLowerCase()) {
  'true' || '1' => true,
  'false' || '0' => false,
  _ => throw FormatException('Not a boolean', value),
};
