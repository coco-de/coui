import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';

void main() {
  const sources = BoxObservationSourceSpec.framedCollectionFrames;
  const browser = BoxObservationSourceSpec.mockupBrowserFrame;

  test('three closed units preserve the existing browser identity', () {
    expect(sources, hasLength(3));
    expect(sources.toSet(), hasLength(3));
    expect(sources, isNot(contains(browser)));
    expect(BoxObservationSourceSpec.componentFrames, contains(browser));
    expect(browser.logicalUnitId, 'mockup-browser-generated-frame');
    expect(browser.nativeAdapterId, 'mockup-browser-generated-frame-v1');
    expect(browser.webAdapterId, 'mockup-browser-generated-frame-v1');
    for (final source in [...sources, browser]) {
      expect(source.validationError, isNull);
      expect(source.quantityId, BoxObservationSourceSpec.quantity);
      expect(BoxObservationSourceSpec.fromJson(source.toJson()), source);
      for (final other in [...sources, browser].where((s) => s != source)) {
        expect(
          BoxObservationSourceSpec(
            schemaVersion: source.schemaVersion,
            logicalUnitId: source.logicalUnitId,
            quantityId: source.quantityId,
            nativeAdapterId: other.nativeAdapterId,
            webAdapterId: source.webAdapterId,
          ).validationError,
          'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
        );
        expect(
          BoxObservationSourceSpec(
            schemaVersion: source.schemaVersion,
            logicalUnitId: source.logicalUnitId,
            quantityId: source.quantityId,
            nativeAdapterId: source.nativeAdapterId,
            webAdapterId: other.webAdapterId,
          ).validationError,
          'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
        );
      }
    }
  });

  test('new schemas cannot attach to unrelated or unreviewed recipes', () {
    const recipes = [
      ('button', 'default'),
      ('mockup', 'phone-unreviewed'),
      ('mockup', 'browser'),
      ('mockup', 'app'),
      ('mockup-device', 'default-unreviewed'),
      ('join', 'default-unreviewed'),
      ('table', 'default-unreviewed'),
    ];
    for (final source in sources) {
      for (final (component, variant) in recipes) {
        expect(
          () => requireCaptureProbes(
            component: component,
            variant: variant,
            roles: const ['root', 'stage'],
            boxObservationSources: [source],
          ),
          throwsFormatException,
        );
        expect(
          captureProbes(
            key: 'arbitrary-current-key',
            component: component,
            variant: variant,
            flutterClassName: 'Widget',
          ).map((probe) => probe.boxObservationSource),
          isNot(contains(source)),
        );
      }
    }
  });

  test('only twelve reviewed constructions declare their own source', () {
    const recipes = <(String, String, BoxObservationSourceSpec, bool)>[
      ('mockup', 'phone', BoxObservationSourceSpec.mockupDeviceBodyFrame, true),
      (
        'mockup',
        'tablet',
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        true,
      ),
      (
        'mockup',
        'landscape',
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        true,
      ),
      (
        'mockup-device',
        'default',
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        true,
      ),
      (
        'mockup-device',
        'flat',
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        true,
      ),
      ('mockup', 'browser', browser, false),
      ('mockup', 'app', browser, false),
      ('join', 'default', BoxObservationSourceSpec.joinStripLayoutHost, false),
      ('join', 'input', BoxObservationSourceSpec.joinStripLayoutHost, false),
      ('join', 'vertical', BoxObservationSourceSpec.joinStripLayoutHost, false),
      (
        'table',
        'default',
        BoxObservationSourceSpec.tableGridContentInset,
        false,
      ),
      (
        'table',
        'resizable',
        BoxObservationSourceSpec.tableGridContentInset,
        false,
      ),
    ];
    for (final (component, variant, source, hasStage) in recipes) {
      final probes = captureProbes(
        key: 'independent-key-with-arbitrary-future-style',
        component: component,
        variant: variant,
        flutterClassName: 'DeclaredWidget',
      );
      expect(
        probes.map((probe) => probe.role),
        orderedEquals(hasStage ? ['root', 'stage'] : ['root']),
      );
      expect(probes.first.boxObservationSource, source);
      if (hasStage) {
        expect(probes.last.boxObservationSource, isNull);
        expect(probes.last.fields.map((field) => field.name).toSet(), {
          'widthPx',
          'heightPx',
        });
      }
      expect(
        () => requireCaptureProbes(
          component: component,
          variant: variant,
          roles: probes.map((probe) => probe.role),
          boxObservationSources: probes.map(
            (probe) => probe.boxObservationSource,
          ),
        ),
        returnsNormally,
      );
      for (final other in sources.where((other) => other != source)) {
        expect(
          () => requireCaptureProbes(
            component: component,
            variant: variant,
            roles: probes.map((probe) => probe.role),
            boxObservationSources: [other],
          ),
          throwsFormatException,
        );
      }
    }
  });

  test('legacy browser default keeps its existing source declaration', () {
    final probes = captureProbes(
      key: 'arbitrary-existing-browser-key',
      component: 'mockup-browser',
      variant: 'default',
      flutterClassName: 'MockupBrowser',
    );
    expect(probes.single.boxObservationSource, browser);
  });
}
