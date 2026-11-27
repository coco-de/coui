import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/box_observation_source_spec.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/bottom_action_bar_ssr_source.dart';

const _literal = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'bottom-action-bar-owned-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'bottom-action-bar-owned-content-inset-v1',
  'webAdapterId': 'bottom-action-bar-owned-content-inset-v1',
};

void main() {
  test(
    'one independent five-field tuple, no new quantity or showcase alias',
    () {
      final source = BoxObservationSourceSpec.fromJson(_literal);
      expect(source.validationError, isNull);
      expect(
        BoxObservationSourceSpec.bottomActionBarContentInset.toJson(),
        _literal,
      );
      expect(source, isNot(BoxObservationSourceSpec.showcaseAllocationHost));
      for (final adapter in ['nativeAdapterId', 'webAdapterId']) {
        final forged = {
          ..._literal,
          adapter: 'classic-compound-showcase-allocation-host-v1',
        };
        expect(
          BoxObservationSourceSpec.fromJson(forged).validationError,
          isNotNull,
        );
      }
    },
  );
  for (final variant in ['default', 'horizontal', 'summary-compact']) {
    test(
      'closed $variant declaration/factory consistency across actual surface enum',
      () {
        for (final style in CoreSurfaceStyleId.values) {
          for (final theme in ['light', 'dark']) {
            final key = 'bottom-action-bar-$variant-$theme-${style.name}';
            final probes = captureProbes(
              key: key,
              component: 'bottom-action-bar',
              variant: variant,
              flutterClassName: 'BottomActionBar',
            );
            expect(probes, hasLength(1));
            expect(probes.single.boxObservationSource?.toJson(), _literal);
            final original = probes.single.toJson()
              ..remove('boxObservationSource');
            expect(
              original,
              rootProbeSpec(
                key: key,
                flutterClassName: 'BottomActionBar',
              ).toJson(),
            );
            final entry = MatrixEntry.fromJson({
              'component': 'bottom-action-bar',
              'variant': variant,
              'theme': theme,
              'surfaceStyle': style.name,
              'tier': 't2',
              'probes': probes.map((probe) => probe.toJson()).toList(),
            });
            expect(BottomActionBarSsrSource.forEntry(entry), isNotNull);
          }
        }
      },
    );
  }
  for (final (component, variant) in [
    ('mockup-foldable', 'angle'),
    ('mockup-foldable', 'default'),
    ('scaffold', 'default'),
    ('bottom-action-bar', 'scaffold'),
    ('scrollview', 'default'),
  ]) {
    test(
      '$component/$variant keeps the complete pre-existing OR-chain source',
      () {
        final probes = captureProbes(
          key: 'source-chain-sentinel',
          component: component,
          variant: variant,
          flutterClassName: 'unchanged',
        );
        expect(
          probes.first.boxObservationSource,
          BoxObservationSourceSpec.showcaseAllocationHost,
        );
        expect(
          () => requireCaptureProbes(
            component: component,
            variant: variant,
            roles: probes.map((probe) => probe.role),
            boxObservationSources: [
              BoxObservationSourceSpec.fromJson(_literal),
            ],
          ),
          throwsFormatException,
        );
      },
    );
  }
  test('unknown Bottom recipe cannot inherit the reviewed product tuple', () {
    final probes = captureProbes(
      key: 'unknown-bottom',
      component: 'bottom-action-bar',
      variant: 'unreviewed',
      flutterClassName: 'BottomActionBar',
    );
    expect(probes.single.boxObservationSource, isNull);
    expect(
      () => requireCaptureProbes(
        component: 'bottom-action-bar',
        variant: 'unreviewed',
        roles: ['root'],
        boxObservationSources: [BoxObservationSourceSpec.fromJson(_literal)],
      ),
      throwsFormatException,
    );
  });
}
