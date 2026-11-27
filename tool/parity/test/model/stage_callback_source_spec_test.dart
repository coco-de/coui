import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/stage_callback_ssr_source.dart';

const _kLiteral = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'stage-container-callback-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'stage-current-callback-content-inset-v1',
  'webAdapterId': 'stage-current-callback-content-inset-v1',
};

void main() {
  test('Stage exact five-field tuple retains existing physical quantity', () {
    expect(
      BoxObservationSourceSpec.stageCallbackContentInset.toJson(),
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
  for (final theme in ['light', 'dark']) {
    test(
      'Stage closed default declaration preserves original descriptor $theme',
      () {
        final key = 'stage-container-default-$theme-defaultStyle';
        final probes = captureProbes(
          key: key,
          component: 'stage-container',
          variant: 'default',
          flutterClassName: 'StageContainer',
        );
        expect(probes, hasLength(1));
        expect(probes.single.boxObservationSource?.toJson(), _kLiteral);
        final original = probes.single.toJson()..remove('boxObservationSource');
        expect(
          original,
          rootProbeSpec(key: key, flutterClassName: 'StageContainer').toJson(),
        );
        final entry = MatrixEntry.fromJson({
          'component': 'stage-container',
          'variant': 'default',
          'theme': theme,
          'surfaceStyle': 'defaultStyle',
          'tier': 't2',
          'probes': probes.map((p) => p.toJson()).toList(),
        });
        expect(StageCallbackSsrSource.forEntry(entry), isNotNull);
      },
    );
  }
  for (final (component, variant) in [
    ('stage-container', 'unreviewed'),
    ('responsive-container', 'default'),
    ('scrollview', 'default'),
  ]) {
    test('Stage tuple cannot borrow $component/$variant source authority', () {
      expect(
        () => requireCaptureProbes(
          component: component,
          variant: variant,
          roles: ['root'],
          boxObservationSources: [BoxObservationSourceSpec.fromJson(_kLiteral)],
        ),
        throwsFormatException,
      );
    });
  }
  test('unknown Stage variant stays without new source declaration', () {
    final probes = captureProbes(
      key: 'unknown-stage',
      component: 'stage-container',
      variant: 'unreviewed',
      flutterClassName: 'StageContainer',
    );
    expect(probes.single.boxObservationSource, isNull);
  });
}
