import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderDecoratedBox;
import 'package:flutter/widgets.dart'
    show
        Border,
        BoxDecoration,
        Container,
        DecoratedBox,
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

import '../../../../tool/parity/src/manifest/capture_probes.dart';
import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_form_collection_units.dart';
import 'box_padding_observation.dart';
import 'box_padding_paired.dart';
import 'box_padding_source_bindings.dart';
import 'parity_matrix_entry.dart';

const _kPump = Duration(milliseconds: 400);
const _kRecipes = <({String component, String variant})>[
  (component: 'toggle-group', variant: 'default'),
  (component: 'toggle-group', variant: 'vertical'),
  (component: 'form-field', variant: 'default'),
  (component: 'form-label', variant: 'default'),
  (component: 'listing', variant: 'default'),
  (component: 'option-list', variant: 'default'),
];

BoxObservationSourceSpec _source(String component) => switch (component) {
  'toggle-group' => BoxObservationSourceSpec.toggleGroupTrackContentInset,
  'form-field' => BoxObservationSourceSpec.formFieldLayoutHost,
  'form-label' => BoxObservationSourceSpec.formLabelRowLayoutHost,
  'listing' => BoxObservationSourceSpec.listingRowsLayoutHost,
  _ => BoxObservationSourceSpec.optionListLayoutHost,
};

Widget _producer(String component, List<Widget> slots, {GlobalKey? key}) =>
    switch (component) {
      'toggle-group' => coui.ToggleGroup<String>(
        key: key,
        value: 'a',
        onChanged: (_) {},
        items: [
          coui.CoreToggleGroupItem(value: 'a', label: 'A', icon: slots[0]),
        ],
        trailing: slots[1],
      ),
      'form-field' => coui.FormField(
        key: key,
        labelWidget: slots[0],
        child: slots[1],
      ),
      'form-label' => coui.FormLabel(
        key: key,
        label: slots[0],
        isRequired: true,
        requiredIndicator: slots[1],
      ),
      'listing' => coui.Listing(key: key, itemBorder: true, children: slots),
      _ => coui.OptionList(key: key, children: slots),
    };

Future<
  ({
    GlobalKey capture,
    FormCollectionBoxSourceBinding binding,
    ValueNotifier<Widget> input,
  })
>
_mount(
  WidgetTester tester,
  Widget result,
  BoxObservationSourceSpec source, {
  bool dark = false,
  GlobalKey? capture,
}) async {
  final key = capture ?? GlobalKey();
  final input = ValueNotifier<Widget>(result);
  addTearDown(input.dispose);
  // Overlay.initialEntries retains its initial child. New independent fixtures
  // need a fresh shell; replacements within one fixture use the mounted input.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    buildTestApp(
      SizedBox(
        width: 440,
        height: 420,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: ValueListenableBuilder<Widget>(
            valueListenable: input,
            builder: (_, current, _) => KeyedSubtree(key: key, child: current),
          ),
        ),
      ),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  await tester.pump(_kPump);
  return (
    capture: key,
    input: input,
    binding: bindFormCollectionBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: source,
    )!,
  );
}

BoxPaddingObservation _read(FormCollectionBoxSourceBinding binding) {
  binding.validateExistingCurrentBinding();
  return binding.readerId == 'outlined-content-v1'
      ? observeOutlinedContainerContentPadding(
          primitive: binding.paddingSource,
          declaringScope: binding.scope,
        )
      : binding.readDeclaredAbsence();
}

Matcher get _sourceError => throwsA(isA<BoxObservationError>());

class _UnknownToggle extends coui.ToggleGroup<String> {
  const _UnknownToggle({required super.onChanged})
    : super(
        value: 'a',
        items: const [coui.CoreToggleGroupItem(value: 'a', label: 'A')],
      );
}

class _UnknownField extends coui.FormField {
  const _UnknownField();
}

class _UnknownLabel extends coui.FormLabel {
  const _UnknownLabel() : super(label: null);
}

class _UnknownListing extends coui.Listing {
  const _UnknownListing() : super(children: const []);
}

