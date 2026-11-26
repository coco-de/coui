import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderFlex, RenderStack;
import 'package:flutter/widgets.dart'
    show
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        Row,
        SizedBox,
        Stack,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_sequence_layout_units.dart';

const BoxObservationSourceSpec _kStack =
    BoxObservationSourceSpec.stackLayoutOverlapHost;
const BoxObservationSourceSpec _kIndexed =
    BoxObservationSourceSpec.indexedSwitcherLayoutHost;
const BoxObservationSourceSpec _kSwap =
    BoxObservationSourceSpec.swapOverlapLayoutHost;
const BoxObservationSourceSpec _kDivider =
    BoxObservationSourceSpec.dividerLabelledSequenceHost;
const double _kWidth = 320;
const double _kHeight = 240;
const double _kBefore = 4;
const double _kAfter = 12;
const Duration _kPump = Duration(milliseconds: 400);
const _kRecipes =
    <({String component, String variant, BoxObservationSourceSpec source})>[
      (component: 'stack-layout', variant: 'default', source: _kStack),
      (component: 'indexed-switcher', variant: 'default', source: _kIndexed),
      (component: 'swap', variant: 'default', source: _kSwap),
      (component: 'swap', variant: 'rotate', source: _kSwap),
      (component: 'divider', variant: 'with-child', source: _kDivider),
    ];

Widget _producer(
  BoxObservationSourceSpec source,
  GlobalKey key,
  List<Widget> slots,
) {
  if (source == _kStack) return coui.Stacks(key: key, children: slots);
  if (source == _kIndexed) {
    return coui.IndexedSwitcher(key: key, children: slots);
  }
  if (source == _kSwap) {
    return coui.Swap(
      key: key,
      onToggle: (_) {},
      offContent: slots[0],
      onContent: slots[1],
    );
  }
  return coui.Divider(key: key, child: slots.single);
}

int _slotCount(BoxObservationSourceSpec source) => source == _kDivider ? 1 : 2;

