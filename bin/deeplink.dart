import 'dart:convert';
import 'dart:io';

import 'package:jugnu/src/links/deep_link_generator.dart';
import 'package:jugnu/src/links/route_info.dart';
import 'package:jugnu/src/links/route_scanner.dart';

const _usage = '''
Builds deep links from the GoRoute definitions in your app.

Usage:
  dart run jugnu:deeplink                       List every route.
  dart run jugnu:deeplink <route> [name=value]  Build a link to a route.

<route> is a route name or a full path such as /users/:id. Each name=value
fills a path parameter when the route has one by that name, and is added to
the query string otherwise.

Options:
  -s, --scheme <scheme>      URL scheme, such as https or myapp.
      --host <host>          Host, such as example.com.
  -q, --query <name=value>   Always add to the query string.
  -d, --dir <path>           Folder to read routes from. Defaults to lib.
      --open <android|ios>   Open the link on a running emulator or simulator.
      --json                 Print JSON instead of text.
  -h, --help                 Show this help.

Examples:
  dart run jugnu:deeplink user id=42 tab=posts
  dart run jugnu:deeplink /users/:id id=42 --scheme https --host example.com
  dart run jugnu:deeplink user id=42 --scheme myapp --open android
''';

Future<void> main(List<String> arguments) async {
  try {
    exitCode = await _run(arguments);
  } on _UsageException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln('Run with --help to see the options.');
    exitCode = 64;
  }
}

Future<int> _run(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (options.help) {
    stdout.write(_usage);
    return 0;
  }

  final routes = _readRoutes(options.dir);
  final links = DeepLinkGenerator(
    routes,
    scheme: options.scheme,
    host: options.host,
  );

  if (options.route == null) {
    _printRoutes(links, json: options.json);
    return 0;
  }

  final route = links.find(options.route!);
  if (route == null) {
    throw _UsageException(
      'No route named or matching "${options.route}". '
      'Run without arguments to list routes.',
    );
  }

  final pathParameters = <String, String>{};
  final queryParameters = <String, List<String>>{};
  for (final MapEntry(:key, :value) in options.values) {
    if (route.parameters.contains(key)) {
      pathParameters[key] = value;
    } else {
      (queryParameters[key] ??= []).add(value);
    }
  }
  for (final MapEntry(:key, :value) in options.query) {
    (queryParameters[key] ??= []).add(value);
  }

  final missing = [
    for (final name in route.parameters)
      if (!pathParameters.containsKey(name)) name,
  ];
  if (missing.isNotEmpty) {
    final example = [for (final name in missing) '$name=...'].join(' ');
    throw _UsageException(
      '${route.fullPath} needs ${missing.join(', ')}. '
      'Try: dart run jugnu:deeplink ${options.route} $example',
    );
  }

  final link = links.build(
    route.fullPath,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
  );

  if (options.json) {
    stdout.writeln(
      jsonEncode({
        'route': route.toJson()..remove('children'),
        'link': '$link',
      }),
    );
  } else {
    stdout.writeln(link);
  }

  if (options.open != null) return _open(link, options.open!);
  return 0;
}

List<RouteInfo> _readRoutes(String dir) {
  final root = Directory(dir);
  if (!root.existsSync()) {
    throw _UsageException('Folder "$dir" not found.');
  }
  const scanner = RouteScanner();
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('.g.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final file in files)
      ...scanner.scan(file.readAsStringSync(), file: file.path),
  ];
}

void _printRoutes(DeepLinkGenerator links, {required bool json}) {
  if (json) {
    stdout.writeln(
      jsonEncode({
        'version': 1,
        'routes': [for (final route in links.routes) route.toJson()],
      }),
    );
    return;
  }

  final routes = links.allRoutes.toList();
  if (routes.isEmpty) {
    stdout.writeln('No GoRoute definitions found.');
    return;
  }
  final width = routes
      .map((route) => route.fullPath.length)
      .reduce((a, b) => a > b ? a : b);
  for (final route in routes) {
    final name = route.name == null ? '' : '  ${route.name}';
    stdout.writeln('${route.fullPath.padRight(width)}$name');
  }
}

Future<int> _open(Uri link, String platform) async {
  if (!link.hasScheme) {
    throw _UsageException('--open needs a --scheme, such as myapp or https.');
  }
  final (command, arguments) = switch (platform) {
    'android' => (
      'adb',
      [
        'shell',
        'am',
        'start',
        '-a',
        'android.intent.action.VIEW',
        '-d',
        '$link',
      ],
    ),
    'ios' => ('xcrun', ['simctl', 'openurl', 'booted', '$link']),
    _ => throw _UsageException('--open takes android or ios.'),
  };
  try {
    final result = await Process.run(command, arguments);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    return result.exitCode;
  } on ProcessException {
    stderr.writeln('Could not run $command. Is it installed and on your PATH?');
    return 1;
  }
}

class _Options {
  _Options._();

  factory _Options.parse(List<String> arguments) {
    final options = _Options._();
    final queue = [...arguments];

    String next(String flag) {
      if (queue.isEmpty) throw _UsageException('$flag needs a value.');
      return queue.removeAt(0);
    }

    while (queue.isNotEmpty) {
      final argument = queue.removeAt(0);
      switch (argument) {
        case '-h' || '--help':
          options.help = true;
        case '--json':
          options.json = true;
        case '-s' || '--scheme':
          options.scheme = next(argument);
        case '--host':
          options.host = next(argument);
        case '-d' || '--dir':
          options.dir = next(argument);
        case '--open':
          options.open = next(argument);
        case '-q' || '--query':
          options.query.add(_pair(next(argument)));
        case _ when argument.startsWith('-'):
          throw _UsageException('Unknown option $argument.');
        case _ when options.route == null:
          options.route = argument;
        case _:
          options.values.add(_pair(argument));
      }
    }
    return options;
  }

  bool help = false;
  bool json = false;
  String? scheme;
  String? host;
  String dir = 'lib';
  String? open;
  String? route;
  final values = <MapEntry<String, String>>[];
  final query = <MapEntry<String, String>>[];
}

MapEntry<String, String> _pair(String text) {
  final index = text.indexOf('=');
  if (index <= 0) {
    throw _UsageException('Expected name=value, got "$text".');
  }
  return MapEntry(text.substring(0, index), text.substring(index + 1));
}

class _UsageException implements Exception {
  const _UsageException(this.message);

  final String message;
}
