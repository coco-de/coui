// Exercises the original public Stepper entry and normal factory source proof.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

const _kSource = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'stepper-horizontal-generated-layout-host',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'stepper-normal-horizontal-generated-host-v1',
  'webAdapterId': 'stepper-normal-horizontal-generated-host-v1',
};

void main() {
  for (final variant in ['default', 'disabled']) {
    for (final theme in ['light', 'dark']) {
      testWidgets('Stepper original Native entry $variant $theme', (
        tester,
      ) async {
        final original = kFlutterPreviewRegistry['stepper']!(variant);
        final key = GlobalKey();
        await pumpTestApp(
          tester,
          SizedBox(
            width: 800,
            child: KeyedSubtree(key: key, child: original),
          ),
          theme: ThemeData.fromCore(
            theme == 'dark' ? CoreThemePresets.dark : CoreThemePresets.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(Stepper), findsOneWidget);
        final product = tester.element(find.byType(Stepper));
        expect(product.runtimeType, StatelessElement);
        final operation = _sole(product);
        expect(operation.runtimeType, MultiChildRenderObjectElement);
        final columns = <Element>[];
        operation.visitChildren(columns.add);
        expect(columns, hasLength(3));
        expect(columns.every((c) => c.widget.runtimeType == Column), true);
        // Original public normal factory and complete column health come first.
        final observed = observePairedNativePadding(
          key: 'stepper-$variant-$theme-defaultStyle',
          probes: const [
            ParityProbeSpec(
              role: 'root',
              flutterFinder: 'byType:Stepper',
              fields: {'paddingPx'},
              boxObservationSource: _kSource,
            ),
          ],
          captureRoot: key.currentContext! as Element,
          registryResult: original,
          legacyRootOmitted: false,
        );
        final row = (observed['byRole']! as Map)['root']! as Map;
        expect(
          row['status'],
          'source-complete',
          reason: 'STEPPER_NATIVE_ORIGINAL_ENTRY_SOURCE_RED',
        );
        expect(row['source'], _kSource);
        expect(row['quantityKind'], 'declaredNoOwnPadding');
        expect(
          row['sourceReaderId'],
          'stepper-normal-horizontal-factory-v1',
        );
        expect(row['canonicalComparisonEligible'], false);
        expect(
          (row['sourceIdentity']! as Map)['buildOrIntrinsicReexecuted'],
          false,
        );
      });
    }
  }
}

Element _sole(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  expect(children, hasLength(1));
  expect(children.single.mounted, true);
  return children.single;
}
