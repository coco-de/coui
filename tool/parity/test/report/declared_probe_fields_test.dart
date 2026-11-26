import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;

import 'package:test/test.dart';

import '../../src/model/property_field.dart';
import '../../src/model/property_snapshot.dart';

const _key = 'field-contract-default-light-defaultStyle';

Map<String, Object?> _webRole(
  String role, {
  required double width,
  String? color,
}) => {
  'color': color,
  'backgroundColor': 'rgba(0, 0, 0, 0)',
  'borderTopWidth': '0px',
  'borderTopColor': 'rgba(0, 0, 0, 0)',
  for (final name in [
    'borderTopLeftRadius',
    'borderTopRightRadius',
    'borderBottomRightRadius',
    'borderBottomLeftRadius',
    'paddingTop',
    'paddingRight',
    'paddingBottom',
    'paddingLeft',
    'outlineWidth',
    'outlineOffset',
  ])
    name: '0px',
  'outlineStyle': 'none',
  'boxShadow': 'none',
  'opacity': '1',
  'widthPx': width,
  'heightPx': role == 'root' ? 50.0 : 24.0,
};

Map<String, Object?> _nativeRole(String role) => PropertySnapshot(
  key: _key,
  platform: 'flutter',
  probeRole: role,
  backgroundColor: NormalizedColor(r: 0, g: 0, b: 0, a: 0),
  borderColor: NormalizedColor(r: 0, g: 0, b: 0, a: 0),
  borderWidthPx: 0,
  borderRadiusPx: const FourSidePx(0, 0, 0, 0),
  paddingPx: const FourSidePx(0, 0, 0, 0),
  outlineWidthPx: 0,
  outlineOffsetPx: 0,
  boxShadow: const [],
  opacity: 1,
  widthPx: role == 'root' ? 100 : 80,
  heightPx: role == 'root' ? 50 : 24,
).toJson();

