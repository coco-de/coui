import 'dart:io';

import 'package:coui_web/coui_web.dart' show ThemeConfig;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/web/web_capture_backend.dart';

void main() {
  // Existing common harness preparation validates the tuple before rendering.
  // No Native/Web source observer, browser paint, or runtime proof is granted.
  for (final recipe in <(String, String)>[
    ('toggle-group', 'default'),
    ('toggle-group', 'vertical'),
    ('form-field', 'default'),
    ('form-label', 'default'),
    ('listing', 'default'),
    ('option-list', 'default'),
    ('disclosure', 'default'),
    ('disclosure', 'chain'),
    ('disclosure', 'group'),
    ('collapsible', 'default'),
    ('resizable', 'default'),
    ('breadcrumb', 'default'),
  ]) {
    test(
      '${recipe.$1}/${recipe.$2} foreign source stops before harness I/O',
      () async {
        final directory = Directory.systemTemp.createTempSync(
          'next-parameter-source-prevalidation-',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final probes = captureProbes(
          key: 'untrusted-parameter-source',
          component: recipe.$1,
          variant: recipe.$2,
          flutterClassName: 'source-mismatch-fixture',
        );
        expect(probes.single.boxObservationSource, isNotNull);
        final entry = MatrixEntry(
          component: 'stat',
          variant: 'default',
          theme: ParityTheme.light,
          surfaceStyle: .defaultId,
          tier: ParityTier.t1,
          probes: probes,
        );
        await expectLater(
          prepareWebCaptureHarness(
            entry: entry,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: '',
            fontFaceCss: '',
            iconifyHeadHtml: '',
            harnessDir: directory,
          ),
          throwsFormatException,
        );
        expect(directory.listSync(), isEmpty);
      },
    );
  }

  for (final component in [
    'avatar',
    'number-input',
    'app-bar',
    'empty-state',
    'label',
    'link',
    'mask',
    'hover',
    'indicator',
    'chat',
    'steps',
    'stepper',
    'aspect-ratio-box',
    'clickable',
    'focus-outline',
    'switch-field',
    'kbd',
    'refresh-trigger',
    'loading',
    'status',
    'tag',
    'skeleton',
    'menu-item',
    'carousel-banner',
    'panel-header',
    'calendar',
    'definition-list',
    'responsive-row-column',
    'responsive-container',
    'responsive-grid',
    'stack-layout',
    'indexed-switcher',
    'swap',
    'divider',
  ]) {
    test(
      '$component source mismatch stops canonical harness preparation',
      () async {
        final directory = Directory.systemTemp.createTempSync(
          'parity-source-prevalidation-',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final probes = captureProbes(
          key: 'untrusted-source',
          component: component,
          variant: switch (component) {
            'chat' => 'neutral',
            'stepper' => 'vertical',
            'kbd' => 'single',
            'skeleton' => 'circle',
            'calendar' => 'single',
            'divider' => 'with-child',
            _ => 'default',
          },
          flutterClassName: 'unused-source-fixture',
        );
        expect(
          probes
              .firstWhere((probe) => probe.role == 'root')
              .boxObservationSource,
          isNotNull,
        );
        final entry = MatrixEntry(
          component: 'stat',
          variant: 'default',
          theme: ParityTheme.light,
          surfaceStyle: .defaultId,
          tier: ParityTier.t1,
          probes: probes,
        );
        await expectLater(
          prepareWebCaptureHarness(
            entry: entry,
            themeConfig: ThemeConfig.defaults(),
            vendoredTailwindScript: '',
            fontFaceCss: '',
            iconifyHeadHtml: '',
            harnessDir: directory,
          ),
          throwsFormatException,
        );
        expect(directory.listSync(), isEmpty);
      },
    );
  }
}
