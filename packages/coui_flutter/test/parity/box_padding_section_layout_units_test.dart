import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        Semantics,
        SizedBox,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/manifest/capture_probes.dart';
import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_paired.dart';
import 'box_padding_section_layout_units.dart';
import 'parity_matrix_entry.dart';

const _kRecipes = <({String component, String variant})>[
  (component: 'disclosure', variant: 'default'),
  (component: 'disclosure', variant: 'chain'),
  (component: 'disclosure', variant: 'group'),
  (component: 'collapsible', variant: 'default'),
  (component: 'resizable', variant: 'default'),
  (component: 'breadcrumb', variant: 'default'),
];
const double _kForeignInset = 7;
const double _kForeignChangedInset = 29;
const double _kHeaderInset = 17;
const double _kChangedHeaderInset = 23;
BoxObservationSourceSpec _source(
  String component, [
  String variant = 'default',
]) => switch (component) {
  'disclosure' =>
    variant == 'group'
        ? BoxObservationSourceSpec.disclosureGroupLayoutHost
        : BoxObservationSourceSpec.disclosureHeaderContentInset,
  'collapsible' => BoxObservationSourceSpec.collapsibleSectionLayoutHost,
  'resizable' => BoxObservationSourceSpec.resizablePaneLayoutHost,
  _ => BoxObservationSourceSpec.breadcrumbTrailLayoutHost,
};
Widget _app(Widget child, {bool dark = false}) => buildTestApp(
  child,
  theme: coui.ThemeData.fromCore(
    dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
  ),
);
SectionLayoutBoxSourceBinding _bind(
  GlobalKey capture,
  Widget result,
  String component, [
  String variant = 'default',
]) => bindSectionLayoutBoxSource(
  captureRoot: capture.currentContext! as Element,
  registryResult: result,
  source: _source(component, variant),
)!;
BoxPaddingObservation _read(SectionLayoutBoxSourceBinding binding) {
  binding.validateExistingCurrentBinding();
  return binding.readerId == 'current-render-padding-v1'
      ? observeSourceOwnedRenderPadding(
          owner: binding.paddingSource,
          scope: binding.scope,
        )
      : binding.readDeclaredAbsence();
}

Widget _producer(String component, List<Widget> slots) => switch (component) {
  'disclosure' => coui.Disclosure(
    trigger: slots[0],
    content: slots[1],
    open: true,
  ),
  'group' => coui.DisclosureGroup(items: slots),
  'collapsible' => coui.Collapsible(
    trigger: slots[0],
    content: slots[1],
    expanded: true,
  ),
  'resizable' => coui.Resizable(
    panes: [
      for (final slot in slots)
        coui.CoreResizablePaneData<Widget>(content: slot),
    ],
  ),
  _ => coui.Breadcrumb(
    items: const [coui.CoreBreadcrumbItem(label: 'Home')],
    onItemTap: (_) => throw StateError('Callbacks must not be replayed'),
  ),
};

class _UnknownDisclosure extends coui.Disclosure {
  const _UnknownDisclosure()
    : super(title: 'Unknown', content: const SizedBox());
}

class _UnknownGroup extends coui.DisclosureGroup {
  const _UnknownGroup() : super(items: const []);
}

class _UnknownCollapsible extends coui.Collapsible {
  const _UnknownCollapsible()
    : super(trigger: const SizedBox(), content: const SizedBox());
}

class _UnknownResizable extends coui.Resizable {
  const _UnknownResizable() : super(panes: const []);
}

