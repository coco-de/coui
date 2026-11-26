import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

import '../../src/model/property_field.dart';
import '../../src/normalize/web_property_normalizer.dart';
import '../diff/png_color_boundary_fixtures.dart';
import '../diff/png_color_profile_fixtures.dart';

void main() {
  const mixed = 'icc-boundary-mixed-light-defaultStyle';
  const good = 'icc-boundary-good-light-defaultStyle';
  for (final boundary in [
    'baseline-profile',
    'mixed-sample-units',
    'property-only',
  ]) {
    for (final cli in ['report', 'compare']) {
      for (final active
          in boundary == 'property-only' ? [false] : [true, false]) {
        test(
          '$cli ${active ? 'active' : 'inactive'} $boundary '
          'retains other roles',
          () async {
            final root = Directory.systemTemp.createTempSync(
              'png-colour-boundary-',
            );
            addTearDown(() => root.deleteSync(recursive: true));
            final captures = Directory('${root.path}/captures')..createSync();
            final baselines = Directory('${root.path}/baseline')..createSync();
            final valid = profilePng([100, 90, 80, 255], srgb: true);
            final mode = boundary == 'property-only'
                ? 'both'
                : (boundary == 'baseline-profile') == active
                ? 'regression'
                : 'parity';
            for (final directory in [captures, baselines]) {
              for (final platform in ['flutter', 'web']) {
                for (final key in [mixed, good, '$mixed.stage']) {
                  File(
                    '${directory.path}/$key.$platform.png',
                  ).writeAsBytesSync(valid);
                }
              }
            }
            if (boundary == 'baseline-profile') {
              File('${baselines.path}/$mixed.stage.web.png').writeAsBytesSync(
                profilePng([
                  100,
                  90,
                  80,
                  255,
                ], profile: unsupportedCurveProfile()),
              );
            } else {
              File(
                '${captures.path}/$mixed.stage.flutter.png',
              ).writeAsBytesSync(
                samplePng(bits: 16, colorType: 2, channels: [100, 90, 80]),
              );
              File('${captures.path}/$mixed.stage.web.png').writeAsBytesSync(
                profilePng([100, 90, 80, 255], profile: p3Profile()),
              );
            }
            if (boundary == 'mixed-sample-units') {
              for (final platform in ['flutter', 'web']) {
                File(
                  '${baselines.path}/$mixed.stage.$platform.png',
                ).writeAsBytesSync(
                  File(
                    '${captures.path}/$mixed.stage.$platform.png',
                  ).readAsBytesSync(),
                );
              }
            }
            if (boundary == 'property-only') {
              File('${captures.path}/$mixed.stage.web.png').writeAsBytesSync(
                profilePng([
                  100,
                  90,
                  80,
                  255,
                ], profile: unsupportedCurveProfile()),
              );
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
              for (final key in [mixed, good]) {
                final roles = ['root', if (key == mixed) 'stage'];
                File('${captures.path}/$key.web.json').writeAsStringSync(
                  jsonEncode({
                    'key': key,
                    'byRole': {for (final role in roles) role: raw},
                  }),
                );
                File('${captures.path}/$key.flutter.json').writeAsStringSync(
                  jsonEncode({
                    'key': key,
                    'byRole': {
                      for (final role in roles)
                        role: {
                          ...normalizeWebSnapshot(
                            raw,
                            key: key,
                            probeRole: role,
                          ).toJson(),
                          'platform': 'flutter',
                        },
                    },
                  }),
                );
              }
            }
            Map<String, Object> probe(String role) => {
              'role': role,
              'webSelector': '#$role',
              'flutterFinder': 'byKey:$role',
              'fields': boundary == 'property-only'
                  ? [for (final field in PropertyField.all) field.name]
                  : <String>[],
            };
            File('${root.path}/manifest.json').writeAsStringSync(
              jsonEncode({
                'entries': [
                  for (final variant in ['mixed', 'good'])
                    {
                      'key': variant == 'mixed' ? mixed : good,
                      'component': 'icc-boundary',
                      'variant': variant,
                      'theme': 'light',
                      'surfaceStyle': 'defaultStyle',
                      'tier': 't1',
                      'probes': [
                        probe('root'),
                        if (variant == 'mixed') probe('stage'),
                      ],
                    },
                ],
              }),
            );
            final packages = await Isolate.packageConfig;
            final result = await Process.run(Platform.resolvedExecutable, [
              '--packages=${packages!.toFilePath()}',
              'tool/parity/$cli.dart',
              '--manifest=${root.path}/manifest.json',
              '--captured=${captures.path}',
              '--baseline-root=${root.path}',
              '--signal=${boundary == 'property-only' ? 'property' : 'pixel'}',
              '--mode=$mode',
              '--out=${root.path}/diff',
              if (cli == 'report') ...[
                '--report-json=${root.path}/report.json',
                '--comment-out=${root.path}/comment.md',
                '--vrt-out=${root.path}/vrt.md',
              ],
            ]);
            expect(
              result.exitCode,
              active ? 2 : 0,
              reason: '${result.stdout}\n${result.stderr}',
            );
            if (active) {
              expect(
                result.stderr,
                contains(
                  boundary == 'baseline-profile' ? 'curve' : 'sample depths',
                ),
              );
            }
            if (cli == 'report') {
              final report =
                  jsonDecode(
                        File('${root.path}/report.json').readAsStringSync(),
                      )
                      as Map;
              final matrix = report['matrix'] as Map;
              expect(matrix['counts'], {
                'pass': active ? 1 : 2,
                'fail': 0,
                'infra': active ? 1 : 0,
                'skipped': 0,
              });
              expect(report['passedCount'], active ? 2 : 3);
              expect(report['infraFailedCount'], active ? 1 : 0);
              expect(
                report['infraSkippedKeys'],
                active ? ['$mixed/stage'] : <String>[],
              );
              final entries = matrix['entries'] as List;
              expect(entries, hasLength(2));
              expect((entries.first as Map)['roles'], {
                'root': 'pass',
                'stage': active ? 'infra' : 'pass',
              });
              expect((entries.last as Map)['roles'], {'root': 'pass'});
            } else {
              expect(
                result.stdout,
                contains(
                  active
                      ? '[compare] 2 passed, 0 failed, 1 infra-skipped'
                      : '[compare] 3 passed, 0 failed, 0 infra-skipped',
                ),
              );
            }
          },
        );
      }
    }
  }
}
