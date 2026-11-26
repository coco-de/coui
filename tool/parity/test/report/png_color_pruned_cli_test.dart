import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../../src/normalize/web_property_normalizer.dart';
import '../diff/png_color_profile_fixtures.dart';

void main() {
  test('pruned CLI retains good pairs after unsupported colour', () async {
    final root = Directory.systemTemp.createTempSync('icc-pruned-boundary-');
    addTearDown(() => root.deleteSync(recursive: true));
    final raw = <String, Object?>{
      'backgroundColor': 'transparent',
      'borderTopColor': 'transparent',
      'borderTopWidth': '0px',
      'borderTopLeftRadius': '0px',
      'borderTopRightRadius': '0px',
      'borderBottomLeftRadius': '0px',
      'borderBottomRightRadius': '0px',
      'paddingTop': '0px',
      'paddingRight': '0px',
      'paddingBottom': '0px',
      'paddingLeft': '0px',
      'outlineWidth': '0px',
      'outlineOffset': '0px',
      'boxShadow': 'none',
      'opacity': '1',
    };
    final valid = profilePng([100, 90, 80, 255], srgb: true);
    final bad = withChunk(valid, 'cICP', Uint8List.fromList([9, 16, 0, 1]));
    for (final key in ['bad-pruned', 'bad-base', 'good-pruned', 'good-base']) {
      for (final platform in ['flutter', 'web']) {
        File('${root.path}/$key.$platform.png').writeAsBytesSync(
          key == 'bad-pruned' && platform == 'web' ? bad : valid,
        );
      }
      // Synthetic format/CLI fixtures, not rendered component observations.
      File('${root.path}/$key.web.json').writeAsStringSync(
        jsonEncode({
          'key': key,
          'byRole': {'root': raw},
        }),
      );
      File('${root.path}/$key.flutter.json').writeAsStringSync(
        jsonEncode({
          'key': key,
          'byRole': {
            'root': {
              ...normalizeWebSnapshot(
                raw,
                key: key,
                probeRole: 'root',
              ).toJson(),
              'platform': 'flutter',
            },
          },
        }),
      );
    }
    File('${root.path}/pairs.json').writeAsStringSync(
      jsonEncode({
        'pairs': [
          {'prunedKey': 'bad-pruned', 'baselineKey': 'bad-base'},
          {'prunedKey': 'good-pruned', 'baselineKey': 'good-base'},
        ],
      }),
    );
    final packages = await Isolate.packageConfig;
    final result = await Process.run(Platform.resolvedExecutable, [
      '--packages=${packages!.toFilePath()}',
      'tool/parity/pruned_verify.dart',
      '--pairs=${root.path}/pairs.json',
      '--captured=${root.path}',
      '--out=${root.path}/diff',
    ]);
    final trace = Platform.environment['PNG_COLOUR_CLI_TRACE'];
    if (trace != null) {
      File(trace).writeAsStringSync(
        jsonEncode({
          'exit': result.exitCode,
          'stdout': result.stdout,
          'stderr': result.stderr,
        }),
      );
    }
    expect(result.exitCode, 2, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stderr, contains('bad-pruned/bad-base (web)'));
    expect(result.stderr, contains('cICP'));
    expect(
      result.stdout,
      contains(
        '[pruned_verify] 3 matched, 0 mismatched, '
        '1 infra-skipped',
      ),
    );
  });
}
