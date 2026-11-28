import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:html/parser.dart' as html;
import 'package:test/test.dart';

import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/client_box_source_protocol.dart';
import '../../src/web/runtime_capture.dart';
import '../../src/web/web_capture_backend.dart';

final _kSource = BoxObservationSourceSpec.fromJson(const {
  'schemaVersion': 1,
  'logicalUnitId': 'stage-container-callback-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'stage-current-callback-content-inset-v1',
  'webAdapterId': 'stage-current-callback-content-inset-v1',
});

MatrixEntry _entry(
  String theme, {
  String component = 'stage-container',
  String variant = 'default',
  BoxObservationSourceSpec? source,
}) {
  final key = '$component-$variant-$theme-defaultStyle';
  return MatrixEntry.fromJson({
    'component': component,
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': [
      rootProbeSpec(
        key: key,
        flutterClassName: 'StageContainer',
        boxObservationSource: source,
      ).toJson(),
    ],
  });
}

void main() {
  for (final theme in ['light', 'dark']) {
    test(
      'Stage original $theme canonical route requires current client source',
      () {
        final entry = _entry(theme, source: _kSource);
        // Health is the actual collector route, not a standalone SSR render.
        expect(requiresClientCapture(entry), true);
        final request = clientBoxSourceDescriptor(
          entry,
          additiveBoxObservations: true,
        );
        expect(
          request,
          isNotNull,
          reason: 'STAGE_ACTUAL_CANONICAL_CLIENT_SOURCE_RED',
        );
        expect(request, {
          'kind': 'canonical-client-stage-callback-v1',
          'entryKey': entry.key,
          'source': _kSource.toJson(),
          'renderPhase': 'client-settled',
        });
      },
    );
    test(
      'Stage original $theme canonical harness never certifies SSR fallback',
      () async {
        final entry = _entry(theme, source: _kSource);
        expect(requiresClientCapture(entry), true);
        final dir = await Directory.systemTemp.createTemp(
          'coui-stage-client-harness-',
        );
        final receipts = <Map<String, Object?>>[];
        try {
          final file = await prepareWebCaptureHarness(
            entry: entry,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: '/* no network */',
            fontFaceCss: '',
            iconifyHeadHtml: '',
            harnessDir: dir,
            onCurrentBoxSource: receipts.add,
          );
          final document = html.parse(file.readAsStringSync());
          expect(document.querySelectorAll('[data-parity-key]'), isEmpty);
          expect(document.querySelectorAll('script'), isNotEmpty);
          expect(receipts, isEmpty);
          expect(
            clientBoxSourceDescriptor(entry, additiveBoxObservations: true),
            isNotNull,
          );
        } finally {
          await dir.delete(recursive: true);
        }
      },
      // The first harness compiles the real client entry before assertions.
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
  test('Stage source-unrequested keeps original descriptor absence', () {
    final entry = _entry('light', source: _kSource);
    expect(
      clientBoxSourceDescriptor(entry, additiveBoxObservations: false),
      isNull,
    );
    expect(
      clientBoxSourceDescriptor(_entry('light'), additiveBoxObservations: true),
      isNull,
    );
  });
  test(
    'non-target public Stage chain remains outside optional source request',
    () {
      final chain = _entry('light', variant: 'chain');
      expect(requiresClientCapture(chain), true);
      expect(
        clientBoxSourceDescriptor(chain, additiveBoxObservations: true),
        isNull,
      );
    },
  );
  test(
    'unrelated source on non-target Stage remains outside this protocol',
    () {
      final entry = _entry(
        'light',
        variant: 'chain',
        source: BoxObservationSourceSpec.numberTickerTextLayoutHost,
      );
      expect(
        clientBoxSourceDescriptor(entry, additiveBoxObservations: true),
        isNull,
      );
    },
  );
  test('borrowed Stage tuple cannot certify another component or recipe', () {
    for (final entry in [
      _entry('light', component: 'button', source: _kSource),
      _entry('light', variant: 'chain', source: _kSource),
    ]) {
      expect(
        () => clientBoxSourceDescriptor(entry, additiveBoxObservations: true),
        throwsStateError,
      );
    }
  });
}
