import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_pair.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/probe_spec.dart';

void main() {
  const sources = BoxObservationSourceSpec.visualValueFrames;
  test('visual value schemas cannot mix producer or adapter identities', () {
    expect(sources, hasLength(4));
    for (final source in sources) {
      expect(source.validationError, isNull);
      expect(source.quantityId, BoxObservationSourceSpec.quantity);
      expect(BoxObservationSourceSpec.fromJson(source.toJson()), source);
      for (final other in sources.where((other) => other != source)) {
        for (final changeNative in [true, false]) {
          final mixed = BoxObservationSourceSpec(
            schemaVersion: source.schemaVersion,
            logicalUnitId: source.logicalUnitId,
            quantityId: source.quantityId,
            nativeAdapterId: changeNative
                ? other.nativeAdapterId
                : source.nativeAdapterId,
            webAdapterId: changeNative
                ? source.webAdapterId
                : other.webAdapterId,
          );
          expect(mixed.validationError, 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
        }
      }
    }
  });

  test('registration cannot turn a missing current frame into a value', () {
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
      expect(pair.error, 'INCOMPLETE_SOURCE_PAIR');
      expect(missing.containsKey('value'), false);
    }
  });

  test('unreviewed recipes cannot declare visual value source contracts', () {
    for (final source in sources) {
      for (final (component, variant) in const [
        ('button', 'default'),
        ('icon', 'unreviewed'),
        ('number-ticker', 'builder'),
        ('skeleton', 'default'),
        ('countdown', 'unreviewed'),
      ]) {
        expect(
          () => requireCaptureProbes(
            component: component,
            variant: variant,
            roles: const ['root'],
            boxObservationSources: [source],
          ),
          throwsFormatException,
        );
      }
    }
  });

  test('only six reviewed visual value constructions declare the source', () {
    const recipes = <(String, String, BoxObservationSourceSpec)>[
      ('icon', 'default', BoxObservationSourceSpec.iconVisualFrame),
      ('icon', 'search', BoxObservationSourceSpec.iconVisualFrame),
      ('icon', 'favorite', BoxObservationSourceSpec.iconVisualFrame),
      (
        'number-ticker',
        'default',
        BoxObservationSourceSpec.numberTickerTextLayoutHost,
      ),
      (
        'skeleton',
        'text',
        BoxObservationSourceSpec.skeletonTextLinesLayoutHost,
      ),
      (
        'countdown',
        'default',
        BoxObservationSourceSpec.countdownValueLayoutHost,
      ),
    ];
    for (final (component, variant, source) in recipes) {
      for (final key in ['caller-owned-key', 'arbitrary-style-key']) {
        final probe = captureProbes(
          key: key,
          component: component,
          variant: variant,
          flutterClassName: 'actual-public-constructor',
        ).single;
        expect(probe.boxObservationSource, source);
        final oldPayload = probe.toJson()..remove('boxObservationSource');
        expect(
          oldPayload,
          rootProbeSpec(
            key: key,
            flutterClassName: 'actual-public-constructor',
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
        for (final other in sources.where((item) => item != source)) {
          expect(
            () => requireCaptureProbes(
              component: component,
              variant: variant,
              roles: [probe.role],
              boxObservationSources: [other],
            ),
            throwsFormatException,
          );
        }
      }
      final unreviewed = '$variant-unreviewed-construction';
      expect(
        captureProbes(
          key: 'unreviewed',
          component: component,
          variant: unreviewed,
          flutterClassName: 'actual-public-constructor',
        ).single.boxObservationSource,
        isNull,
      );
      expect(
        () => requireCaptureProbes(
          component: component,
          variant: unreviewed,
          roles: const ['root'],
          boxObservationSources: [source],
        ),
        throwsFormatException,
      );
    }
  });
}
