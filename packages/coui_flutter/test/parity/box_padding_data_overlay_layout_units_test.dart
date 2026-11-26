import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_data_overlay_layout_units.dart';
import 'box_padding_observation.dart';

const _recipes = <({String component, String variant})>[
  (component: 'theme-controller', variant: 'default'),
  (component: 'tracker', variant: 'default'),
  (component: 'bottom-sheet', variant: 'default'),
  (component: 'bottom-sheet', variant: 'close'),
  (component: 'swiper', variant: 'default'),
  (component: 'swiper', variant: 'sheet'),
  (component: 'diff', variant: 'default'),
  (component: 'diff', variant: 'text'),
];
BoxObservationSourceSpec _source(String component) => switch (component) {
  'theme-controller' =>
    BoxObservationSourceSpec.themeControllerOptionGridLayoutHost,
  'tracker' => BoxObservationSourceSpec.trackerSegmentRowLayoutHost,
  'bottom-sheet' => BoxObservationSourceSpec.bottomSheetOuterLayoutHost,
  'swiper' => BoxObservationSourceSpec.swiperTriggerLayoutHost,
  'diff' => BoxObservationSourceSpec.diffViewerLayoutHost,
  _ => throw ArgumentError(component),
};
Widget _app(Widget result, GlobalKey capture, {bool dark = false}) =>
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
    );
