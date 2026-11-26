import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart'
    show
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        SizedBox,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_responsive_layout_units.dart';

const double _kForeignInset = 4;
const double _kForeignChanged = 12;
const double _kOwnedInset = 17;
const double _kOwnedChanged = 23;
const double _kHostWidth = 500;
const double _kHostHeight = 300;
const _kRecipes = <({String component, String variant})>[
  (component: 'responsive-row-column', variant: 'default'),
  (component: 'responsive-row-column', variant: 'desktop'),
  (component: 'responsive-container', variant: 'default'),
  (component: 'responsive-grid', variant: 'default'),
  (component: 'responsive-grid', variant: 'span'),
];
BoxObservationSourceSpec _source(String component) => switch (component) {
  'responsive-row-column' => BoxObservationSourceSpec.responsiveFlexLayoutHost,
  'responsive-container' =>
    BoxObservationSourceSpec.responsiveContainerContentInset,
  _ => BoxObservationSourceSpec.responsiveGridLayoutHost,
};
ResponsiveLayoutBoxSourceBinding _bind(
  GlobalKey key,
  Widget actual,
  String component,
) => bindResponsiveLayoutBoxSource(
  captureRoot: key.currentContext! as Element,
  registryResult: actual,
  source: _source(component),
)!;
Widget _producer(String component, GlobalKey key, List<Widget> slots) =>
    switch (component) {
      'responsive-row-column' => coui.ResponsiveRowColumn(
        key: key,
        children: slots,
      ),
      'responsive-container' => coui.ResponsiveContainer(
        key: key,
        child: slots.single,
      ),
      _ => coui.ResponsiveGrid(key: key, responsive: false, children: slots),
    };
BoxPaddingObservation _read(ResponsiveLayoutBoxSourceBinding binding) {
  binding.validateExistingCurrentBinding();
  return binding.readerId == 'current-render-padding-v1'
      ? observeSourceOwnedRenderPadding(
          owner: binding.paddingSource,
          scope: binding.scope,
        )
      : binding.readDeclaredAbsence();
}

class _UnknownFlex extends coui.ResponsiveRowColumn {
  const _UnknownFlex() : super(children: const [SizedBox()]);
}

class _UnknownContainer extends coui.ResponsiveContainer {
  const _UnknownContainer() : super(child: const SizedBox());
}

