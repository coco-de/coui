import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import '../../src/baseline/baseline_store.dart';
import '../../src/diff/comparator.dart';
import '../../src/model/capture_body.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/model/probe_spec.dart';
import '../../src/report/entry_loader.dart';

void main() {
  late Directory directory;
  late BaselineStore baselines;
  final entry = MatrixEntry(
    component: 'mockup-device',
    variant: 'default',
    theme: ParityTheme.light,
    surfaceStyle: CoreSurfaceStyleId.defaultStyle,
    tier: ParityTier.t1,
    probes: [
      rootProbeSpec(
        key: 'mockup-device-default-light-defaultStyle',
        flutterClassName: 'MockupDevice',
      ),
      const ProbeSpec(
        role: 'stage',
        webSelector: 'stage',
        flutterFinder: 'previewRoot',
        fields: {},
      ),
    ],
  );
  setUp(() {
    directory = Directory.systemTemp.createTempSync('body-capture-test-');
    baselines = BaselineStore.at(directory.path);
    final flutter = img.Image(width: 800, height: 4);
    final web = img.Image(width: 800, height: 4);
    img.fill(flutter, color: img.ColorRgb8(255, 255, 255));
    img.fill(web, color: img.ColorRgb8(255, 255, 255));
    img.fillRect(
      flutter,
      x1: 398,
      y1: 0,
      x2: 401,
      y2: 3,
      color: img.ColorRgb8(0, 0, 0),
    );
    for (final (platform, image) in [('flutter', flutter), ('web', web)]) {
      final bytes = Uint8List.fromList(img.encodePng(image));
      File(
        '${directory.path}/${entry.key}.stage.$platform.png',
      ).writeAsBytesSync(bytes);
      File(
        '${directory.path}/${entry.key}.$platform.png',
      ).writeAsBytesSync(captureBodyColumn(bytes, left: 398, width: 4));
    }
  });
  tearDown(() => directory.deleteSync(recursive: true));

  ComparisonResult compare(String role) {
    final loaded = loadEntry(
      entry: entry,
      probeRole: role,
      signal: .pixel,
      capturedDir: directory,
      baselineStore: baselines,
    );
    return compareEntry(
      key: entry.key,
      probeRole: role,
      signal: .pixel,
      flutterPng: loaded.flutterPng,
      webPng: loaded.webPng,
      pixelModes: const {.parity},
    );
  }

  test('empty stage space cannot hide a completely wrong body', () {
    expect(compare('stage').passed, isTrue);
    expect(compare('root').passed, isFalse);
    expect(compare('root').crossPlatformParity!.diffRatio, 1);
  });

  test('a missing stage artifact cannot fall back to root', () {
    File('${directory.path}/${entry.key}.stage.web.png').deleteSync();
    expect(() => compare('stage'), throwsA(isA<InfraFailure>()));
  });

  test('the CLI key fails when only the body fails', () async {
    final manifest = File('${directory.path}/manifest.json')
      ..writeAsStringSync(
        jsonEncode({
          'entries': [entry.toJson()],
        }),
      );
    final output = File('${directory.path}/report.json');
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/parity/report.dart',
      '--manifest=${manifest.path}',
      '--captured=${directory.path}',
      '--baseline-root=${directory.path}',
      '--signal=pixel',
      '--mode=parity',
      '--out=${directory.path}/diff',
      '--report-json=${output.path}',
      '--comment-out=${directory.path}/comment.md',
      '--vrt-out=${directory.path}/vrt.md',
    ]);
    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    final json = jsonDecode(output.readAsStringSync()) as Map;
    final matrix = json['matrix'] as Map;
    expect((matrix['counts'] as Map)['fail'], 1);
    expect((matrix['counts'] as Map)['pass'], 0);
    expect(((matrix['entries'] as List).single as Map)['roles'], {
      'root': 'fail',
      'stage': 'pass',
    });
  });
}
