import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/stepper_horizontal_ssr_source.dart';

const _kLiteral = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'stepper-horizontal-generated-layout-host',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'stepper-normal-horizontal-generated-host-v1',
  'webAdapterId': 'stepper-normal-horizontal-generated-host-v1',
};

void main() {
  test('Stepper exact five-field tuple retains existing physical quantity', () {
    expect(
      BoxObservationSourceSpec.stepperHorizontalHost.toJson(),
      _kLiteral,
    );
    expect(
      BoxObservationSourceSpec.fromJson(_kLiteral).validationError,
      isNull,
    );
    expect(_kLiteral['quantityId'], BoxObservationSourceSpec.quantity);
    for (final field in ['logicalUnitId', 'nativeAdapterId', 'webAdapterId']) {
      expect(
        BoxObservationSourceSpec.fromJson({
          ..._kLiteral,
          field: 'foreign',
        }).validationError,
        isNotNull,
      );
    }
    for (final field in _kLiteral.keys) {
      final missing = {..._kLiteral}..remove(field);
      expect(
        () => BoxObservationSourceSpec.fromJson(missing),
        throwsFormatException,
      );
    }
  });
  for (final variant in ['default', 'disabled']) {
    for (final theme in ['light', 'dark']) {
      test(
        [
          'Stepper closed declaration preserves original descriptor ',
          '$variant $theme',
        ].join(),
        () {
          final key = 'stepper-$variant-$theme-defaultStyle';
          final probes = captureProbes(
            key: key,
            component: 'stepper',
            variant: variant,
            flutterClassName: 'Stepper',
          );
          expect(probes, hasLength(1));
          expect(probes.single.boxObservationSource?.toJson(), _kLiteral);
          final original = probes.single.toJson()
            ..remove('boxObservationSource');
          expect(
            original,
            rootProbeSpec(key: key, flutterClassName: 'Stepper').toJson(),
          );
          final entry = MatrixEntry.fromJson({
            'component': 'stepper',
            'variant': variant,
            'theme': theme,
            'surfaceStyle': 'defaultStyle',
            'tier': 't2',
            'probes': probes.map((p) => p.toJson()).toList(),
          });
          expect(StepperHorizontalSsrSource.forEntry(entry), isNotNull);
        },
      );
    }
  }
  for (final (component, variant) in [
    ('stepper', 'unreviewed'),
    ('responsive-container', 'default'),
    ('scrollview', 'default'),
  ]) {
    test(
      'Stepper tuple cannot borrow $component/$variant source authority',
      () {
        expect(
          () => requireCaptureProbes(
            component: component,
            variant: variant,
            roles: ['root'],
            boxObservationSources: [
              BoxObservationSourceSpec.fromJson(_kLiteral),
            ],
          ),
          throwsFormatException,
        );
      },
    );
  }
  test('unknown Stepper variant stays without new source declaration', () {
    final probes = captureProbes(
      key: 'unknown-stepper',
      component: 'stepper',
      variant: 'unreviewed',
      flutterClassName: 'Stepper',
    );
    expect(probes.single.boxObservationSource, isNull);
  });
}