Future<Map<String, Object?>> _run(
  String name, {
  bool stageColorDiff = false,
  bool rootColorDiff = false,
  double stageWebWidth = 80,
  bool unknownField = false,
  bool emptyStageFields = false,
  String cli = 'report',
  String signal = 'property',
}) async {
  final out = Directory.systemTemp.createTempSync('declared-fields-$name-');
  addTearDown(() => out.deleteSync(recursive: true));
  final captured = Directory('${out.path}/captured')..createSync();
  final manifest = File('${out.path}/manifest.json')
    ..writeAsStringSync(
      jsonEncode({
        'entries': [
          {
            'component': 'field-contract',
            'variant': 'default',
            'theme': 'light',
            'surfaceStyle': 'defaultStyle',
            'tier': 't1',
            'probes': [
              {
                'role': 'root',
                'webSelector': '#root',
                'flutterFinder': 'byKey:root',
                'fields': [
                  for (final field in PropertyField.values) field.name,
                ],
              },
              {
                'role': 'stage',
                'webSelector': '#stage',
                'flutterFinder': 'byKey:stage',
                'fields': [
                  if (!emptyStageFields) ...['widthPx', 'heightPx'],
                  if (unknownField) 'doesNotExist',
                ],
              },
            ],
          },
        ],
      }),
    );
  File('${captured.path}/$_key.flutter.json').writeAsStringSync(
    jsonEncode({
      'key': _key,
      'byRole': {
        for (final role in ['root', 'stage']) role: _nativeRole(role),
      },
    }),
  );
  File('${captured.path}/$_key.web.json').writeAsStringSync(
    jsonEncode({
      'key': _key,
      'byRole': {
        'root': _webRole(
          'root',
          width: 100,
          color: rootColorDiff ? 'rgb(7, 8, 9)' : null,
        ),
        'stage': _webRole(
          'stage',
          width: stageWebWidth,
          color: stageColorDiff ? 'rgb(7, 8, 9)' : null,
        ),
      },
    }),
  );
  if (signal == 'pixel') {
    final png = img.encodePng(img.Image(width: 2, height: 2));
    for (final role in ['root', 'stage']) {
      for (final platform in ['flutter', 'web']) {
        final suffix = role == 'root' ? '' : '.$role';
        File(
          '${captured.path}/$_key$suffix.$platform.png',
        ).writeAsBytesSync(png);
      }
    }
  }
  final packages = await Isolate.packageConfig;
  expect(packages, isNotNull);
  final report = File('${out.path}/report.json');
  final args = [
    '--packages=${packages!.toFilePath()}',
    'tool/parity/$cli.dart',
    '--manifest=${manifest.path}',
    '--captured=${captured.path}',
    '--baseline-root=${out.path}/baseline',
    '--out=${out.path}/diff',
    '--signal=$signal',
    '--mode=parity',
    if (cli == 'report') ...[
      '--report-json=${report.path}',
      '--comment-out=${out.path}/comment.md',
      '--vrt-out=${out.path}/vrt.md',
    ],
  ];
  final result = await Process.run(
    Platform.resolvedExecutable,
    args,
  );
  File('${out.path}/stdout.log').writeAsStringSync('${result.stdout}');
  File('${out.path}/stderr.log').writeAsStringSync('${result.stderr}');
  final observation = <String, Object?>{
    'actualExit': result.exitCode,
    'report': report.existsSync()
        ? jsonDecode(report.readAsStringSync())
        : null,
    'stderr': '${result.stderr}',
    'argv': args,
    'scope':
        'Synthetic contract fixtures through the comparison CLI; not captured/rendered data',
  };
  File(
    '${out.path}/observations.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(observation));
  return observation;
}

void main() {
  test(
    'declared equal stage geometry ignores undeclared colour difference',
    () async {
      final result = await _run('undeclared-colour', stageColorDiff: true);
      expect(
        result['actualExit'],
        0,
        reason:
            'The declared stage fields widthPx/heightPx match; colour was not declared.',
      );
      final report = result['report']! as Map<String, dynamic>;
      final stage = (report['propertyDiffs'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((row) => row['probeRole'] == 'stage');
      expect(
        (stage['fields'] as List).cast<Map<String, dynamic>>().map(
          (row) => row['field'],
        ),
        unorderedEquals(['widthPx', 'heightPx']),
      );
    },
  );

  test(
    'declared width difference still fails at unchanged px tolerance',
    () async {
      final result = await _run('declared-width', stageWebWidth: 82);
      expect(result['actualExit'], 1);
      final report = result['report']! as Map<String, dynamic>;
      final stage = (report['propertyDiffs'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((row) => row['probeRole'] == 'stage');
      expect(
        (stage['fields'] as List).cast<Map<String, dynamic>>().singleWhere(
          (row) => row['field'] == 'widthPx',
        )['matches'],
        isFalse,
      );
    },
  );

  test('unknown declared JSON field fails closed as manifest error', () async {
    final result = await _run('unknown-field', unknownField: true);
    expect(result['actualExit'], 2);
    expect(result['report'], isNull);
    expect(result['stderr'], contains('doesNotExist'));
  });

  test(
    'the root all-fields declaration still rejects colour difference',
    () async {
      final result = await _run('root-all-fields', rootColorDiff: true);
      expect(result['actualExit'], 1);
      final report = result['report']! as Map<String, dynamic>;
      final root = (report['propertyDiffs'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((row) => row['probeRole'] == 'root');
      expect(
        (root['fields'] as List).cast<Map<String, dynamic>>().singleWhere(
          (row) => row['field'] == 'color',
        )['matches'],
        isFalse,
      );
    },
  );
  for (final cli in ['report', 'compare']) {
    test('$cli empty active property declaration fails closed', () async {
      final result = await _run(
        'empty-active-$cli',
        cli: cli,
        emptyStageFields: true,
      );
      expect(result['actualExit'], 2);
      expect(result['stderr'], contains('at least one declared field'));
      if (cli == 'report') {
        final report = result['report']! as Map<String, dynamic>;
        expect(report['infraFailedCount'], 1);
        expect(report['passedCount'], 1);
        final matrix = report['matrix']! as Map<String, dynamic>;
        expect(matrix['counts'], containsPair('fail', 0));
      }
    });
    test('$cli empty pixel-only declaration remains valid', () async {
      final result = await _run(
        'empty-pixel-$cli',
        cli: cli,
        signal: 'pixel',
        emptyStageFields: true,
      );
      expect(result['actualExit'], 0, reason: '${result['stderr']}');
      if (cli == 'report') {
        final report = result['report']! as Map<String, dynamic>;
        expect(report['propertyDiffs'], isEmpty);
        expect(report['infraFailedCount'], 0);
      }
    });
  }
}