Future<({GlobalKey capture, SequenceLayoutBoxSourceBinding binding})> _mount(
  WidgetTester tester,
  Widget result,
  BoxObservationSourceSpec source, {
  bool dark = false,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    buildTestApp(
      SizedBox(
        width: _kWidth,
        height: _kHeight,
        child: KeyedSubtree(key: key, child: result),
      ),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  await tester.pump(_kPump);
  return (
    capture: key,
    binding: bindSequenceLayoutBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: source,
    )!,
  );
}

Matcher get _sourceError => throwsA(isA<BoxObservationError>());

class _UnknownStacks extends coui.Stacks {
  const _UnknownStacks() : super(children: const [SizedBox()]);
}

class _UnknownIndexed extends coui.IndexedSwitcher {
  const _UnknownIndexed() : super(children: const [SizedBox()]);
}

class _UnknownSwap extends coui.Swap {
  const _UnknownSwap()
    : super(offContent: const SizedBox(), onContent: const SizedBox());
}

class _UnknownDivider extends coui.Divider {
  const _UnknownDivider() : super(child: const SizedBox());
}

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark current source',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final binding = (await _mount(
            tester,
            result,
            recipe.source,
            dark: dark,
          )).binding;
          expect(binding.registryResultElement.widget, same(result));
          expect(binding.scope.producer, same(binding.registryResultElement));
          expect(binding.fieldUnitElement, same(binding.frameSource));
          expect(binding.paddingSource, same(binding.frameSource));
          expect(binding.readerId, 'sequence-layout-declared-absence-v1');
          binding.validateExistingCurrentBinding();
          final read = binding.readDeclaredAbsence();
          expect(read.value, EdgeInsets.zero);
          expect(read.quantity, PaddingQuantityKind.declaredNoOwnPadding);
          expect(read.paddingElement, isNull);
          expect(read.owner, same(binding.frameSource));
          expect(
            binding.frameSource.renderObject.runtimeType,
            recipe.source == _kDivider ? RenderFlex : RenderStack,
          );
          expect(binding.scope.foreignBoundaries, isNotEmpty);
          for (final foreign in binding.scope.foreignBoundaries) {
            expect(() => binding.scope.requireOwned(foreign), _sourceError);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final source in [_kStack, _kIndexed, _kSwap, _kDivider]) {
    testWidgets(
      '${source.logicalUnitId} whole foreign4 to12 cannot donate padding',
      (tester) async {
        final amount = ValueNotifier<double>(_kBefore);
        addTearDown(amount.dispose);
        final keys = List.generate(_slotCount(source), (_) => GlobalKey());
        final slots = <Widget>[
          for (final key in keys)
            ValueListenableBuilder<double>(
              valueListenable: amount,
              builder: (_, value, _) => Padding(
                key: key,
                padding: EdgeInsets.all(value),
                child: const SizedBox(width: 12, height: 8),
              ),
            ),
        ];
        final result = _producer(source, GlobalKey(), slots);
        final binding = (await _mount(tester, result, source)).binding;
        final held = [for (final key in keys) key.currentContext! as Element];
        binding.readDeclaredAbsence();
        amount.value = _kAfter;
        await tester.pump(_kPump);
        for (var i = 0; i < keys.length; i++) {
          expect(keys[i].currentContext, same(held[i]));
          expect(
            (held[i].widget as Padding).padding,
            const EdgeInsets.all(_kAfter),
          );
          expect(() => binding.scope.requireOwned(held[i]), _sourceError);
        }
        expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${source.logicalUnitId} same Element new input rejects held witness',
      (tester) async {
        final producerKey = GlobalKey();
        final capture = GlobalKey();
        final slots = <Widget>[
          for (var i = 0; i < _slotCount(source); i++) coui.Text('slot$i'),
        ];
        final first = _producer(source, producerKey, slots);
        final current = ValueNotifier<Widget>(first);
        addTearDown(current.dispose);
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              width: _kWidth,
              height: _kHeight,
              child: ValueListenableBuilder<Widget>(
                valueListenable: current,
                builder: (_, widget, _) =>
                    KeyedSubtree(key: capture, child: widget),
              ),
            ),
          ),
        );
        await tester.pump(_kPump);
        final binding = bindSequenceLayoutBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: first,
          source: source,
        )!;
        final element = producerKey.currentContext! as Element;
        final next = _producer(source, producerKey, List<Widget>.of(slots));
        current.value = next;
        await tester.pump(_kPump);
        expect(producerKey.currentContext, same(element));
        expect(element.widget, same(next));
        expect(binding.validateExistingCurrentBinding, _sourceError);
        expect(binding.readDeclaredAbsence, _sourceError);
        final fresh = bindSequenceLayoutBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: next,
          source: source,
        )!;
        expect(fresh.readDeclaredAbsence().value, EdgeInsets.zero);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Position whole subtree stays foreign', (tester) async {
    final label = GlobalKey();
    final position = coui.Position(
      top: 0,
      child: Padding(
        key: label,
        padding: const EdgeInsets.all(_kAfter),
        child: const SizedBox(width: 12, height: 8),
      ),
    );
    final result = coui.Stacks(children: [position]);
    final binding = (await _mount(tester, result, _kStack)).binding;
    expect(binding.scope.foreignBoundaries.single.widget, same(position));
    expect(
      () => binding.scope.requireOwned(label.currentContext! as Element),
      _sourceError,
    );
    expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
  });
  testWidgets(
    'current generated Divider row may rebuild with owned label/line inset changes',
    (tester) async {
      final amount = ValueNotifier<double>(_kBefore);
      addTearDown(amount.dispose);
      final capture = GlobalKey();
      const result = coui.Divider(child: coui.Text('supplied label'));
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<double>(
            valueListenable: amount,
            child: SizedBox(
              width: _kWidth,
              height: _kHeight,
              child: KeyedSubtree(key: capture, child: result),
            ),
            builder: (_, value, child) => coui.Theme(
              data: coui.ThemeData.fromCore(coui.CoreThemePresets.light)
                  .copyWith(
                    coreComponentTheme: () => coui.CoreComponentTheme(
                      divider: coui.CoreDividerTheme(
                        style: coui.CoreDividerStyle(
                          indent: value,
                          endIndent: value,
                          childPadding: coui.CoreEdgeInsets.symmetric(
                            horizontal: value,
                          ),
                        ),
                      ),
                    ),
                  ),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pump(_kPump);
      final binding = bindSequenceLayoutBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _kDivider,
      )!;
      final oldWidget = binding.frameSource.widget;
      final oldPad = ((oldWidget as Row).children[1] as Padding).padding;
      amount.value = _kAfter;
      await tester.pump(_kPump);
      expect(binding.frameSource.widget, isNot(same(oldWidget)));
      final newPad =
          ((binding.frameSource.widget as Row).children[1] as Padding).padding;
      expect(newPad, isNot(oldPad));
      binding.validateExistingCurrentBinding();
      expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Swap animation ticks rebuild generated Widgets without extra callbacks',
    (tester) async {
      final checked = ValueNotifier<bool>(false);
      addTearDown(checked.dispose);
      final capture = GlobalKey();
      var calls = 0;
      late coui.Swap current;
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: _kWidth,
            height: _kHeight,
            child: ValueListenableBuilder<bool>(
              valueListenable: checked,
              builder: (_, value, _) {
                current = coui.Swap(
                  checked: value,
                  animation: .rotate,
                  onToggle: (next) {
                    calls++;
                    checked.value = next;
                  },
                  offContent: const coui.Text('off'),
                  onContent: const coui.Text('on'),
                );
                return KeyedSubtree(key: capture, child: current);
              },
            ),
          ),
        ),
      );
      await tester.pump();
      final held = bindSequenceLayoutBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: current,
        source: _kSwap,
      )!..readDeclaredAbsence();
      expect(calls, 0);
      await tester.tap(find.byWidget(current));
      await tester.pump();
      expect(calls, 1);
      expect(held.readDeclaredAbsence, _sourceError);
      final fresh = bindSequenceLayoutBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: current,
        source: _kSwap,
      )!;
      final generated = fresh.frameSource.widget;
      await tester.pump(const Duration(milliseconds: 30));
      expect(fresh.frameSource.widget, isNot(same(generated)));
      fresh
        ..validateExistingCurrentBinding()
        ..readDeclaredAbsence();
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('framework-valid source host corruption is incomplete', (
    tester,
  ) async {
    const result = coui.Stacks(children: [coui.Text('foreign')]);
    final binding = (await _mount(tester, result, _kStack)).binding;
    final frame = binding.frameSource;
    tester.binding.buildOwner!.buildScope(frame, () {
      frame.update(const Stack(children: [SizedBox.shrink()]));
    });
    await tester.pump();
    expect(binding.readDeclaredAbsence, _sourceError);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unmounted original producer never produces an absence', (
    tester,
  ) async {
    const first = coui.Stacks(children: [coui.Text('foreign')]);
    final current = ValueNotifier<Widget>(first);
    addTearDown(current.dispose);
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<Widget>(
          valueListenable: current,
          builder: (_, widget, _) => KeyedSubtree(key: capture, child: widget),
        ),
      ),
    );
    await tester.pump();
    final binding = bindSequenceLayoutBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: first,
      source: _kStack,
    )!;
    current.value = const SizedBox.shrink();
    await tester.pump();
    expect(binding.registryResultElement.mounted, isFalse);
    expect(binding.readDeclaredAbsence, _sourceError);
  });
  for (final fixture in <({Widget widget, BoxObservationSourceSpec source})>[
    (widget: const _UnknownStacks(), source: _kStack),
    (widget: const _UnknownIndexed(), source: _kIndexed),
    (widget: const _UnknownSwap(), source: _kSwap),
    (widget: const _UnknownDivider(), source: _kDivider),
    (
      widget: coui.Swap(
        animation: .flip,
        onToggle: (_) {},
        offContent: const coui.Text('off'),
        onContent: const coui.Text('on'),
      ),
      source: _kSwap,
    ),
    (
      widget: const coui.Swap(
        offContent: coui.Text('off'),
        onContent: coui.Text('on'),
      ),
      source: _kSwap,
    ),
    (widget: const coui.Divider(), source: _kDivider),
    (
      widget: const coui.Divider(
        orientation: .vertical,
        child: coui.Text('label'),
      ),
      source: _kDivider,
    ),
    (
      widget: const coui.Divider(semantic: true, child: coui.Text('label')),
      source: _kDivider,
    ),
  ]) {
    testWidgets(
      'closed source rejects ${fixture.widget.runtimeType}/${fixture.source.logicalUnitId}',
      (tester) async {
        final capture = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(
            SizedBox(
              width: _kWidth,
              height: _kHeight,
              child: KeyedSubtree(key: capture, child: fixture.widget),
            ),
          ),
        );
        await tester.pump(_kPump);
        expect(
          () => bindSequenceLayoutBoxSource(
            captureRoot: capture.currentContext! as Element,
            registryResult: fixture.widget,
            source: fixture.source,
          ),
          _sourceError,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final source in [_kStack, _kIndexed, _kSwap]) {
    testWidgets('${source.logicalUnitId} raw duplicated inputs reject', (
      tester,
    ) async {
      const shared = coui.Text('same caller');
      final result = _producer(source, GlobalKey(), [shared, shared]);
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: _kWidth,
            height: _kHeight,
            child: KeyedSubtree(key: capture, child: result),
          ),
        ),
      );
      await tester.pump(_kPump);
      expect(
        () => bindSequenceLayoutBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: result,
          source: source,
        ),
        _sourceError,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('missing capture and mismatched tuple fail without a value', (
    tester,
  ) async {
    const result = coui.Stacks(children: [coui.Text('foreign')]);
    final mounted = await _mount(tester, result, _kStack);
    for (final source in [
      BoxObservationSourceSpec.fromJson({
        ..._kStack.toJson(),
        'schemaVersion': 99,
      }),
      BoxObservationSourceSpec.fromJson({
        ..._kStack.toJson(),
        'webAdapterId': _kDivider.webAdapterId,
      }),
    ]) {
      expect(
        () => bindSequenceLayoutBoxSource(
          captureRoot: mounted.capture.currentContext! as Element,
          registryResult: result,
          source: source,
        ),
        _sourceError,
      );
    }
    expect(
      () => bindSequenceLayoutBoxSource(
        captureRoot: mounted.capture.currentContext! as Element,
        registryResult: const coui.Stacks(children: [coui.Text('different')]),
        source: _kStack,
      ),
      _sourceError,
    );
  });
}
