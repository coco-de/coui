import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show
        Align,
        Alignment,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        SizedBox,
        Text,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'box_padding_structured_root_units.dart';
import 'parity_matrix_entry.dart';

const _kRecipes = <({String component, String variant})>[
  (component: 'basic', variant: 'default'),
  (component: 'disclosure-badge', variant: 'default'),
  (component: 'disclosure-badge', variant: 'commitment'),
  (component: 'multiple-choice', variant: 'default'),
  (component: 'page-header', variant: 'default'),
  (component: 'sidebar', variant: 'default'),
  (component: 'sidebar', variant: 'two-pane'),
  (component: 'sidebar', variant: 'collapsed'),
  (component: 'tab-pane', variant: 'default'),
  (component: 'tab-pane', variant: 'editor-strip'),
  (component: 'tree', variant: 'default'),
  (component: 'tree', variant: 'selected'),
  (component: 'tree', variant: 'trailing'),
  (component: 'timeline', variant: 'default'),
  (component: 'category-breakdown', variant: 'default'),
  (component: 'category-breakdown', variant: 'donut'),
  (component: 'trend-chart', variant: 'default'),
  (component: 'trend-chart', variant: 'bar'),
  (component: 'window-panel', variant: 'default'),
];
BoxObservationSourceSpec _source(String component) => switch (component) {
  'basic' => BoxObservationSourceSpec.basicContentInset,
  'disclosure-badge' =>
    BoxObservationSourceSpec.disclosureBadgeSolidContentInset,
  'multiple-choice' => BoxObservationSourceSpec.multipleChoiceLayoutHost,
  'page-header' => BoxObservationSourceSpec.pageHeaderLayoutHost,
  'sidebar' => BoxObservationSourceSpec.sidebarOuterLayoutHost,
  'tab-pane' => BoxObservationSourceSpec.tabPaneBarContentInset,
  'tree' => BoxObservationSourceSpec.treeOuterLayoutHost,
  'timeline' => BoxObservationSourceSpec.timelineSequenceLayoutHost,
  'category-breakdown' => BoxObservationSourceSpec.categoryBreakdownLayoutHost,
  'trend-chart' => BoxObservationSourceSpec.trendChartOuterLayoutHost,
  'window-panel' => BoxObservationSourceSpec.windowPanelFrameContentInset,
  _ => throw ArgumentError(component),
};
String _reader(String component) => switch (component) {
  'basic' || 'tab-pane' => 'current-render-padding-v1',
  'disclosure-badge' => 'structured-solid-border-content-v1',
  'window-panel' => 'current-outlined-container-content-v1',
  _ => 'structured-root-declared-absence-v1',
};
Future<void> _mount(
  WidgetTester tester,
  GlobalKey capture,
  Widget result, {
  bool dark = false,
}) async {
  // An independent fixture must replace Overlay.initialEntries completely.
  await tester.pumpWidget(const SizedBox.shrink());
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
}