class _UnknownGrid extends coui.ResponsiveGrid {
  const _UnknownGrid() : super(children: const [SizedBox()]);
}

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant}/dark=$dark actual registry source',
        (tester) async {
          final actual = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final capture = GlobalKey();
          await tester.pumpWidget(
            buildTestApp(
              KeyedSubtree(key: capture, child: actual),
              theme: coui.ThemeData.fromCore(
                dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final binding = _bind(capture, actual, recipe.component);
          expect(binding.scope.producer, same(binding.registryResultElement));
          expect(binding.frameSource, same(binding.paddingSource));
          final observed = _read(binding);
          expect(
            observed.quantity,
            recipe.component == 'responsive-container'
                ? PaddingQuantityKind.frameworkOwnParameter
                : PaddingQuantityKind.declaredNoOwnPadding,
          );
          expect(binding.scope.foreignBoundaries, isNotEmpty);
          for (final boundary in binding.scope.foreignBoundaries) {
            expect(
              () => binding.scope.requireOwned(boundary),
              throwsA(isA<BoxObservationError>()),
            );
          }
          if (recipe.component == 'responsive-container') {
            expect(
              binding.readDeclaredAbsence,
              throwsA(isA<BoxObservationError>()),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final component in [
    'responsive-row-column',
    'responsive-container',
    'responsive-grid',
  ]) {
    testWidgets('$component foreign mutation retains source owner', (
      tester,
    ) async {
      final inset = ValueNotifier<double>(_kForeignInset);
      final foreign = GlobalKey();
      final slot = ValueListenableBuilder<double>(
        key: foreign,
        valueListenable: inset,
        builder: (context, value, child) => Padding(
          padding: EdgeInsets.all(value),
          child: const SizedBox(width: 12, height: 8),
        ),
      );
      final actual = _producer(component, GlobalKey(), [slot]);
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: _kHostWidth,
            height: _kHostHeight,
            child: KeyedSubtree(key: capture, child: actual),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final binding = _bind(capture, actual, component);
      final before = _read(binding);
      final held = foreign.currentContext;
      inset.value = _kForeignChanged;
      await tester.pumpAndSettle();
      expect(foreign.currentContext, same(held));
      expect(binding.scope.foreignBoundaries.single, same(held));
      expect(
        (tester.widget(
                  find.descendant(
                    of: find.byKey(foreign),
                    matching: find.byType(Padding),
                  ),
                )
                as Padding)
            .padding,
        const EdgeInsets.all(_kForeignChanged),
      );
      expect(_read(binding).value, before.value);
      expect(
        () => binding.scope.requireOwned(foreign.currentContext! as Element),
        throwsA(isA<BoxObservationError>()),
      );
      expect(tester.takeException(), isNull);
      inset.dispose();
    });
    testWidgets('$component original input replacement rejects held witness', (
      tester,
    ) async {
      final key = GlobalKey();
      final first = _producer(component, key, [
        const SizedBox(width: 12, height: 8),
      ]);
      final current = ValueNotifier<Widget>(first);
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: _kHostWidth,
            height: _kHostHeight,
            child: ValueListenableBuilder<Widget>(
              valueListenable: current,
              builder: (context, value, child) =>
                  KeyedSubtree(key: capture, child: value),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final old = _bind(capture, first, component);
      final next = _producer(component, key, [
        const SizedBox(width: 20, height: 8),
      ]);
      current.value = next;
      await tester.pumpAndSettle();
      expect(
        old.validateExistingCurrentBinding,
        throwsA(isA<BoxObservationError>()),
      );
      expect(_bind(capture, next, component).scope.producer, isA<Element>());
      current.dispose();
    });
    testWidgets('$component stale tuple and foreign wrapper reject', (
      tester,
    ) async {
      final actual = _producer(component, GlobalKey(), [const SizedBox()]);
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: actual)),
      );
      await tester.pumpAndSettle();
      final source = _source(component);
      final changed = BoxObservationSourceSpec(
        schemaVersion: 99,
        logicalUnitId: source.logicalUnitId,
        quantityId: source.quantityId,
        nativeAdapterId: source.nativeAdapterId,
        webAdapterId: source.webAdapterId,
      );
      expect(
        () => bindResponsiveLayoutBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: actual,
          source: changed,
        ),
        throwsA(isA<BoxObservationError>()),
      );
      expect(
        () => bindResponsiveLayoutBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: SizedBox(child: actual),
          source: source,
        ),
        throwsA(isA<BoxObservationError>()),
      );
    });
  }
  for (final component in ['responsive-row-column', 'responsive-grid']) {
    testWidgets('$component raw duplicate rejects before mounted filtering', (
      tester,
    ) async {
      const repeated = SizedBox(width: 12, height: 8);
      final actual = _producer(component, GlobalKey(), [repeated, repeated]);
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: _kHostWidth,
            height: _kHostHeight,
            child: KeyedSubtree(key: capture, child: actual),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        () => _bind(capture, actual, component),
        throwsA(isA<BoxObservationError>()),
      );
    });
  }
  for (final input in <({String component, Widget value})>[
    (component: 'responsive-row-column', value: const _UnknownFlex()),
    (component: 'responsive-container', value: const _UnknownContainer()),
    (component: 'responsive-grid', value: const _UnknownGrid()),
  ]) {
    testWidgets('${input.component} unknown concrete subtype rejects', (
      tester,
    ) async {
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: input.value)),
      );
      await tester.pumpAndSettle();
      expect(
        () => _bind(capture, input.value, input.component),
        throwsA(isA<BoxObservationError>()),
      );
    });
  }
  testWidgets('Container changed real own parameter requires a fresh binding', (
    tester,
  ) async {
    final capture = GlobalKey();
    final producerKey = GlobalKey();
    Widget create(double value) => coui.ResponsiveContainer(
      key: producerKey,
      padding: coui.CoreEdgeInsets.all(value),
      child: const SizedBox(width: 12, height: 8),
    );
    final original = create(_kOwnedInset);
    final state = ValueNotifier<Widget>(original);
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<Widget>(
          valueListenable: state,
          builder: (context, value, child) =>
              KeyedSubtree(key: capture, child: value),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final old = _bind(capture, original, 'responsive-container');
    final before = _read(old);
    expect(before.value, const EdgeInsets.all(_kOwnedInset));
    final next = create(_kOwnedChanged);
    state.value = next;
    await tester.pumpAndSettle();
    expect(
      old.validateExistingCurrentBinding,
      throwsA(isA<BoxObservationError>()),
    );
    expect(
      _read(_bind(capture, next, 'responsive-container')).value,
      const EdgeInsets.all(_kOwnedChanged),
    );
    state.dispose();
  });
  testWidgets('Container corrupted render padding rejects source forwarding', (
    tester,
  ) async {
    const actual = coui.ResponsiveContainer(child: SizedBox());
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: actual)),
    );
    await tester.pumpAndSettle();
    final binding = _bind(capture, actual, 'responsive-container');
    final render = binding.paddingSource.renderObject! as RenderPadding;
    final saved = render.padding;
    render.padding = const EdgeInsets.all(_kOwnedChanged);
    expect(
      binding.validateExistingCurrentBinding,
      throwsA(isA<BoxObservationError>()),
    );
    render.padding = saved;
  });
  testWidgets(
    'Grid permits current generated frame rebuild without builder re-entry',
    (tester) async {
      final width = ValueNotifier<double>(_kHostWidth);
      const actual = coui.ResponsiveGrid(
        children: [SizedBox(width: 12, height: 8)],
      );
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<double>(
            valueListenable: width,
            builder: (context, value, child) => SizedBox(
              width: value,
              child: KeyedSubtree(key: capture, child: actual),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final binding = _bind(capture, actual, 'responsive-grid');
      final generated = binding.frameSource.widget;
      width.value = _kHostWidth - 80;
      await tester.pumpAndSettle();
      expect(binding.frameSource.widget, isNot(same(generated)));
      binding.validateExistingCurrentBinding();
      expect(
        binding.readDeclaredAbsence().quantity,
        PaddingQuantityKind.declaredNoOwnPadding,
      );
      width.dispose();
    },
  );
  testWidgets(
    'Container inherited style observes current parameter with held input',
    (tester) async {
      final inset = ValueNotifier<double>(_kOwnedInset);
      const actual = coui.ResponsiveContainer(
        child: SizedBox(width: 12, height: 8),
      );
      final capture = GlobalKey();
      final heldInput = KeyedSubtree(key: capture, child: actual);
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<double>(
            valueListenable: inset,
            builder: (context, value, child) => coui.Theme(
              data: coui.ThemeData.fromCore(coui.CoreThemePresets.light)
                  .copyWith(
                    coreComponentTheme: () => coui.CoreComponentTheme(
                      responsiveContainer: coui.CoreResponsiveContainerTheme(
                        style: coui.CoreResponsiveContainerStyle(
                          horizontalPadding: coui.CoreEdgeInsets.all(value),
                        ),
                      ),
                    ),
                  ),
              child: heldInput,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final binding = _bind(capture, actual, 'responsive-container');
      final owner = binding.paddingSource;
      final generated = owner.widget;
      expect(_read(binding).value, const EdgeInsets.all(_kOwnedInset));
      inset.value = _kOwnedChanged;
      await tester.pumpAndSettle();
      expect(binding.paddingSource, same(owner));
      expect(binding.registryResultElement.widget, same(actual));
      expect(owner.widget, isNot(same(generated)));
      binding.validateExistingCurrentBinding();
      expect(_read(binding).value, const EdgeInsets.all(_kOwnedChanged));
      expect(tester.takeException(), isNull);
      inset.dispose();
    },
  );
}