Future<void> _mount(
  WidgetTester tester,
  Widget result,
  GlobalKey capture, {
  bool dark = false,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(_app(result, capture, dark: dark));
  await tester.pumpAndSettle();
}

DataOverlayLayoutBoxSourceBinding _bind(
  GlobalKey capture,
  Widget result,
  String component,
) => bindDataOverlayLayoutBoxSource(
  captureRoot: capture.currentContext! as Element,
  registryResult: result,
  source: _source(component),
)!;
Widget _foreign(int marker) => Padding(
  padding: EdgeInsets.fromLTRB(marker.toDouble(), 1, 7, 2),
  child: Text('foreign $marker'),
);

class _UnknownSheet extends coui.BottomSheet {
  const _UnknownSheet() : super(title: const Text('unknown'));
}

class _UnknownSegment extends coui.CoreTrackerSegment {
  const _UnknownSegment() : super(status: coui.CoreTrackerStatus.fine);
  Widget get hiddenSlot => const Text('unknown foreign slot');
}

void main() {
  for (final recipe in _recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant}/$dark exact owned operation',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final capture = GlobalKey();
          await _mount(tester, result, capture, dark: dark);
          final binding = _bind(capture, result, recipe.component);
          final actual = binding.readDeclaredAbsence();
          expect(binding.scope.producer, same(binding.registryResultElement));
          binding.scope
            ..requireOwned(binding.fieldUnitElement)
            ..requireOwned(binding.frameSource);
          expect(actual.frameOwner, same(binding.frameSource));
          expect(actual.quantity, PaddingQuantityKind.declaredNoOwnPadding);
          expect(actual.paddingElement, isNull);
          expect(actual.value, EdgeInsets.zero);
          expect(
            binding.readActualPadding,
            throwsA(isA<BoxObservationError>()),
          );
          for (final foreign in binding.scope.foreignBoundaries) {
            expect(
              () => binding.scope.requireOwned(foreign),
              throwsA(isA<BoxObservationError>()),
            );
          }
          if (recipe.component == 'swiper') {
            final semantic = binding.fieldUnitElement.widget as Semantics;
            expect(semantic.properties.expanded, isNotNull);
            expect(binding.sourceProvenOutsideTriggerSlots, hasLength(1));
            expect(binding.allOriginalSuppliedSlots, hasLength(2));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets('sheet all foreign inset/border slots stay opaque/$dark', (
      tester,
    ) async {
      final capture = GlobalKey();
      final title = _foreign(101);
      final description = _foreign(103);
      final content = _foreign(107);
      final footer = _foreign(109);
      final result = coui.BottomSheet(
        title: title,
        description: description,
        content: content,
        footer: footer,
        showCloseButton: true,
        showDivider: true,
        onClose: () {},
      );
      await _mount(tester, result, capture, dark: dark);
      final binding = _bind(capture, result, 'bottom-sheet');
      expect(
        binding.allOriginalSuppliedSlots,
        orderedEquals([title, description, content, footer]),
      );
      expect(binding.scope.foreignBoundaries, hasLength(4));
      expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
      for (final foreign in binding.scope.foreignBoundaries) {
        expect(
          binding.allOriginalSuppliedSlots.any(
            (w) => identical(w, foreign.widget),
          ),
          true,
        );
      }
    });
    testWidgets(
      'Diff labels/layers are all foreign, not an old code diff frame/$dark',
      (tester) async {
        final capture = GlobalKey();
        final before = _foreign(11);
        final after = _foreign(13);
        final beforeLabel = _foreign(17);
        final afterLabel = _foreign(19);
        final result = coui.Diff(
          before: before,
          after: after,
          beforeLabel: beforeLabel,
          afterLabel: afterLabel,
          ariaLabel: 'arbitrary comparison',
        );
        await _mount(tester, result, capture, dark: dark);
        final binding = _bind(capture, result, 'diff');
        expect(
          binding.allOriginalSuppliedSlots,
          orderedEquals([before, after, beforeLabel, afterLabel]),
        );
        expect(binding.scope.foreignBoundaries, hasLength(4));
        expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
        expect(
          bindDataOverlayLayoutBoxSource(
            captureRoot: capture.currentContext! as Element,
            registryResult: result,
            source: BoxObservationSourceSpec.codeDiffFrame,
          ),
          isNull,
        );
      },
    );
  }

  testWidgets('sheet raw duplicate rejected before optional branch handling', (
    tester,
  ) async {
    final duplicate = _foreign(23);
    final capture = GlobalKey();
    final result = coui.BottomSheet(
      title: duplicate,
      content: duplicate,
      showHandle: false,
    );
    await _mount(tester, result, capture);
    expect(
      () => _bind(capture, result, 'bottom-sheet'),
      throwsA(isA<BoxObservationError>()),
    );
  });
  testWidgets(
    'Swiper duplicate across outside-overlay slot rejected before omission',
    (tester) async {
      final duplicate = _foreign(29);
      final capture = GlobalKey();
      final result = coui.Swiper(overlayContent: duplicate, child: duplicate);
      await _mount(tester, result, capture);
      expect(
        () => _bind(capture, result, 'swiper'),
        throwsA(isA<BoxObservationError>()),
      );
    },
  );
  testWidgets('Diff duplicated layer/label reference is rejected', (
    tester,
  ) async {
    final duplicate = _foreign(31);
    final capture = GlobalKey();
    final result = coui.Diff(
      before: duplicate,
      after: _foreign(41),
      beforeLabel: duplicate,
    );
    await _mount(tester, result, capture);
    expect(
      () => _bind(capture, result, 'diff'),
      throwsA(isA<BoxObservationError>()),
    );
  });
  testWidgets('unknown concrete producer cannot borrow a registered tuple', (
    tester,
  ) async {
    const result = _UnknownSheet();
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    expect(
      () => _bind(capture, result, 'bottom-sheet'),
      throwsA(isA<BoxObservationError>()),
    );
  });
  testWidgets('unknown capture wrapper cannot become source owner', (
    tester,
  ) async {
    final result = Padding(
      padding: const EdgeInsets.all(53),
      child: coui.BottomSheet(title: _foreign(59)),
    );
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    expect(
      () => _bind(capture, result, 'bottom-sheet'),
      throwsA(isA<BoxObservationError>()),
    );
  });
  testWidgets('forged known tuple is rejected before any source read', (
    tester,
  ) async {
    final result = coui.BottomSheet(title: _foreign(67));
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final original = _source('bottom-sheet');
    final forged = BoxObservationSourceSpec(
      schemaVersion: 99,
      logicalUnitId: original.logicalUnitId,
      quantityId: original.quantityId,
      nativeAdapterId: original.nativeAdapterId,
      webAdapterId: original.webAdapterId,
    );
    expect(
      () => bindDataOverlayLayoutBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: forged,
      ),
      throwsA(isA<BoxObservationError>()),
    );
  });

  testWidgets(
    'held sheet binding rejects live public slot/branch replacement',
    (tester) async {
      final capture = GlobalKey();
      final first = coui.BottomSheet(
        title: _foreign(71),
        description: _foreign(73),
        content: _foreign(79),
      );
      final current = ValueNotifier<Widget>(first);
      addTearDown(current.dispose);
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<Widget>(
            valueListenable: current,
            builder: (_, value, _) => SizedBox(
              width: 800,
              child: KeyedSubtree(key: capture, child: value),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final old = _bind(capture, first, 'bottom-sheet');
      final element = old.registryResultElement;
      final second = coui.BottomSheet(
        title: _foreign(89),
        footer: _foreign(97),
        showHandle: false,
        showDivider: true,
      );
      current.value = second;
      await tester.pumpAndSettle();
      expect(
        old.readDeclaredAbsence,
        throwsA(isA<BoxObservationError>()),
      );
      final fresh = _bind(capture, second, 'bottom-sheet');
      expect(fresh.registryResultElement, same(element));
      expect(fresh.allOriginalSuppliedSlots, hasLength(2));
      expect(fresh.readDeclaredAbsence().value, EdgeInsets.zero);
    },
  );

  testWidgets(
    'Swiper current Semantics changes through real mounted controlled input',
    (tester) async {
      final capture = GlobalKey();
      final first = coui.Swiper(
        overlayContent: _foreign(113),
        child: const SizedBox(width: 300, height: 160),
      );
      final current = ValueNotifier<Widget>(first);
      addTearDown(current.dispose);
      await tester.pumpWidget(
        buildTestApp(
          // openDrawer uses a real Navigator route, as the production host.
          Navigator(
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, _, _) => ValueListenableBuilder<Widget>(
                valueListenable: current,
                builder: (_, value, _) =>
                    KeyedSubtree(key: capture, child: value),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final held = _bind(capture, first, 'swiper');
      expect(
        (held.fieldUnitElement.widget as Semantics).properties.expanded,
        false,
      );
      final second = coui.Swiper(
        open: true,
        overlayContent: first.overlayContent,
        child: first.child,
      );
      current.value = second;
      await tester.pumpAndSettle();
      expect(
        held.readDeclaredAbsence,
        throwsA(isA<BoxObservationError>()),
      );
      final fresh = _bind(capture, second, 'swiper');
      expect(
        (fresh.fieldUnitElement.widget as Semantics).properties.expanded,
        true,
      );
      expect(
        fresh.sourceProvenOutsideTriggerSlots.single,
        same(first.overlayContent),
      );
      expect(fresh.readDeclaredAbsence().value, EdgeInsets.zero);
      current.value = coui.Swiper(
        overlayContent: second.overlayContent,
        child: second.child,
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'unregistered data subclass cannot be treated as no Widget slots',
    (tester) async {
      final capture = GlobalKey();
      const result = coui.Tracker(segments: [_UnknownSegment()]);
      await _mount(tester, result, capture);
      expect(
        () => _bind(capture, result, 'tracker'),
        throwsA(isA<BoxObservationError>()),
      );
    },
  );

  testWidgets(
    'data input mutation without rebuilding cannot fabricate complete frame',
    (tester) async {
      final capture = GlobalKey();
      final segments = <coui.CoreTrackerSegment>[
        const coui.CoreTrackerSegment(status: coui.CoreTrackerStatus.fine),
      ];
      final result = coui.Tracker(segments: segments);
      await _mount(tester, result, capture);
      final held = _bind(capture, result, 'tracker');
      segments.add(
        const coui.CoreTrackerSegment(status: coui.CoreTrackerStatus.warning),
      );
      expect(
        held.readDeclaredAbsence,
        throwsA(isA<BoxObservationError>()),
      );
    },
  );
}
