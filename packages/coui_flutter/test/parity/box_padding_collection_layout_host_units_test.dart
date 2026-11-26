import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/calendar/calendar_default_example.dart';
import 'package:docs_core/previews/examples/flutter/definition_list/definition_list_default_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart'
    show RenderFlex, RenderIntrinsicWidth, RenderTable, RenderWrap;
import 'package:flutter/widgets.dart'
    show
        Column,
        EdgeInsets,
        Element,
        GlobalKey,
        IntrinsicWidth,
        KeyedSubtree,
        Padding,
        SizedBox,
        Table,
        UniqueKey,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_collection_layout_host_units.dart';
import 'box_padding_observation.dart';

const BoxObservationSourceSpec _kCalendar =
    BoxObservationSourceSpec.calendarLayoutHost;
const BoxObservationSourceSpec _kDefinition =
    BoxObservationSourceSpec.definitionListLayoutHost;
const _kForeignBefore = 4.0;
const _kForeignAfter = 12.0;
const _kRecipes =
    <({String component, String variant, BoxObservationSourceSpec source})>[
      (component: 'calendar', variant: 'single', source: _kCalendar),
      (component: 'calendar', variant: 'range', source: _kCalendar),
      (component: 'calendar', variant: 'multi', source: _kCalendar),
      (component: 'calendar', variant: 'none', source: _kCalendar),
      (component: 'calendar', variant: 'markers', source: _kCalendar),
      (component: 'definition-list', variant: 'default', source: _kDefinition),
      (component: 'definition-list', variant: 'columns', source: _kDefinition),
      (component: 'definition-list', variant: 'inline', source: _kDefinition),
    ];

class _UnknownCalendar extends coui.Calendar {
  const _UnknownCalendar();
}

class _UnknownDefinition extends coui.DefinitionList {
  const _UnknownDefinition() : super(items: const []);
}

class _UnknownEntry extends coui.CoreDefinitionEntry<Widget> {
  const _UnknownEntry() : super(term: 'unknown', description: 'value');
}

