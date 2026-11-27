// Regression coverage through the original public Native entry point.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

const _source = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'classic-scope-showcase-allocation-host',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'classic-scope-showcase-allocation-host-v1',
  'webAdapterId': 'classic-scope-showcase-allocation-host-v1',
};
const _cases = <(String, String), (Type, String, Type, int)>{
  ('drag', 'default'): (DragScope, 'DragScope', Column, 2),
  ('drag', 'board'): (DragScope, 'DragScope', Row, 2),
  ('drag', 'overlay'): (DragScope, 'DragScope', Column, 2),
  ('subfocus', 'default'): (SubfocusScope, 'SubfocusScope', Column, 3),
};
void main() {
  for (final entry in _cases.entries) {
    for (final theme in ['light', 'dark']) {
      testWidgets('scope original Native ${entry.key}/$theme', (tester) async {
        final (component, variant) = entry.key;
        final (scopeType, className, layoutType, count) = entry.value;
        final original = kFlutterPreviewRegistry[component]!(variant);
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
        final scopes = find.byType(scopeType);
        expect(scopes, findsOneWidget);
        final scope = tester.widget(scopes);
        final publicChild = scope is DragScope
            ? scope.child
            : (scope as SubfocusScope).child;
        expect(publicChild.runtimeType, layoutType);
        expect(find.byWidget(publicChild), findsOneWidget);
        final raw = (publicChild as Flex).children;
        expect(raw, hasLength(count));
        for (final child in raw) {
          expect(find.byWidget(child), findsOneWidget);
          expect(tester.element(find.byWidget(child)).mounted, true);
        }
        // Normal original public scope/child/layout/opaque-seat health above
        // must pass before the missing typed-provenance target assertion.
        final paired = observePairedNativePadding(
          key: '$component-$variant-$theme-defaultStyle',
          probes: [
            ParityProbeSpec(
              role: 'root',
              flutterFinder: 'byType:$className',
              fields: const {'paddingPx'},
              boxObservationSource: _source,
            ),
          ],
          captureRoot: key.currentContext! as Element,
          registryResult: original,
          legacyRootOmitted: false,
        );
        final row = (paired['byRole']! as Map)['root']! as Map;
        expect(
          row['status'],
          'source-complete',
          reason: 'SCOPE_NATIVE_ORIGINAL_ENTRY_SOURCE_RED',
        );
        expect(row['source'], _source);
        expect(row['quantityKind'], 'declaredNoOwnPadding');
        expect(
          row['sourceReaderId'],
          'scope-allocation-current-public-forwarding-v1',
        );
        expect(row['canonicalComparisonEligible'], false);
        // No expected style scalar, callback, private State, or helper replay.
      });
    }
  }
}