class _UnknownOptions extends coui.OptionList {
  const _UnknownOptions() : super(children: const []);
}

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark actual registry and shared dispatch',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final source = _source(recipe.component);
          final mounted = await _mount(tester, result, source, dark: dark);
          final binding = mounted.binding;
          expect(binding.registryResultElement.widget, same(result));
          expect(binding.paddingSource, same(binding.frameSource));
          final read = _read(binding);
          if (recipe.component == 'toggle-group') {
            expect(
              binding.paddingSource.widget.runtimeType,
              coui.OutlinedContainer,
            );
            expect(read.quantity, PaddingQuantityKind.frameworkOwnParameter);
            expect(read.frameOwner!.widget.runtimeType, Container);
            expect(binding.readDeclaredAbsence, _sourceError);
          } else {
            expect(read.quantity, PaddingQuantityKind.declaredNoOwnPadding);
            expect(read.value, EdgeInsets.zero);
            expect(read.paddingElement, isNull);
          }
          expect(read.value, isNot(const EdgeInsets.all(40)));
          final probe = captureProbes(
            key: 'unit',
            component: recipe.component,
            variant: recipe.variant,
            flutterClassName: 'sanity-only',
          ).single;
          Map<Object?, Object?> observe(bool omitted) =>
              (observePairedNativePadding(
                        key: 'unit',
                        probes: [
                          ParityProbeSpec(
                            role: probe.role,
                            flutterFinder: probe.flutterFinder,
                            fields: probe.fields
                                .map((field) => field.name)
                                .toSet(),
                            boxObservationSource: source.toJson(),
                          ),
                        ],
                        captureRoot: mounted.capture.currentContext! as Element,
                        registryResult: result,
                        legacyRootOmitted: omitted,
                      )['byRole']!
                      as Map)['root']!
                  as Map;
          final actual = observe(false);
          expect(actual['status'], 'source-complete', reason: '$actual');
          expect(actual['sourceReaderId'], binding.readerId);
          expect(actual['source'], source.toJson());
          expect(actual['canonicalComparisonEligible'], isFalse);
          final withoutLegacy = observe(true);
          expect(withoutLegacy['status'], 'source-complete');
          expect(withoutLegacy['value'], actual['value']);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final component in [
    'toggle-group',
    'form-field',
    'form-label',
    'listing',
    'option-list',
  ]) {
    testWidgets(
      '$component whole foreign changing padding cannot donate its inset',
      (tester) async {
        final amount = ValueNotifier<double>(4);
        addTearDown(amount.dispose);
        final slots = <Widget>[
          for (var i = 0; i < 2; i++)
            ValueListenableBuilder<double>(
              valueListenable: amount,
              builder: (_, value, _) => Padding(
                padding: EdgeInsets.all(value),
                child: const SizedBox(width: 8, height: 8),
              ),
            ),
        ];
        final result = _producer(component, slots);
        final binding = (await _mount(
          tester,
          result,
          _source(component),
        )).binding;
        final before = _read(binding).value;
        expect(binding.scope.foreignBoundaries, hasLength(2));
        for (final boundary in binding.scope.foreignBoundaries) {
          expect(() => binding.scope.requireOwned(boundary), _sourceError);
        }
        amount.value = 12;
        await tester.pump(_kPump);
        expect(_read(binding).value, before);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '$component same Element with new producer input rejects stale witness',
      (tester) async {
        final key = GlobalKey();
        final slots = <Widget>[
          const SizedBox(width: 8, height: 8),
          const SizedBox(width: 9, height: 8),
        ];
        final first = _producer(component, slots, key: key);
        final mounted = await _mount(tester, first, _source(component));
        final held = key.currentContext;
        mounted.input.value = _producer(component, slots, key: key);
        await tester.pump(_kPump);
        expect(key.currentContext, same(held));
        expect(mounted.binding.validateExistingCurrentBinding, _sourceError);
      },
    );
    testWidgets('$component duplicate raw slots are rejected before omission', (
      tester,
    ) async {
      const shared = SizedBox(width: 8, height: 8);
      final result = switch (component) {
        'form-label' => const coui.FormLabel(
          label: shared,
          requiredIndicator: shared,
        ),
        'form-field' => const coui.FormField(
          labelAction: shared,
          child: shared,
        ),
        _ => _producer(component, [shared, shared]),
      };
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: result)),
      );
      await tester.pump(_kPump);
      expect(
        () => bindFormCollectionBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: result,
          source: _source(component),
        ),
        _sourceError,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'actual outer track decoration allocation is checked, not its target style',
    (tester) async {
      final result = _producer('toggle-group', [
        const SizedBox(width: 8, height: 8),
        const SizedBox(width: 9, height: 8),
      ]);
      final binding = (await _mount(
        tester,
        result,
        _source('toggle-group'),
      )).binding;
      final frame = _read(binding).frameOwner!;
      final decoration = (frame.widget as Container).decoration;
      final owner = requireOneBoxOwner(
        boxElements(frame).where(
          (element) =>
              element.widget is DecoratedBox &&
              identical(
                (element.widget as DecoratedBox).decoration,
                decoration,
              ),
        ),
        'the exact outer frame decoration',
      );
      final render = owner.renderObject! as RenderDecoratedBox;
      final original = render.decoration;
      render.decoration = BoxDecoration(border: Border.all(width: 3));
      expect(binding.validateExistingCurrentBinding, _sourceError);
      render.decoration = original;
      binding.validateExistingCurrentBinding();
    },
  );
  testWidgets(
    'omitted immutable label marker and label action stay declared '
    'without mounting',
    (tester) async {
      for (final result in <Widget>[
        const coui.FormLabel(
          label: coui.Text('label'),
          requiredIndicator: SizedBox(),
        ),
        const coui.FormField(
          labelAction: SizedBox(),
          child: SizedBox(width: 8, height: 8),
        ),
      ]) {
        final component = result is coui.FormLabel
            ? 'form-label'
            : 'form-field';
        final binding = (await _mount(
          tester,
          result,
          _source(component),
        )).binding;
        expect(_read(binding).value, EdgeInsets.zero);
      }
    },
  );
  testWidgets('unknown concrete subclasses never inherit source authority', (
    tester,
  ) async {
    final unknown = <String, Widget>{
      'toggle-group': _UnknownToggle(onChanged: (_) {}),
      'form-field': const _UnknownField(),
      'form-label': const _UnknownLabel(),
      'listing': const _UnknownListing(),
      'option-list': const _UnknownOptions(),
    };
    for (final entry in unknown.entries) {
      await tester.pumpWidget(const SizedBox());
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: entry.value)),
      );
      await tester.pump(_kPump);
      expect(
        () => bindFormCollectionBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: entry.value,
          source: _source(entry.key),
        ),
        _sourceError,
      );
    }
  });
}