Future<({GlobalKey key, CollectionLayoutHostBoxSourceBinding binding})> _mount(
  WidgetTester tester,
  Widget result,
  BoxObservationSourceSpec source, {
  bool dark = false,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    buildTestApp(
      KeyedSubtree(key: key, child: result),
      disableAnimations: true,
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  await tester.pump();
  return (
    key: key,
    binding: bindCollectionLayoutHostBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: source,
    )!,
  );
}

Matcher get _sourceError => throwsA(isA<BoxObservationError>());

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark current host',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final mounted = await _mount(
            tester,
            result,
            recipe.source,
            dark: dark,
          );
          final binding = mounted.binding;
          expect(binding.registryResultElement.widget, same(result));
          expect(binding.scope.producer, same(binding.registryResultElement));
          expect(binding.frameSource, same(binding.fieldUnitElement));
          expect(binding.paddingSource, same(binding.fieldUnitElement));
          expect(binding.readerId, 'collection-host-declared-absence-v1');
          final observation = binding.readDeclaredAbsence();
          expect(observation.owner, same(binding.fieldUnitElement));
          expect(
            observation.quantity,
            PaddingQuantityKind.declaredNoOwnPadding,
          );
          expect(observation.paddingElement, isNull);
          expect(observation.generatedSlots, isNotEmpty);
          expect(observation.value, EdgeInsets.zero);
          final expected = recipe.component == 'calendar'
              ? RenderIntrinsicWidth
              : switch (recipe.variant) {
                  'columns' => RenderTable,
                  'inline' => RenderWrap,
                  _ => RenderFlex,
                };
          expect(binding.frameSource.renderObject.runtimeType, expected);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Calendar reads preserve callback counts and current month rebuilds',
    (tester) async {
      var stateCalls = 0;
      var markerCalls = 0;
      var changes = 0;
      final result = coui.Calendar.single(
        initialView: const coui.CoreCalendarView(2026, 11),
        stateBuilder: (_) {
          stateCalls++;
          return coui.CoreCalendarDateState.enabled;
        },
        markerBuilder: (_) {
          markerCalls++;
          return null;
        },
        onChanged: (_) {
          changes++;
        },
      );
      final mounted = await _mount(tester, result, _kCalendar);
      final binding = mounted.binding;
      final counts = (stateCalls, markerCalls, changes);
      final generatedWidget = binding.frameSource.widget;
      binding
        ..readDeclaredAbsence()
        ..readDeclaredAbsence();
      expect((stateCalls, markerCalls, changes), counts);
      expect(stateCalls, greaterThan(0));
      expect(markerCalls, greaterThan(0));
      // Source-order navigation control; no expected size or padding selection.
      final buttons = find.descendant(
        of: find.byWidget(result),
        matching: find.byType(coui.Button),
      );
      await tester.tap(buttons.first);
      await tester.pump();
      final afterBuild = (stateCalls, markerCalls, changes);
      expect(binding.frameSource.widget, isNot(same(generatedWidget)));
      binding.readDeclaredAbsence();
      expect((stateCalls, markerCalls, changes), afterBuild);
      expect(tester.takeException(), isNull);
    },
  );

  for (final layout in coui.CoreDefinitionLayout.values) {
    testWidgets('rich foreign padding/$layout cannot donate host inset', (
      tester,
    ) async {
      final amount = ValueNotifier<double>(_kForeignBefore);
      addTearDown(amount.dispose);
      final foreignKey = GlobalKey();
      final rich = ValueListenableBuilder<double>(
        valueListenable: amount,
        builder: (_, value, _) => Padding(
          key: foreignKey,
          padding: EdgeInsets.all(value),
          child: const coui.Text('foreign'),
        ),
      );
      final result = coui.DefinitionList(
        layout: layout,
        items: [
          coui.CoreDefinitionEntry<Widget>.rich(
            term: 'rich',
            description: rich,
          ),
        ],
      );
      final binding = (await _mount(tester, result, _kDefinition)).binding;
      expect(binding.scope.foreignBoundaries.single.widget, same(rich));
      expect(
        () => binding.scope.requireOwned(foreignKey.currentContext! as Element),
        _sourceError,
      );
      final before = binding.readDeclaredAbsence().value;
      amount.value = _kForeignAfter;
      await tester.pump();
      expect(
        (foreignKey.currentWidget! as Padding).padding,
        EdgeInsets.all(amount.value),
      );
      expect(binding.readDeclaredAbsence().value, before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Table cell spacing remains separate during actual theme rebuild',
    (tester) async {
      final amount = ValueNotifier<double>(coui.CoreSpace.space16);
      addTearDown(amount.dispose);
      final key = GlobalKey();
      const result = coui.DefinitionList(
        layout: coui.CoreDefinitionLayout.columns,
        items: [
          coui.CoreDefinitionEntry<Widget>(term: 'one', description: 'value'),
          coui.CoreDefinitionEntry<Widget>(term: 'two', description: 'value'),
        ],
      );
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<double>(
            valueListenable: amount,
            child: KeyedSubtree(key: key, child: result),
            builder: (_, value, child) => coui.Theme(
              data: coui.ThemeData.fromCore(coui.CoreThemePresets.light)
                  .copyWith(
                    coreComponentTheme: () => coui.CoreComponentTheme(
                      definitionList: coui.CoreDefinitionListTheme(
                        style: coui.CoreDefinitionListStyle(
                          entrySpacing: value,
                          pairSpacing: value,
                        ),
                      ),
                    ),
                  ),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pump();
      final binding = bindCollectionLayoutHostBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: _kDefinition,
      )!;
      final frameWidget = binding.frameSource.widget;
      final cell =
          (binding.frameSource.widget as Table).children[1].children[1];
      expect((cell as Padding).padding, isNot(EdgeInsets.zero));
      binding.readDeclaredAbsence();
      amount.value = coui.CoreSpace.space32;
      await tester.pump();
      expect(binding.frameSource.widget, isNot(same(frameWidget)));
      expect(binding.frameSource.renderObject.runtimeType, RenderTable);
      final nextCell =
          (binding.frameSource.widget as Table).children[1].children[1]
              as Padding;
      expect(nextCell.padding, isNot(cell.padding));
      expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
      expect(tester.takeException(), isNull);
    },
  );

  for (final source in [_kCalendar, _kDefinition]) {
    for (final example in [true, false]) {
      testWidgets(
        'same-mounted replaced input/$example/${source.logicalUnitId} rejects held witness',
        (tester) async {
          final inputKey = UniqueKey();
          Widget input() => source == _kCalendar
              ? (example
                    ? CalendarDefaultExample(key: inputKey)
                    : coui.Calendar.single(key: inputKey))
              : (example
                    ? DefinitionListDefaultExample(key: inputKey)
                    : coui.DefinitionList(key: inputKey, items: const []));
          final current = ValueNotifier<Widget>(input());
          addTearDown(current.dispose);
          final key = GlobalKey();
          await tester.pumpWidget(
            buildTestApp(
              ValueListenableBuilder<Widget>(
                valueListenable: current,
                builder: (_, value, _) => KeyedSubtree(key: key, child: value),
              ),
            ),
          );
          await tester.pump();
          CollectionLayoutHostBoxSourceBinding bind() =>
              bindCollectionLayoutHostBoxSource(
                captureRoot: key.currentContext! as Element,
                registryResult: current.value,
                source: source,
              )!;
          final old = bind();
          final element = old.registryResultElement;
          current.value = input();
          await tester.pump();
          expect(element.mounted, true);
          expect(element.widget, same(current.value));
          expect(old.readDeclaredAbsence, _sourceError);
          expect(() => bind().readDeclaredAbsence(), returnsNormally);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'unknown producers records wrappers and raw rich duplicates reject',
    (tester) async {
      const rich = Padding(
        padding: EdgeInsets.all(_kForeignBefore),
        child: coui.Text('supplied'),
      );
      const cases = <(Widget, BoxObservationSourceSpec)>[
        (_UnknownCalendar(), _kCalendar),
        (_UnknownDefinition(), _kDefinition),
        (coui.DefinitionList(items: [_UnknownEntry()]), _kDefinition),
        (
          coui.DefinitionList(
            items: [
              coui.CoreDefinitionEntry<Widget>.rich(
                term: 'a',
                description: rich,
              ),
              coui.CoreDefinitionEntry<Widget>.rich(
                term: 'b',
                description: rich,
              ),
            ],
          ),
          _kDefinition,
        ),
        (
          Padding(padding: EdgeInsets.zero, child: coui.Calendar.single()),
          _kCalendar,
        ),
        (Column(children: [coui.DefinitionList(items: [])]), _kDefinition),
      ];
      for (final (result, source) in cases) {
        await tester.pumpWidget(const SizedBox.shrink());
        final key = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(
            KeyedSubtree(key: key, child: result),
            disableAnimations: true,
          ),
        );
        await tester.pump();
        expect(
          () => bindCollectionLayoutHostBoxSource(
            captureRoot: key.currentContext! as Element,
            registryResult: result,
            source: source,
          ),
          _sourceError,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'schema tuple capture identity missing and unmounted fail closed',
    (tester) async {
      const result = CalendarDefaultExample();
      final mounted = await _mount(tester, result, _kCalendar);
      for (final change in [
        {'schemaVersion': 99},
        {'quantityId': 'unknown'},
        {'nativeAdapterId': 'unknown'},
        {'webAdapterId': 'unknown'},
      ]) {
        expect(
          () => bindCollectionLayoutHostBoxSource(
            captureRoot: mounted.key.currentContext! as Element,
            registryResult: result,
            source: BoxObservationSourceSpec.fromJson({
              ..._kCalendar.toJson(),
              ...change,
            }),
          ),
          _sourceError,
        );
      }
      expect(
        () => bindCollectionLayoutHostBoxSource(
          captureRoot: mounted.key.currentContext! as Element,
          registryResult: CalendarDefaultExample(key: UniqueKey()),
          source: _kCalendar,
        ),
        _sourceError,
      );
      expect(
        bindCollectionLayoutHostBoxSource(
          captureRoot: mounted.key.currentContext! as Element,
          registryResult: result,
          source: BoxObservationSourceSpec.fromJson({
            ..._kCalendar.toJson(),
            'logicalUnitId': 'unknown',
          }),
        ),
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(mounted.binding.readDeclaredAbsence, _sourceError);
    },
  );

  testWidgets('concrete host corruption is incomplete rather than absent', (
    tester,
  ) async {
    const result = CalendarDefaultExample();
    final binding = (await _mount(tester, result, _kCalendar)).binding;
    final host = binding.frameSource;
    final original = host.widget as IntrinsicWidth;
    tester.binding.buildOwner!.buildScope(host, () {
      host.update(
        IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.all(_kForeignBefore),
            child: original.child,
          ),
        ),
      );
    });
    await tester.pump();
    expect(binding.readDeclaredAbsence, _sourceError);
    expect(tester.takeException(), isNull);
  });
}