class _UnknownBreadcrumb extends coui.Breadcrumb {
  const _UnknownBreadcrumb() : super(items: const []);
}

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant}/$dark actual registry and shared dispatcher',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final capture = GlobalKey();
          await tester.pumpWidget(
            _app(
              SizedBox(
                width: 500,
                height: 300,
                child: KeyedSubtree(key: capture, child: result),
              ),
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          final binding = _bind(
            capture,
            result,
            recipe.component,
            recipe.variant,
          );
          expect(binding.scope.producer, same(binding.registryResultElement));
          expect(binding.frameSource, same(binding.paddingSource));
          final observed = _read(binding);
          final header =
              recipe.component == 'disclosure' && recipe.variant != 'group';
          expect(
            observed.quantity,
            header
                ? PaddingQuantityKind.frameworkOwnParameter
                : PaddingQuantityKind.declaredNoOwnPadding,
          );
          for (final boundary in binding.scope.foreignBoundaries) {
            expect(
              () => binding.scope.requireOwned(boundary),
              throwsA(isA<BoxObservationError>()),
            );
          }
          final probes = captureProbes(
            key: 'unit',
            component: recipe.component,
            variant: recipe.variant,
            flutterClassName: 'sanity-only',
          );
          final paired = observePairedNativePadding(
            key: 'unit',
            probes: probes.map((p) => ParityProbeSpec.fromJson(p.toJson())),
            captureRoot: capture.currentContext! as Element,
            registryResult: result,
            legacyRootOmitted: false,
          );
          final root = (paired['byRole']! as Map)['root']! as Map;
          expect(root['status'], 'source-complete');
          expect(
            root['source'],
            _source(recipe.component, recipe.variant).toJson(),
          );
          expect(root['sourceReaderId'], binding.readerId);
          expect(root['canonicalComparisonEligible'], false);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final component in ['disclosure', 'group', 'collapsible', 'resizable']) {
    testWidgets('$component whole foreign mutation cannot replace owner', (
      tester,
    ) async {
      final inset = ValueNotifier<double>(_kForeignInset);
      final foreign = List.generate(
        2,
        (index) => ValueListenableBuilder<double>(
          valueListenable: inset,
          builder: (context, value, child) => Padding(
            padding: EdgeInsets.all(value),
            child: const SizedBox(width: 20, height: 12),
          ),
        ),
      );
      final result = _producer(component, foreign);
      final capture = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 500,
            height: 300,
            child: KeyedSubtree(key: capture, child: result),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final binding = _bind(
        capture,
        result,
        component == 'group' ? 'disclosure' : component,
        component == 'group' ? 'group' : 'default',
      );
      final owner = binding.paddingSource;
      final before = _read(binding).value;
      expect(binding.scope.foreignBoundaries, hasLength(2));
      inset.value = _kForeignChangedInset;
      await tester.pumpAndSettle();
      expect(_read(binding).value, before);
      expect(binding.paddingSource, same(owner));
      for (final slot in foreign) {
        final element = tester.element(find.byWidget(slot));
        expect(
          () => binding.scope.requireOwned(element),
          throwsA(isA<BoxObservationError>()),
        );
      }
      inset.dispose();
    });
    testWidgets('$component duplicate raw inputs fail before omission', (
      tester,
    ) async {
      const slot = SizedBox(width: 20, height: 12);
      final result = _producer(component, [slot, slot]);
      final capture = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 500,
            height: 300,
            child: KeyedSubtree(key: capture, child: result),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        () => _bind(
          capture,
          result,
          component == 'group' ? 'disclosure' : component,
          component == 'group' ? 'group' : 'default',
        ),
        throwsA(isA<BoxObservationError>()),
      );
    });
  }
  for (final initial in [false, true]) {
    testWidgets(
      'Disclosure current state differs from initial=$initial '
      'and stale witness rejects',
      (tester) async {
        final trigger = Semantics(
          expanded: true,
          child: const SizedBox(width: 40, height: 20),
        );
        const content = SizedBox(width: 40, height: 20);
        final result = coui.Disclosure(
          trigger: trigger,
          content: content,
          open: initial,
        );
        final capture = GlobalKey();
        await tester.pumpWidget(
          _app(KeyedSubtree(key: capture, child: result)),
        );
        await tester.pumpAndSettle();
        final old = _bind(capture, result, 'disclosure');
        final value = _read(old).value;
        await tester.tap(
          find
              .descendant(
                of: find.byKey(capture),
                matching: find.byType(coui.Clickable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(result.open, initial);
        expect(() => _read(old), throwsA(isA<BoxObservationError>()));
        final current = _bind(capture, result, 'disclosure');
        expect(_read(current).value, value);
        expect(current.scope.foreignBoundaries, hasLength(initial ? 1 : 2));
        expect(
          current.readDeclaredAbsence,
          throwsA(isA<BoxObservationError>()),
        );
        // The trigger's supplied expanded=true Semantics is never the witness.
        if (initial) expect(find.byWidget(content), findsNothing);
      },
    );
  }
  testWidgets(
    'closed duplicate trigger/content is rejected before omitted content',
    (tester) async {
      const slot = SizedBox(width: 20, height: 12);
      const result = coui.Disclosure(trigger: slot, content: slot);
      final capture = GlobalKey();
      await tester.pumpWidget(_app(KeyedSubtree(key: capture, child: result)));
      await tester.pumpAndSettle();
      expect(
        () => _bind(capture, result, 'disclosure'),
        throwsA(isA<BoxObservationError>()),
      );
    },
  );
  testWidgets(
    'Disclosure reads actual header override and never body top padding',
    (tester) async {
      final inset = ValueNotifier<double>(_kHeaderInset);
      final capture = GlobalKey();
      Widget? actual;
      await tester.pumpWidget(
        _app(
          ValueListenableBuilder<double>(
            valueListenable: inset,
            builder: (context, value, child) {
              actual = coui.Disclosure(
                title: 'Header',
                open: true,
                disclosureStyle: coui.CoreDisclosureStyle(
                  contentInset: coui.CoreEdgeInsets.all(value),
                ),
                content: const Padding(
                  padding: EdgeInsets.all(_kForeignChangedInset),
                  child: SizedBox(width: 20, height: 12),
                ),
              );
              return KeyedSubtree(key: capture, child: actual!);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final binding = _bind(capture, actual!, 'disclosure');
      expect(_read(binding).value, const EdgeInsets.all(_kHeaderInset));
      inset.value = _kChangedHeaderInset;
      await tester.pumpAndSettle();
      expect(() => _read(binding), throwsA(isA<BoxObservationError>()));
      expect(
        _read(_bind(capture, actual!, 'disclosure')).value,
        const EdgeInsets.all(_kChangedHeaderInset),
      );
      inset.dispose();
    },
  );
  for (final item in <({String component, String variant, Widget result})>[
    (
      component: 'disclosure',
      variant: 'default',
      result: const _UnknownDisclosure(),
    ),
    (component: 'disclosure', variant: 'group', result: const _UnknownGroup()),
    (
      component: 'collapsible',
      variant: 'default',
      result: const _UnknownCollapsible(),
    ),
    (
      component: 'resizable',
      variant: 'default',
      result: const _UnknownResizable(),
    ),
    (
      component: 'breadcrumb',
      variant: 'default',
      result: const _UnknownBreadcrumb(),
    ),
    (
      component: 'disclosure',
      variant: 'default',
      result: const SizedBox(
        child: coui.Disclosure(title: 'Foreign', content: SizedBox()),
      ),
    ),
  ]) {
    testWidgets(
      'unknown constructor/wrapper ${item.result.runtimeType} fails closed',
      (tester) async {
        final capture = GlobalKey();
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 500,
              height: 300,
              child: KeyedSubtree(key: capture, child: item.result),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          () => _bind(capture, item.result, item.component, item.variant),
          throwsA(isA<BoxObservationError>()),
        );
      },
    );
  }
}
