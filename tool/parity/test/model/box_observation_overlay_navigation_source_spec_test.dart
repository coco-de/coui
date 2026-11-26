import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_pair.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/probe_spec.dart';

void main() {
  const sources = [
    ...BoxObservationSourceSpec.dataOverlayLayoutFrames,
    ...BoxObservationSourceSpec.navigationTriggerParameterFrames,
  ];
  test(
    'eight source schemas preserve quantity and closed adapter identities',
    () {
      expect(sources, hasLength(8));
      expect(
        sources.map((source) => source.logicalUnitId).toSet(),
        hasLength(8),
      );
      for (final source in sources) {
        expect(source.validationError, isNull);
        expect(source.quantityId, BoxObservationSourceSpec.quantity);
        expect(source.nativeAdapterId, '${source.logicalUnitId}-v1');
        expect(source.webAdapterId, source.nativeAdapterId);
        expect(BoxObservationSourceSpec.fromJson(source.toJson()), source);
        for (final other in sources.where((other) => other != source)) {
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
    },
  );
  test(
    'schema registration alone does not grant current observation proof',
    () {
      for (final source in sources) {
        final missing = <String, Object?>{
          'status': 'incomplete',
          'source': source.toJson(),
          'error': 'MISSING_CURRENT_SOURCE_WITNESS',
        };
        final pair = boxObservationPairGate(
          expected: source,
          native: missing,
          web: missing,
        );
        expect(pair.eligible, false);
        expect(pair.nativeComplete, false);
        expect(pair.webComplete, false);
        expect(pair.error, 'INCOMPLETE_SOURCE_PAIR');
        expect(missing.containsKey('value'), false);
      }
    },
  );
  test('new schemas cannot be declared by an unrelated recipe', () {
    for (final source in sources) {
      expect(
        () => requireCaptureProbes(
          component: 'button',
          variant: 'default',
          roles: const ['root'],
          boxObservationSources: [source],
        ),
        throwsFormatException,
      );
    }
  });
  test('only the thirteen reviewed constructions declare these sources', () {
    const recipes = <(String, String, BoxObservationSourceSpec)>[
      (
        'theme-controller',
        'default',
        BoxObservationSourceSpec.themeControllerOptionGridLayoutHost,
      ),
      (
        'tracker',
        'default',
        BoxObservationSourceSpec.trackerSegmentRowLayoutHost,
      ),
      (
        'bottom-sheet',
        'default',
        BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
      ),
      (
        'bottom-sheet',
        'close',
        BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
      ),
      ('swiper', 'default', BoxObservationSourceSpec.swiperTriggerLayoutHost),
      ('swiper', 'sheet', BoxObservationSourceSpec.swiperTriggerLayoutHost),
      ('diff', 'default', BoxObservationSourceSpec.diffViewerLayoutHost),
      ('diff', 'text', BoxObservationSourceSpec.diffViewerLayoutHost),
      (
        'command-search',
        'default',
        BoxObservationSourceSpec.commandSearchTriggerContentInset,
      ),
      (
        'navigation-bar',
        'default',
        BoxObservationSourceSpec.navigationBarItemsContentInset,
      ),
      (
        'navigation-bar',
        'rail',
        BoxObservationSourceSpec.navigationBarItemsContentInset,
      ),
      (
        'navigation-bar',
        'sidebar',
        BoxObservationSourceSpec.navigationBarItemsContentInset,
      ),
      ('dock', 'default', BoxObservationSourceSpec.dockBarContentInset),
    ];
    expect(recipes, hasLength(13));
    for (final (component, variant, source) in recipes) {
      for (final key in ['caller-owned-key', 'rawStyle:arbitrary']) {
        final probe = captureProbes(
          key: key,
          component: component,
          variant: variant,
          flutterClassName: 'public-constructor',
        ).single;
        expect(probe.boxObservationSource, source);
        final payload = probe.toJson()..remove('boxObservationSource');
        expect(
          payload,
          rootProbeSpec(
            key: key,
            flutterClassName: 'public-constructor',
          ).toJson(),
        );
        expect(
          () => requireCaptureProbes(
            component: component,
            variant: variant,
            roles: [probe.role],
            boxObservationSources: [source],
          ),
          returnsNormally,
        );
        for (final unrelated in sources.where((other) => other != source)) {
          expect(
            () => requireCaptureProbes(
              component: component,
              variant: variant,
              roles: [probe.role],
              boxObservationSources: [unrelated],
            ),
            throwsFormatException,
          );
        }
      }
      expect(
        captureProbes(
          key: 'unreviewed',
          component: component,
          variant: '$variant-unreviewed-source',
          flutterClassName: 'public-constructor',
        ).single.boxObservationSource,
        isNull,
      );
      expect(
        () => requireCaptureProbes(
          component: component,
          variant: '$variant-unreviewed-source',
          roles: const ['root'],
          boxObservationSources: [source],
        ),
        throwsFormatException,
      );
    }
  });
}