Map<String, Object?> _observe(
  Element capture,
  Widget result,
  Map<String, Object?> source, {
  bool omitted = false,
}) =>
    ((observePairedNativePadding(
                  key: 'dispatch-unit',
                  probes: [
                    ParityProbeSpec(
                      role: 'root',
                      flutterFinder: 'unused-sanity-finder',
                      fields: const {'paddingPx'},
                      boxObservationSource: source,
                    ),
                  ],
                  captureRoot: capture,
                  registryResult: result,
                  legacyRootOmitted: omitted,
                )['byRole']!
                as Map)['root']!
            as Map)
        .cast<String, Object?>();

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets('${recipe.component}/${recipe.variant}/$dark shared source', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry[recipe.component]!(
          recipe.variant == 'default' ? null : recipe.variant,
        );
        final capture = GlobalKey();
        await _mount(tester, capture, result, dark: dark);
        final root = capture.currentContext! as Element;
        final source = _source(recipe.component);
        final binding = bindStructuredRootBoxSource(
          captureRoot: root,
          registryResult: result,
          source: source,
        )!;
        for (final omitted in [false, true]) {
          final actual = _observe(
            root,
            result,
            source.toJson(),
            omitted: omitted,
          );
          expect(actual['status'], 'source-complete', reason: '$actual');
          expect(actual['source'], source.toJson());
          expect(actual['sourceReaderId'], _reader(recipe.component));
          expect(actual['sourceBindingAuthority'], isNotEmpty);
          expect(
            actual['layoutRootElement'],
            identityHashCode(binding.registryResultElement),
          );
          expect(
            actual['declaringProducerElement'],
            identityHashCode(binding.scope.producer),
          );
          expect(
            actual['fieldUnitElement'],
            identityHashCode(binding.fieldUnitElement),
          );
          expect(
            actual['declaredPaddingSourceElement'],
            identityHashCode(binding.paddingSource),
          );
          expect(
            actual['declaredFrameSourceElement'],
            identityHashCode(binding.frameSource),
          );
          expect(
            actual['frameSourceOwnerElement'],
            actual['declaredFrameSourceElement'],
          );
          expect(actual['frameSourceStatus'], 'bound-configured-frame');
          expect(actual['legacyRoleEligible'], !omitted);
          expect(actual['canonicalComparisonEligible'], false);
          expect(actual['paintRequired'], false);
          expect(actual['paintPresenceInferred'], false);
          if (recipe.component == 'window-panel') {
            expect(
              actual['declaredFrameSourceElement'],
              isNot(actual['declaredPaddingSourceElement']),
            );
          }
        }
      });
    }
  }

  testWidgets('shared Badge retains actual reserved border allocation', (
    tester,
  ) async {
    final capture = GlobalKey();
    const result = coui.DisclosureBadge(
      kind: coui.CoreDisclosureKind.commitment,
      label: 'solid',
      disclosureBadgeStyle: coui.CoreDisclosureBadgeStyle(
        borderWidth: 3,
        padding: coui.CoreEdgeInsets.fromLTRB(3, 5, 7, 11),
      ),
    );
    await _mount(tester, capture, result);
    final actual = _observe(
      capture.currentContext! as Element,
      result,
      BoxObservationSourceSpec.disclosureBadgeSolidContentInset.toJson(),
    );
    expect(actual['status'], 'source-complete');
    expect(actual['value'], [5, 7, 11, 3]);
    expect(actual['currentRenderPadding'], [8, 10, 14, 6]);
    expect(actual['sameOwnerDecorationAllocation'], [3, 3, 3, 3]);
    expect(
      actual['actualPaddingElement'],
      actual['declaredPaddingSourceElement'],
    );
    expect(
      actual['frameSourceOwnerElement'],
      isNot(actual['actualPaddingElement']),
    );
  });

  testWidgets('shared Basic does not promote a whole foreign source', (
    tester,
  ) async {
    final capture = GlobalKey();
    const foreign = coui.Basic(
      title: Text('foreign'),
      basicStyle: coui.CoreBasicStyle(padding: coui.CoreEdgeInsets.all(97)),
    );
    const result = coui.Basic(
      title: foreign,
      basicStyle: coui.CoreBasicStyle(
        padding: coui.CoreEdgeInsets.fromLTRB(3, 5, 7, 11),
      ),
    );
    await _mount(tester, capture, result);
    final actual = _observe(
      capture.currentContext! as Element,
      result,
      BoxObservationSourceSpec.basicContentInset.toJson(),
    );
    expect(actual['status'], 'source-complete');
    expect(actual['value'], [5, 7, 11, 3]);
    final foreignElement = tester.element(find.byWidget(foreign));
    expect(
      actual['declaredPaddingSourceElement'],
      isNot(identityHashCode(foreignElement)),
    );
    const unregisteredWrapper = Padding(
      padding: coui.EdgeInsets.zero,
      child: result,
    );
    await _mount(tester, capture, unregisteredWrapper);
    expect(
      _observe(
        capture.currentContext! as Element,
        unregisteredWrapper,
        BoxObservationSourceSpec.basicContentInset.toJson(),
      )['status'],
      'incomplete',
    );
  });

  testWidgets('shared current update rejects stale registry construction', (
    tester,
  ) async {
    final capture = GlobalKey();
    const first = coui.Basic(
      title: Text('first'),
      basicStyle: coui.CoreBasicStyle(padding: coui.CoreEdgeInsets.all(3)),
    );
    final current = ValueNotifier<Widget>(first);
    addTearDown(current.dispose);
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<Widget>(
          valueListenable: current,
          builder: (_, value, _) => KeyedSubtree(key: capture, child: value),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final root = capture.currentContext! as Element;
    final source = BoxObservationSourceSpec.basicContentInset.toJson();
    expect(_observe(root, first, source)['value'], [3, 3, 3, 3]);
    const next = coui.Basic(
      title: Text('next'),
      basicStyle: coui.CoreBasicStyle(padding: coui.CoreEdgeInsets.all(17)),
    );
    current.value = next;
    await tester.pumpAndSettle();
    expect(capture.currentContext, same(root));
    final stale = _observe(root, first, source);
    expect(stale['status'], 'incomplete');
    expect(stale['error'], 'MISMATCHED_CONSTRUCTION_RESULT');
    final actual = _observe(root, next, source, omitted: true);
    expect(actual['status'], 'source-complete');
    expect(actual['value'], [17, 17, 17, 17]);
    expect(actual['legacyRoleEligible'], false);
    expect(actual['canonicalComparisonEligible'], false);
  });

  testWidgets('unknown tuples and foreign concrete units stay incomplete', (
    tester,
  ) async {
    final capture = GlobalKey();
    const result = coui.Basic(title: Text('actual'));
    await _mount(tester, capture, result);
    final source = BoxObservationSourceSpec.basicContentInset.toJson();
    for (final field in ['logicalUnitId', 'nativeAdapterId', 'webAdapterId']) {
      final invalid = {...source, field: 'unregistered'};
      final actual = _observe(
        capture.currentContext! as Element,
        result,
        invalid,
      );
      expect(actual['status'], 'incomplete');
      expect(actual['error'], 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
    }
    final mismatch = _observe(
      capture.currentContext! as Element,
      result,
      BoxObservationSourceSpec.windowPanelFrameContentInset.toJson(),
    );
    expect(mismatch['status'], 'incomplete');
    expect(mismatch['error'], isNotNull);
  });

  testWidgets('an unrequested legacy stage never becomes a padding result', (
    tester,
  ) async {
    final capture = GlobalKey();
    const result = coui.Basic(title: Text('actual'));
    await _mount(tester, capture, result);
    final probe = ParityProbeSpec(
      role: 'stage',
      flutterFinder: 'unused',
      fields: const {'widthPx', 'heightPx'},
      boxObservationSource: BoxObservationSourceSpec.basicContentInset.toJson(),
    );
    final payload = observePairedNativePadding(
      key: 'stage-unit',
      probes: [probe],
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      legacyRootOmitted: true,
    );
    expect(payload['mode'], 'additive-only');
    expect(payload['legacyRootOmitted'], true);
    expect(payload['canonicalComparisonEligible'], false);
    expect((payload['byRole']! as Map)['stage'], {'status': 'not-requested'});
    expect(probe.fields, {'widthPx', 'heightPx'});
  });
}
