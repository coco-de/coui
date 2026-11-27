import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

const _recipes = <(String, String, Map<String, Object?>)>[
  (
    'tree',
    'trailing',
    <String, Object?>{
      'schemaVersion': 1,
      'logicalUnitId': 'tree-generated-outer-layout-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'tree-generated-outer-layout-host-v1',
      'webAdapterId': 'tree-generated-outer-layout-host-v1',
    },
  ),
  (
    'media-query',
    'default',
    <String, Object?>{
      'schemaVersion': 1,
      'logicalUnitId': 'media-query-generated-visibility-layout-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'media-query-generated-visibility-layout-host-v1',
      'webAdapterId': 'media-query-generated-visibility-layout-host-v1',
    },
  ),
  (
    'swipe-actions',
    'default',
    <String, Object?>{
      'schemaVersion': 1,
      'logicalUnitId': 'swipe-actions-generated-outer-layout-host',
      'quantityId': 'inside-frame-own-content-inset-v1',
      'nativeAdapterId': 'swipe-actions-generated-outer-layout-host-v1',
      'webAdapterId': 'swipe-actions-generated-outer-layout-host-v1',
    },
  ),
];
void main() {
  for (final recipe in _recipes) {
    for (final theme in ['light', 'dark']) {
      testWidgets(
        'Public wrapper original Native ${recipe.$1}/${recipe.$2}/$theme',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.$1]!(recipe.$2);
          final capture = GlobalKey();
          await pumpTestApp(
            tester,
            SizedBox(
              width: 800,
              height: 900,
              child: KeyedSubtree(key: capture, child: result),
            ),
            theme: ThemeData.fromCore(
              theme == 'dark' ? CoreThemePresets.dark : CoreThemePresets.light,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          switch (recipe.$1) {
            case 'tree':
              final tree = tester.widget<Tree>(find.byType(Tree));
              expect(tree.trailingBuilder, isNotNull);
              expect(find.text('src'), findsOneWidget);
              expect(find.text('app.dart'), findsOneWidget);
            case 'media-query':
              final product = tester.widget<MediaQueryVisibility>(
                find.byType(MediaQueryVisibility),
              );
              expect(product.child, isA<Container>());
              expect(product.alternateChild, isA<Container>());
              expect(find.byWidget(product.child), findsOneWidget);
            case 'swipe-actions':
              final product = tester.widget<SwipeActions>(
                find.byType(SwipeActions),
              );
              expect(product.trailingActions, hasLength(2));
              expect(find.byWidget(product.child), findsOneWidget);
          }
          final actual = observePairedNativePadding(
            key: '${recipe.$1}-${recipe.$2}-$theme-defaultStyle',
            probes: [
              ParityProbeSpec(
                role: 'root',
                flutterFinder: 'unused-original-entry',
                fields: const {'paddingPx'},
                boxObservationSource: recipe.$3,
              ),
            ],
            captureRoot: capture.currentContext! as Element,
            registryResult: result,
            legacyRootOmitted: false,
          );
          final row = (actual['byRole']! as Map)['root']! as Map;
          expect(
            row['status'],
            'source-complete',
            reason: 'PUBLIC_WRAPPER_NATIVE_ORIGINAL_SOURCE_RED',
          );
          expect(row['source'], recipe.$3);
        },
      );
    }
  }
}
