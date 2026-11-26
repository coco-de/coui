import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_structured_root_units.dart';

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
// Overlay.initialEntries keeps its first child on a shell-only repump.
// Independent fixtures are unmounted; mounted updates below use ValueNotifier.
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

StructuredRootBoxSourceBinding _bind(
  GlobalKey capture,
  Widget result,
  String component,
) => bindStructuredRootBoxSource(
  captureRoot: capture.currentContext! as Element,
  registryResult: result,
  source: _source(component),
)!;
BoxPaddingObservation _read(StructuredRootBoxSourceBinding binding) =>
    binding.readerId == 'structured-root-declared-absence-v1'
    ? binding.readDeclaredAbsence()
    : binding.readActualPadding();
Widget _foreign(double inset, {String label = 'foreign'}) =>
    Padding(padding: EdgeInsets.all(inset), child: Text(label));

class _UnknownBasic extends coui.Basic {
  const _UnknownBasic() : super(title: const Text('unknown'));
}

class _UnknownTab extends coui.CoreTabItem<Widget> {
  const _UnknownTab() : super(label: 'unknown');
}

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant}/$dark current source',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final capture = GlobalKey();
          await _mount(tester, result, capture, dark: dark);
          final binding = _bind(capture, result, recipe.component);
          expect(binding.scope.producer, same(binding.registryResultElement));
          binding.scope.requireOwned(binding.fieldUnitElement);
          binding.scope.requireOwned(binding.frameSource);
          final observation = _read(binding);
          expect(observation.frameOwner, same(binding.frameSource));
          expect(observation.value.left.isFinite, true);
          expect(observation.value.top.isFinite, true);
          expect(
            observation.quantity,
            binding.readerId == 'structured-root-declared-absence-v1'
                ? PaddingQuantityKind.declaredNoOwnPadding
                : isNot(PaddingQuantityKind.declaredNoOwnPadding),
          );
          for (final boundary in binding.scope.foreignBoundaries) {
            expect(
              () => binding.scope.requireOwned(boundary),
              throwsA(isA<BoxObservationError>()),
            );
          }
          if (recipe.component == 'tab-pane') {
            expect(binding.paddingSource.widget, isA<Padding>());
            expect(binding.frameSource.widget, isA<SizedBox>());
          }
          if (recipe.component == 'window-panel') {
            expect(binding.paddingSource.widget, isA<coui.OutlinedContainer>());
          }
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'Basic asymmetric current inset and whole foreign exclusion/$dark',
      (tester) async {
        final capture = GlobalKey();
        final foreign = _foreign(71);
        final first = coui.Basic(
          title: foreign,
          subtitle: _foreign(37),
          basicStyle: const coui.CoreBasicStyle(
            padding: coui.CoreEdgeInsets.only(
              left: 3,
              top: 7,
              right: 13,
              bottom: 19,
            ),
          ),
        );
        await _mount(tester, first, capture, dark: dark);
        final held = _bind(capture, first, 'basic');
        final value = _read(held);
        expect(value.value, const EdgeInsets.fromLTRB(3, 7, 13, 19));
        expect(held.scope.foreignBoundaries, hasLength(2));
        final second = coui.Basic(
          title: _foreign(113),
          basicStyle: const coui.CoreBasicStyle(
            padding: coui.CoreEdgeInsets.only(
              left: 5,
              top: 11,
              right: 17,
              bottom: 23,
            ),
          ),
        );
        await _mount(tester, second, capture, dark: !dark);
        expect(() => _read(held), throwsA(isA<BoxObservationError>()));
        expect(
          _read(_bind(capture, second, 'basic')).value,
          const EdgeInsets.fromLTRB(5, 11, 17, 23),
        );
      },
    );
    testWidgets(
      'solid Badge border once, asymmetric/zero inset/$dark',
      (tester) async {
        final capture = GlobalKey();
        for (final zero in [false, true]) {
          final result = coui.DisclosureBadge(
            kind: coui.CoreDisclosureKind.commitment,
            label: 'solid',
            disclosureBadgeStyle: coui.CoreDisclosureBadgeStyle(
              borderWidth: 3,
              padding: zero
                  ? coui.CoreEdgeInsets.zero
                  : const coui.CoreEdgeInsets.only(
                      left: 5,
                      top: 11,
                      right: 17,
                      bottom: 23,
                    ),
            ),
          );
          await _mount(tester, result, capture, dark: dark);
          final binding = _bind(capture, result, 'disclosure-badge');
          final observed = _read(binding);
          expect(
            observed.value,
            zero ? EdgeInsets.zero : const EdgeInsets.fromLTRB(5, 11, 17, 23),
          );
          expect(observed.allocatedDecorationInsets, const EdgeInsets.all(3));
          expect(
            observed.currentRenderPadding,
            observed.value + const EdgeInsets.all(3),
          );
          expect(
            binding.readDeclaredAbsence,
            throwsA(isA<BoxObservationError>()),
          );
        }
      },
    );
  }
  testWidgets('held binding rejects replaced input at same mounted capture', (
    tester,
  ) async {
    final capture = GlobalKey();
    final first = coui.Basic(
      title: _foreign(31),
      basicStyle: const coui.CoreBasicStyle(
        padding: coui.CoreEdgeInsets.fromLTRB(3, 5, 7, 11),
      ),
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
    final mounted = capture.currentContext;
    final held = _bind(capture, first, 'basic');
    final next = coui.Basic(
      title: _foreign(97),
      basicStyle: const coui.CoreBasicStyle(
        padding: coui.CoreEdgeInsets.fromLTRB(13, 17, 19, 23),
      ),
    );
    current.value = next;
    await tester.pumpAndSettle();
    expect(capture.currentContext, same(mounted));
    expect(() => _read(held), throwsA(isA<BoxObservationError>()));
    expect(
      _read(_bind(capture, next, 'basic')).value,
      const EdgeInsets.fromLTRB(13, 17, 19, 23),
    );
  });

  testWidgets('same Badge binding follows actual current theme allocation', (
    tester,
  ) async {
    final capture = GlobalKey();
    const result = coui.DisclosureBadge(
      kind: coui.CoreDisclosureKind.commitment,
      label: 'current theme',
    );
    coui.ThemeData theme(bool dark) =>
        coui.ThemeData.fromCore(
          dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
        ).copyWith(
          coreComponentTheme: () => coui.CoreComponentTheme(
            disclosureBadge: coui.CoreDisclosureBadgeTheme(
              style: coui.CoreDisclosureBadgeStyle(
                borderWidth: dark ? 5 : 3,
                padding: dark
                    ? const coui.CoreEdgeInsets.fromLTRB(13, 17, 19, 23)
                    : const coui.CoreEdgeInsets.fromLTRB(3, 5, 7, 11),
              ),
            ),
          ),
        );
    final current = ValueNotifier<coui.ThemeData>(theme(false));
    addTearDown(current.dispose);
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<coui.ThemeData>(
          valueListenable: current,
          builder: (_, data, child) => coui.Theme(data: data, child: child!),
          child: KeyedSubtree(key: capture, child: result),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final binding = _bind(capture, result, 'disclosure-badge');
    final frame = binding.frameSource;
    final padding = binding.paddingSource;
    final first = _read(binding);
    expect(first.value, const EdgeInsets.fromLTRB(3, 5, 7, 11));
    expect(first.allocatedDecorationInsets, const EdgeInsets.all(3));
    current.value = theme(true);
    await tester.pumpAndSettle();
    final next = _read(binding);
    expect(binding.frameSource, same(frame));
    expect(binding.paddingSource, same(padding));
    expect(next.value, const EdgeInsets.fromLTRB(13, 17, 19, 23));
    expect(next.allocatedDecorationInsets, const EdgeInsets.all(5));
  });

  testWidgets(
    'Badge rejects nonuniform actual border and negative current allocation',
    (tester) async {
      final capture = GlobalKey();
      const result = coui.DisclosureBadge(
        kind: coui.CoreDisclosureKind.open,
        label: 'solid',
        disclosureBadgeStyle: coui.CoreDisclosureBadgeStyle(
          borderWidth: 3,
          padding: coui.CoreEdgeInsets.zero,
        ),
      );
      await _mount(tester, result, capture);
      final binding = _bind(capture, result, 'disclosure-badge');
      final render = binding.frameSource.renderObject! as RenderDecoratedBox;
      final original = render.decoration as BoxDecoration;
      render.decoration = original.copyWith(
        border: const Border(
          left: BorderSide(width: 2),
          right: BorderSide(width: 4),
        ),
      );
      expect(() => _read(binding), throwsA(isA<BoxObservationError>()));
      render.decoration = original.copyWith(border: Border.all(width: 17));
      expect(() => _read(binding), throwsA(isA<BoxObservationError>()));
    },
  );

  testWidgets(
    'layout units exclude all whole foreign inputs even with large padding',
    (tester) async {
      final factories = <String, Widget Function(List<Widget>)>{
        'page-header': (s) => coui.PageHeader(
          eyebrow: s[0],
          title: s[1],
          description: s[2],
          actions: [s[3]],
        ),
        'sidebar': (s) => coui.Sidebar(
          type: coui.CoreSidebarType.twoPane,
          railHeader: s[0],
          railItems: [s[1]],
          header: s[2],
          children: [s[3]],
        ),
        'category-breakdown': (s) => coui.CategoryBreakdown(
          variant: coui.CoreCategoryBreakdownVariant.donut,
          center: s[0],
          empty: s[1],
          items: const [coui.CoreCategoryBreakdownItem(label: 'a', value: 1)],
        ),
        'trend-chart': (s) =>
            coui.TrendChart(summary: s[0], empty: s[1], points: const []),
      };
      for (final entry in factories.entries) {
        final slots = List.generate(
          4,
          (i) => _foreign(31 + i.toDouble(), label: 'slot$i'),
        );
        final result = entry.value(slots);
        final capture = GlobalKey();
        // Sidebar's Expanded regions need the same finite example constraint.
        final actual = entry.key == 'sidebar'
            ? SizedBox(height: 500, child: result)
            : result;
        await _mount(tester, actual, capture);
        final producer = entry.key == 'sidebar'
            ? (actual as SizedBox).child!
            : actual;
        final root = entry.key == 'sidebar'
            ? tester.element(find.byWidget(producer))
            : capture.currentContext! as Element;
        final binding = bindStructuredRootBoxSource(
          captureRoot: root,
          registryResult: producer,
          source: _source(entry.key),
        )!;
        expect(_read(binding).value, EdgeInsets.zero);
        expect(binding.scope.foreignBoundaries, isNotEmpty);
        for (final boundary in binding.scope.foreignBoundaries) {
          expect(
            () => binding.scope.requireOwned(boundary),
            throwsA(isA<BoxObservationError>()),
          );
        }
      }
    },
  );

  testWidgets(
    'TabPane selection/strip checks raw identities before omission',
    (tester) async {
      final capture = GlobalKey();
      final a = _foreign(61);
      final b = _foreign(73);
      final leading = _foreign(11);
      final badge = _foreign(17);
      final trailing = _foreign(23);
      final tabs = [
        coui.CoreTabItem<Widget>(
          label: 'a',
          content: a,
          leading: leading,
          badge: badge,
          trailing: trailing,
        ),
        coui.CoreTabItem<Widget>(label: 'b', content: b),
      ];
      StructuredRootBoxSourceBinding? held;
      for (final variant in [
        coui.CoreTabPaneVariant.boxed,
        coui.CoreTabPaneVariant.editorStrip,
      ]) {
        for (final selected in [0, 1]) {
          final result = coui.TabPane(
            tabs: tabs,
            selectedIndex: selected,
            variant: variant,
            tabPaneStyle: const coui.CoreTabPaneStyle(
              barPadding: coui.CoreEdgeInsets.only(
                left: 3,
                top: 5,
                right: 7,
                bottom: 11,
              ),
            ),
          );
          await _mount(tester, result, capture);
          if (held != null) {
            expect(() => _read(held!), throwsA(isA<BoxObservationError>()));
          }
          held = _bind(capture, result, 'tab-pane');
          expect(_read(held).value, const EdgeInsets.fromLTRB(3, 5, 7, 11));
          expect(
            held.scope.foreignBoundaries,
            hasLength(variant == coui.CoreTabPaneVariant.boxed ? 4 : 3),
          );
        }
      }
    },
  );

  testWidgets('empty typed TabPane still owns actual bar padding', (
    tester,
  ) async {
    for (final variant in [
      coui.CoreTabPaneVariant.boxed,
      coui.CoreTabPaneVariant.editorStrip,
    ]) {
      final capture = GlobalKey();
      final result = coui.TabPane(
        tabs: const [],
        selectedIndex: 0,
        variant: variant,
        tabPaneStyle: const coui.CoreTabPaneStyle(
          barPadding: coui.CoreEdgeInsets.fromLTRB(3, 5, 7, 11),
        ),
      );
      await _mount(tester, result, capture);
      expect(
        _read(_bind(capture, result, 'tab-pane')).value,
        const EdgeInsets.fromLTRB(3, 5, 7, 11),
      );
    }
  });

  testWidgets(
    'WindowPanel minimize keeps frame distinct from body padding',
    (tester) async {
      final capture = GlobalKey();
      StructuredRootBoxSourceBinding? held;
      for (final minimized in [false, true]) {
        final result = coui.WindowPanel(
          title: const Text('title'),
          actions: _foreign(13),
          isMinimized: minimized,
          windowPanelStyle: const coui.CoreWindowPanelStyle(
            containerBorderWidth: 3,
            contentPadding: coui.CoreEdgeInsets.all(29),
          ),
          child: _foreign(83),
        );
        await _mount(tester, result, capture);
        if (held != null) {
          expect(() => _read(held!), throwsA(isA<BoxObservationError>()));
        }
        held = _bind(capture, result, 'window-panel');
        expect(_read(held).value, EdgeInsets.zero);
        expect(_read(held).allocatedDecorationInsets, EdgeInsets.zero);
        expect(held.scope.foreignBoundaries, hasLength(minimized ? 2 : 3));
      }
    },
  );

  testWidgets(
    'duplicates include currently unrendered fields and inactive tab content',
    (tester) async {
      final slot = _foreign(9);
      final cases = <({String component, Widget result})>[
        (
          component: 'basic',
          result: coui.Basic(title: slot, subtitle: slot, showSubtitle: false),
        ),
        (
          component: 'sidebar',
          result: coui.Sidebar(header: slot, railHeader: slot),
        ),
        (
          component: 'category-breakdown',
          result: coui.CategoryBreakdown(
            center: slot,
            empty: slot,
            items: const [coui.CoreCategoryBreakdownItem(label: 'a', value: 1)],
          ),
        ),
        (
          component: 'trend-chart',
          result: coui.TrendChart(
            summary: slot,
            empty: slot,
            points: [coui.CoreTrendPoint(date: DateTime(2026), value: 1)],
          ),
        ),
        (
          component: 'tab-pane',
          result: coui.TabPane(
            variant: coui.CoreTabPaneVariant.editorStrip,
            selectedIndex: 0,
            tabs: [
              coui.CoreTabItem<Widget>(label: 'a', content: slot),
              coui.CoreTabItem<Widget>(label: 'b', content: slot),
            ],
          ),
        ),
        (
          component: 'window-panel',
          result: coui.WindowPanel(title: slot, isMinimized: true, child: slot),
        ),
      ];
      for (final item in cases) {
        final capture = GlobalKey();
        final result = item.component == 'sidebar'
            ? SizedBox(height: 400, child: item.result)
            : item.result;
        await _mount(tester, result, capture);
        final root = item.component == 'sidebar'
            ? tester.element(find.byWidget(item.result))
            : capture.currentContext! as Element;
        expect(
          () => bindStructuredRootBoxSource(
            captureRoot: root,
            registryResult: item.result,
            source: _source(item.component),
          ),
          throwsA(isA<BoxObservationError>()),
        );
      }
    },
  );

  testWidgets(
    'unknown producers/records/current operations fail closed',
    (tester) async {
      final cases = <({String component, Widget result})>[
        (component: 'basic', result: const _UnknownBasic()),
        (
          component: 'multiple-choice',
          result: const coui.MultipleChoice<int>(
            options: [(value: 1, label: 'a')],
          ),
        ),
        (
          component: 'tab-pane',
          result: const coui.TabPane(tabs: [_UnknownTab()], selectedIndex: 0),
        ),
        (
          component: 'disclosure-badge',
          result: const coui.DisclosureBadge(
            kind: coui.CoreDisclosureKind.private,
            label: 'dashed',
          ),
        ),
        (
          component: 'category-breakdown',
          result: coui.CategoryBreakdown(items: const [], empty: _foreign(67)),
        ),
        (
          component: 'tree',
          result: coui.Tree(
            nodes: const [coui.CoreTreeNode(label: 'a')],
            trailingBuilder: (_, _, {required expanded}) =>
                throw StateError('not used by observer'),
          ),
        ),
      ];
      for (final item in cases) {
        final capture = GlobalKey();
        // The real renderer may call builders; use an actual foreign tree slot,
        // never a throwing renderer callback. The observer must not replay it.
        final result = item.component == 'tree'
            ? coui.Tree(
                nodes: const [coui.CoreTreeNode(label: 'a')],
                trailingBuilder: (_, _, {required expanded}) => _foreign(7),
              )
            : item.result;
        await _mount(tester, result, capture);
        expect(
          () => _bind(capture, result, item.component),
          throwsA(isA<BoxObservationError>()),
        );
      }
    },
  );
}
