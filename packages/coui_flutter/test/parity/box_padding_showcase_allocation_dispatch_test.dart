import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

const _kLiteralSource = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'classic-compound-showcase-allocation-host',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'classic-compound-showcase-allocation-host-v1',
  'webAdapterId': 'classic-compound-showcase-allocation-host-v1',
};

const _kRecipes = <(String, String)>[
  ('progress', 'tone'),
  ('chat', 'default'),
  ('chat', 'plain'),
  ('chat', 'tail-corner'),
  ('chat', 'tail-top'),
  ('chip', 'selected'),
  ('chip', 'variant'),
  ('chip', 'shape'),
  ('chip', 'cast-motion'),
  ('chip', 'prefix'),
  ('skeleton', 'default'),
  ('step-item', 'default'),
];

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets('$recipe/$dark real Native allocation dispatcher', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry[recipe.$1]!(recipe.$2);
        final capture = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              width: 800,
              height: 600,
              child: SingleChildScrollView(
                child: KeyedSubtree(key: capture, child: result),
              ),
            ),
            theme: coui.ThemeData.fromCore(
              dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final payload = observePairedNativePadding(
          key: 'actual-source-only',
          probes: [
            const ParityProbeSpec(
              role: 'root',
              flutterFinder: 'actual-canonical',
              fields: {'paddingPx'},
              boxObservationSource: _kLiteralSource,
            ),
          ],
          captureRoot: capture.currentContext! as Element,
          registryResult: result,
          legacyRootOmitted: true,
        );
        final row = (payload['byRole']! as Map)['root']! as Map;
        expect(row['status'], 'source-complete', reason: '$row');
        expect(row['quantityKind'], 'declaredNoOwnPadding');
        expect(
          row['sourceReaderId'],
          'showcase-allocation-current-framework-host-v1',
        );
        expect(payload['legacyRootOmitted'], true);
        expect(payload['canonicalComparisonEligible'], false);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
