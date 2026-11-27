// Exercises the original public Stage entry and real current parameter reader.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

const _kSource = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'stage-container-callback-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'stage-current-callback-content-inset-v1',
  'webAdapterId': 'stage-current-callback-content-inset-v1',
};

void main() {
  for (final theme in ['light', 'dark']) {
    testWidgets('Stage original Native entry $theme', (tester) async {
      final original = kFlutterPreviewRegistry['stage-container']!('default');
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
      expect(find.byType(StageContainer), findsOneWidget);
      final stage = tester.element(find.byType(StageContainer));
      final layout = _sole(stage);
      expect(layout.widget, isA<LayoutBuilder>());
      final padding = _sole(layout);
      expect(padding.widget, isA<Padding>());
      expect(_sole(padding).widget, isA<Container>());
      expect(padding, isNot(same(stage)));
      // Public original mount and already executed parameter health precede
      // the missing-source target. No expected Core padding or resolver call.
      final observed = observePairedNativePadding(
        key: 'stage-container-default-$theme-defaultStyle',
        probes: const [
          ParityProbeSpec(
            role: 'root',
            flutterFinder: 'byType:StageContainer',
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
        reason: 'STAGE_NATIVE_ORIGINAL_ENTRY_SOURCE_RED',
      );
      expect(row['source'], _kSource);
      expect(row['quantityKind'], 'frameworkOwnParameter');
      expect(
        row['sourceReaderId'],
        'stage-already-executed-callback-padding-v1',
      );
      expect(row['canonicalComparisonEligible'], false);
      expect((row['sourceIdentity']! as Map)['callbackReexecuted'], false);
    });
  }
}

Element _sole(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  expect(children, hasLength(1));
  expect(children.single.mounted, true);
  return children.single;
}
