import 'package:coui_flutter/coui_flutter.dart' as c;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/manifest/capture_probes.dart';
import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

void main() {
  const recipes = <String, List<String>>{
    'banner': [
      'default',
      'info',
      'warning',
      'destructive',
      'success',
      'solid',
      'narrow',
    ],
    'description-card': [
      'default',
      'filled',
      'ghost',
      'vertical',
      'space-between',
      'placeholder',
    ],
    'formatted-input': [
      'default',
      'korean-phone',
      'credit-card',
      'date',
      'verify',
    ],
    'frame': ['default', 'column', 'dashed', 'elevated'],
  };
  for (final family in recipes.entries) {
    for (final variant in family.value) {
      for (final dark in [false, true]) {
        testWidgets(
          '${family.key}/$variant dark=$dark reaches its shared reader',
          (tester) async {
            final probe = captureProbes(
              key: 'unit',
              component: family.key,
              variant: variant,
              flutterClassName: 'sanity-only',
            ).single;
            final source = probe.boxObservationSource!;
            final result = kFlutterPreviewRegistry[family.key]!(
              variant == 'default' ? null : variant,
            );
            final key = GlobalKey();
            await tester.pumpWidget(
              buildTestApp(
                KeyedSubtree(key: key, child: result),
                theme: c.ThemeData.fromCore(
                  dark ? c.CoreThemePresets.dark : c.CoreThemePresets.light,
                ),
              ),
            );
            await tester.pumpAndSettle();
            Map<Object?, Object?> observe(bool omitted) =>
                (observePairedNativePadding(
                          key: 'unit',
                          probes: [
                            ParityProbeSpec(
                              role: probe.role,
                              flutterFinder: probe.flutterFinder,
                              fields: probe.fields
                                  .map((field) => field.name)
                                  .toSet(),
                              boxObservationSource: source.toJson(),
                            ),
                          ],
                          captureRoot: key.currentContext! as Element,
                          registryResult: result,
                          legacyRootOmitted: omitted,
                        )['byRole']!
                        as Map)['root']!
                    as Map;
            final actual = observe(false);
            expect(actual['status'], 'source-complete', reason: '$actual');
            expect(actual['source'], source.toJson());
            expect(actual['value'], hasLength(4));
            expect(actual['sourceReaderId'], switch (family.key) {
              'banner' => 'current-container-v1',
              'frame' => 'current-render-padding-v1',
              _ => 'outlined-content-v1',
            });
            expect(actual['declaredFrameSourceElement'], isNotNull);
            expect(actual['declaredPaddingSourceElement'], isNotNull);
            if (family.key == 'frame') {
              expect(
                actual['actualPaddingElement'],
                actual['declaredPaddingSourceElement'],
              );
              expect(
                actual['declaredFrameSourceElement'],
                isNot(actual['declaredPaddingSourceElement']),
              );
              expect(actual['sameOwnerDecorationAllocation'], [0, 0, 0, 0]);
            }
            expect(actual['canonicalComparisonEligible'], isFalse);
            final omitted = observe(true);
            expect(omitted['status'], 'source-complete');
            expect(omitted['value'], actual['value']);
            expect(omitted['legacyRoleEligible'], isFalse);
            expect(omitted['canonicalComparisonEligible'], isFalse);
          },
        );
      }
    }
  }
}
