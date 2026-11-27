import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';

void main() {
  const recipes = <(String, String, String)>[
    ('tree', 'trailing', 'tree-generated-outer-layout-host'),
    ('media-query', 'default', 'media-query-generated-visibility-layout-host'),
    ('swipe-actions', 'default', 'swipe-actions-generated-outer-layout-host'),
  ];
  for (final (component, variant, unit) in recipes) {
    test(
      '$component/$variant exact independent five-field '
      'source and unchanged selector',
      () {
        final probe = captureProbes(
          key: 'public-key',
          component: component,
          variant: variant,
          flutterClassName: 'existing-public-finder',
        ).single;
        expect(probe.boxObservationSource?.toJson(), <String, Object?>{
          'schemaVersion': 1,
          'logicalUnitId': unit,
          'quantityId': 'inside-frame-own-content-inset-v1',
          'nativeAdapterId': '$unit-v1',
          'webAdapterId': '$unit-v1',
        });
        expect(probe.boxObservationSource!.validationError, isNull);
        expect(probe.webSelector, contains('data-parity-key="public-key"'));
        expect(probe.flutterFinder, 'byType:existing-public-finder');
        expect(probe.fields.map((f) => f.name), contains('paddingPx'));
        requireCaptureProbes(
          component: component,
          variant: variant,
          roles: ['root'],
          boxObservationSources: [probe.boxObservationSource],
        );
        expect(
          () => requireCaptureProbes(
            component: component,
            variant: 'unknown',
            roles: ['root'],
            boxObservationSources: [probe.boxObservationSource],
          ),
          throwsFormatException,
        );
        for (final field in [
          'logicalUnitId',
          'quantityId',
          'nativeAdapterId',
          'webAdapterId',
        ]) {
          final wrong = BoxObservationSourceSpec.fromJson({
            ...probe.boxObservationSource!.toJson(),
            field: 'foreign',
          });
          expect(wrong.validationError, isNotNull);
        }
      },
    );
  }
  test(
    'all surface enum variants retain declaration '
    'without a value or theme gate',
    () {
      expect(CoreSurfaceStyleId.values, isNotEmpty);
      // captureProbes intentionally has no style input. Declaration is a source
      // grammar; runtime and measurement credit remain actual capture results.
      for (final _ in CoreSurfaceStyleId.values) {
        for (final (component, variant, _) in recipes) {
          expect(
            captureProbes(
              key: 'k',
              component: component,
              variant: variant,
              flutterClassName: 'F',
            ).single.boxObservationSource,
            isNotNull,
          );
        }
      }
    },
  );
}
