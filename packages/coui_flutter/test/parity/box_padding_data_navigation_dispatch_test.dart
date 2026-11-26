import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show Align, Alignment, Element, GlobalKey, KeyedSubtree, SizedBox;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

void main() {
  for (final (component, variant, source) in [
    (
      'theme-controller',
      'default',
      BoxObservationSourceSpec.themeControllerOptionGridLayoutHost,
    ),
    (
      'tracker',
      'default',
      BoxObservationSourceSpec.trackerSegmentRowLayoutHost,
    ),
    (
      'bottom-sheet',
      'default',
      BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
    ),
    (
      'bottom-sheet',
      'close',
      BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
    ),
    ('swiper', 'default', BoxObservationSourceSpec.swiperTriggerLayoutHost),
    ('swiper', 'sheet', BoxObservationSourceSpec.swiperTriggerLayoutHost),
    ('diff', 'default', BoxObservationSourceSpec.diffViewerLayoutHost),
    ('diff', 'text', BoxObservationSourceSpec.diffViewerLayoutHost),
    (
      'command-search',
      'default',
      BoxObservationSourceSpec.commandSearchTriggerContentInset,
    ),
    (
      'navigation-bar',
      'default',
      BoxObservationSourceSpec.navigationBarItemsContentInset,
    ),
    (
      'navigation-bar',
      'rail',
      BoxObservationSourceSpec.navigationBarItemsContentInset,
    ),
    (
      'navigation-bar',
      'sidebar',
      BoxObservationSourceSpec.navigationBarItemsContentInset,
    ),
    ('dock', 'default', BoxObservationSourceSpec.dockBarContentInset),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('shared current source $component/$variant/$dark', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry[component]!(
          variant == 'default' ? null : variant,
        );
        final capture = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              width: 800,
              height: 900,
              child: Align(
                alignment: Alignment.topLeft,
                child: KeyedSubtree(key: capture, child: result),
              ),
            ),
            theme: coui.ThemeData.fromCore(
              dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final root = capture.currentContext! as Element;
        for (final omitted in [false, true]) {
          final payload = observePairedNativePadding(
            key: 'current-dispatch',
            probes: [
              ParityProbeSpec(
                role: 'root',
                flutterFinder: 'source-only',
                fields: const {'paddingPx'},
                boxObservationSource: source.toJson(),
              ),
            ],
            captureRoot: root,
            registryResult: result,
            legacyRootOmitted: omitted,
          );
          final actual = (payload['byRole']! as Map)['root']! as Map;
          expect(actual['status'], 'source-complete', reason: '$actual');
          expect(actual['sourceUnitValidated'], isTrue);
          expect(actual['source'], source.toJson());
          expect(actual['sourceBindingAuthority'], isNotEmpty);
          expect(actual['frameSourceStatus'], 'bound-configured-frame');
          expect(
            actual['frameSourceOwnerElement'],
            actual['declaredFrameSourceElement'],
          );
          expect(actual['legacyRoleEligible'], !omitted);
          expect(actual['canonicalComparisonEligible'], isFalse);
          expect(actual['paintRequired'], isFalse);
          expect(payload['legacyRootOmitted'], omitted);
          expect(payload['canonicalComparisonEligible'], isFalse);
        }
      });
    }
  }
}
