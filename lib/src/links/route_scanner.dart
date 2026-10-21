import 'route_info.dart';
import 'route_pattern.dart';

/// Reads `GoRoute` and `TypedGoRoute` definitions from Dart source code.
///
/// This is a light, best-effort reader rather than a full Dart parser. It
/// understands routes written inline, the way most apps declare them:
///
/// ```dart
/// GoRoute(
///   path: '/users',
///   name: 'users',
///   routes: [GoRoute(path: ':id', name: 'user', builder: ...)],
/// )
/// ```
///
/// Routes inside `ShellRoute` and `StatefulShellRoute` are picked up too. A
/// path or name that is not a plain string literal is skipped.
class RouteScanner {
  /// Creates a scanner. Nothing is read until [scan] is called.
  const RouteScanner();

  /// Returns the top-level routes declared in [source].
  ///
  /// [file] is recorded on each [RouteInfo] so tools can link back to it.
  List<RouteInfo> scan(String source, {String? file}) {
    final tokens = _tokenize(source);
    return _Reader(tokens, file).routesIn(0, tokens.length, '');
  }
}

enum _Kind { word, string, symbol }

class _Token {
  const _Token(this.kind, this.text, this.line, {this.literal = true});

  final _Kind kind;
  final String text;
  final int line;

  /// False for strings that contain interpolation.
  final bool literal;

  bool isSymbol(String symbol) => kind == _Kind.symbol && text == symbol;
  bool isWord(String word) => kind == _Kind.word && text == word;
}

class _Reader {
  _Reader(this.tokens, this.file);

  final List<_Token> tokens;
  final String? file;

  List<RouteInfo> routesIn(int start, int end, String parentPath) {
    final routes = <RouteInfo>[];
    var i = start;
    while (i < end) {
      final open = _routeCallAt(i);
      if (open == null) {
        i++;
        continue;
      }
      final close = _matching(open);
      final route = _route(i, open, close, parentPath);
      if (route != null) {
        routes.add(route);
      } else {
        // Not a usable route, but it may still wrap routes we can read.
        routes.addAll(routesIn(open + 1, close, parentPath));
      }
      i = close + 1;
    }
    return routes;
  }

  /// When a `GoRoute(` or `TypedGoRoute<T>(` call starts at [i], returns the
  /// index of its opening parenthesis.
  int? _routeCallAt(int i) {
    final token = tokens[i];
    if (token.isWord('GoRoute') && _at(i + 1)?.isSymbol('(') == true) {
      return i + 1;
    }
    if (token.isWord('TypedGoRoute') && _at(i + 1)?.isSymbol('<') == true) {
      var j = i + 2;
      while (j < tokens.length && !tokens[j].isSymbol('>')) {
        j++;
      }
      if (_at(j + 1)?.isSymbol('(') == true) return j + 1;
    }
    return null;
  }

  RouteInfo? _route(int start, int open, int close, String parentPath) {
    final path = _stringArgument(open, close, 'path');
    if (path == null) return null;
    final fullPath = RoutePattern.join(parentPath, path);

    var name = _stringArgument(open, close, 'name');
    if (name == null && tokens[start].isWord('TypedGoRoute')) {
      name = tokens[start + 2].text;
    }

    final routesList = _argument(open, close, 'routes');
    final children = routesList == null
        ? const <RouteInfo>[]
        : routesIn(routesList, _matching(routesList), fullPath);

    return RouteInfo(
      path: path,
      fullPath: fullPath,
      name: name,
      children: children,
      file: file,
      line: tokens[start].line,
    );
  }

  /// The value of a named string argument, such as `path: '/users'`.
  String? _stringArgument(int open, int close, String name) {
    final index = _argument(open, close, name);
    if (index == null) return null;
    final token = tokens[index];
    if (token.kind != _Kind.string || !token.literal) return null;
    // Adjacent literals, as in 'a' 'b', are joined like Dart does.
    final buffer = StringBuffer(token.text);
    var next = index + 1;
    while (_at(next)?.kind == _Kind.string) {
      buffer.write(tokens[next].text);
      next++;
    }
    return buffer.toString();
  }

  /// The index of the first token of a named argument's value, looking only
  /// at the top level of the call between [open] and [close].
  int? _argument(int open, int close, String name) {
    var depth = 0;
    for (var i = open + 1; i < close; i++) {
      final token = tokens[i];
      if (token.kind == _Kind.symbol) {
        if ('([{'.contains(token.text)) depth++;
        if (')]}'.contains(token.text)) depth--;
        continue;
      }
      if (depth == 0 &&
          token.isWord(name) &&
          _at(i + 1)?.isSymbol(':') == true) {
        // Skip a leading `const` or type arguments such as <RouteBase>.
        var value = i + 2;
        if (_at(value)?.isWord('const') == true) value++;
        if (_at(value)?.isSymbol('<') == true) {
          while (value < close && !tokens[value].isSymbol('>')) {
            value++;
          }
          value++;
        }
        return value < close ? value : null;
      }
    }
    return null;
  }

  int _matching(int open) {
    var depth = 0;
    for (var i = open; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.kind != _Kind.symbol) continue;
      if ('([{'.contains(token.text)) depth++;
      if (')]}'.contains(token.text) && --depth == 0) return i;
    }
    return tokens.length - 1;
  }

  _Token? _at(int i) => i < tokens.length ? tokens[i] : null;
}

List<_Token> _tokenize(String source) {
  final tokens = <_Token>[];
  var line = 1;
  var i = 0;

  bool startsWith(String text) => source.startsWith(text, i);

  while (i < source.length) {
    final char = source[i];

    if (char == '\n') {
      line++;
      i++;
    } else if (char.trim().isEmpty) {
      i++;
    } else if (startsWith('//')) {
      while (i < source.length && source[i] != '\n') {
        i++;
      }
    } else if (startsWith('/*')) {
      final end = source.indexOf('*/', i + 2);
      final stop = end == -1 ? source.length : end + 2;
      line += '\n'.allMatches(source.substring(i, stop)).length;
      i = stop;
    } else if (char == "'" ||
        char == '"' ||
        ((char == 'r' || char == 'R') &&
            i + 1 < source.length &&
            (source[i + 1] == "'" || source[i + 1] == '"'))) {
      final startLine = line;
      final raw = char == 'r' || char == 'R';
      if (raw) i++;
      final quote = source[i];
      final triple = startsWith(quote * 3);
      final delimiter = triple ? quote * 3 : quote;
      i += delimiter.length;
      final value = StringBuffer();
      var literal = true;
      while (i < source.length && !startsWith(delimiter)) {
        final c = source[i];
        if (c == '\n') line++;
        if (!raw && c == r'\' && i + 1 < source.length) {
          value.write(source[i + 1]);
          i += 2;
          continue;
        }
        if (!raw && c == r'$') literal = false;
        value.write(c);
        i++;
      }
      i += delimiter.length;
      tokens.add(
        _Token(_Kind.string, value.toString(), startLine, literal: literal),
      );
    } else if (RegExp(r'[A-Za-z_$0-9]').hasMatch(char)) {
      final start = i;
      while (i < source.length &&
          RegExp(r'[A-Za-z_$0-9]').hasMatch(source[i])) {
        i++;
      }
      tokens.add(_Token(_Kind.word, source.substring(start, i), line));
    } else {
      tokens.add(_Token(_Kind.symbol, char, line));
      i++;
    }
  }
  return tokens;
}
