import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('jugnu_cli');
    File(
      'test/fixtures/app_router.dart.txt',
    ).copySync('${dir.path}/router.dart');
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  Future<ProcessResult> deeplink(List<String> arguments) => Process.run(
    Platform.resolvedExecutable.endsWith('dart')
        ? Platform.resolvedExecutable
        : 'dart',
    ['run', 'bin/deeplink.dart', '--dir', dir.path, ...arguments],
  );

  test('lists routes', () async {
    final result = await deeplink([]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(result.stdout, contains('/users/:id/posts/:postId'));
    expect(result.stdout, contains('user'));
  });

  test('lists routes as JSON', () async {
    final result = await deeplink(['--json']);
    final json = jsonDecode(result.stdout as String) as Map;
    expect(json['version'], 1);
    expect((json['routes'] as List).first['fullPath'], '/');
  });

  test('builds a link and splits path and query values', () async {
    final result = await deeplink([
      'post',
      'id=4',
      'postId=9',
      'ref=mail',
      '--scheme',
      'https',
      '--host',
      'example.com',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect(
      (result.stdout as String).trim(),
      'https://example.com/users/4/posts/9?ref=mail',
    );
  });

  test('explains missing path parameters', () async {
    final result = await deeplink(['user']);
    expect(result.exitCode, 64);
    expect(result.stderr, contains('needs id'));
  });
}
