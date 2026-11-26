import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../diff/png_color_profile_fixtures.dart';

void main() {
  late Directory root;
  const mixed = 'icc-fixture-mixed-light-defaultStyle';
  const good = 'icc-fixture-good-light-defaultStyle';
  setUp(() {
    root = Directory.systemTemp.createTempSync('png-profile-cli-');
    final valid = profilePng([100, 90, 80, 255], srgb: true);
    final unsupported = withChunk(
      valid,
      'cICP',
      Uint8List.fromList([9, 16, 0, 1]),
    );
    for (final platform in ['flutter', 'web']) {
      for (final key in [mixed, good]) {
        File('${root.path}/$key.$platform.png').writeAsBytesSync(valid);
      }
      File('${root.path}/$mixed.stage.$platform.png').writeAsBytesSync(
        platform == 'web' ? unsupported : valid,
      );
    }
    Map<String, Object> probe(String role) => {
      'role': role,
      'webSelector': '#$role',
      'flutterFinder': 'byKey:$role',
      'fields': <String>[],
    };
    File('${root.path}/manifest.json').writeAsStringSync(
      jsonEncode({
        'entries': [
          for (final variant in ['mixed', 'good'])
            {
              'key': variant == 'mixed' ? mixed : good,
              'component': 'icc-fixture',
              'variant': variant,
              'theme': 'light',
              'surfaceStyle': 'defaultStyle',
              'tier': 't1',
              'probes': [probe('root'), if (variant == 'mixed') probe('stage')],
            },
        ],
      }),
    );
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<ProcessResult> run(String cli) async {
    final packages = await Isolate.packageConfig;
    expect(packages, isNotNull);
    return await Process.run(Platform.resolvedExecutable, [
      '--packages=${packages!.toFilePath()}',
      'tool/parity/$cli.dart',
      '--manifest=${root.path}/manifest.json',
      '--captured=${root.path}',
      '--baseline-root=${root.path}',
      '--signal=pixel',
      '--mode=parity',
      '--out=${root.path}/diff',
      if (cli == 'report') ...[
        '--report-json=${root.path}/report.json',
        '--comment-out=${root.path}/comment.md',
        '--vrt-out=${root.path}/vrt.md',
      ],
    ]);
  }

  test(
    'report preserves good rows and isolates unsupported colour format',
    () async {
      final result = await run('report');
      expect(result.exitCode, 2, reason: '${result.stdout}\n${result.stderr}');
      final json =
          jsonDecode(File('${root.path}/report.json').readAsStringSync())
              as Map;
      final matrix = json['matrix'] as Map;
      expect(matrix['counts'], {
        'pass': 1,
        'fail': 0,
        'infra': 1,
        'skipped': 0,
      });
      expect(json['passedCount'], 2);
      expect(json['infraFailedCount'], 1);
      expect(json['infraSkippedKeys'], ['$mixed/stage']);
      final entries = matrix['entries'] as List;
      expect(entries, hasLength(2));
      expect((entries.first as Map)['roles'], {
        'root': 'pass',
        'stage': 'infra',
      });
      expect((entries.last as Map)['roles'], {'root': 'pass'});
    },
  );
  test(
    'compare exits2 for unsupported format while continuing good roles',
    () async {
      final result = await run('compare');
      expect(result.exitCode, 2, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stderr, contains('$mixed.stage.web.png'));
      expect(result.stderr, contains('cICP'));
      expect(
        result.stdout,
        contains('[compare] 2 passed, 0 failed, 1 infra-skipped'),
      );
    },
  );
}
