import 'dart:ui' show PointerDeviceKind;

import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_layout_host_units.dart';
import 'box_padding_observation.dart';

// Independent public caller input, not a design token or ownership criterion.
const double _kCallerInset = 4;
const double _kChangedCallerInset = 12;
const double _kCallerSize = 40;
const double _kCallerRatio = 2;

Matcher _changed() => throwsA(isA<BoxObservationError>());

void main() {
  const recipes = <(String, String, BoxObservationSourceSpec)>[
    ('steps', 'default', BoxObservationSourceSpec.stepsSequenceHost),
    ('steps', 'horizontal', BoxObservationSourceSpec.stepsSequenceHost),
    ('steps', 'list', BoxObservationSourceSpec.stepsSequenceHost),
    (
      'stepper',
      'vertical',
      BoxObservationSourceSpec.stepperVerticalSequenceHost,
    ),
    (
      'aspect-ratio-box',
      'default',
      BoxObservationSourceSpec.aspectRatioLayoutHost,
    ),
    ('clickable', 'default', BoxObservationSourceSpec.clickableInteractionHost),
    (
      'focus-outline',
      'default',
      BoxObservationSourceSpec.focusOutlinePassThroughHost,
    ),
    ('switch-field', 'default', BoxObservationSourceSpec.switchFieldControlRow),
  ];
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets('${recipe.$1}/${recipe.$2} dark=$dark actual source', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry[recipe.$1]!(
          recipe.$2 == 'default' ? null : recipe.$2,
        );
        final capture = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(
            KeyedSubtree(key: capture, child: result),
            theme: coui.ThemeData.fromCore(
              dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final binding = bindLayoutHostBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: result,
          source: recipe.$3,
        )!;
        final observed = binding.readDeclaredAbsence();
        expect(binding.registryResultElement.widget, same(result));
        expect(binding.scope.producer, same(binding.registryResultElement));
        expect(observed.owner, same(binding.frameSource));
        expect(observed.quantity, PaddingQuantityKind.declaredNoOwnPadding);
        expect(observed.paddingElement, isNull);
        expect(observed.value, EdgeInsets.zero);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final family in ['aspect', 'clickable', 'focus']) {
    testWidgets('$family foreign padding changes on the same mounted child', (
      tester,
    ) async {
      final amount = ValueNotifier<double>(_kCallerInset);
      final foreign = GlobalKey();
      final capture = GlobalKey();
      final child = ValueListenableBuilder<double>(
        valueListenable: amount,
        builder: (context, value, child) => Padding(
          key: foreign,
          padding: EdgeInsets.all(value),
          child: const SizedBox(width: _kCallerSize, height: _kCallerSize),
        ),
      );
      final result = switch (family) {
        'aspect' => coui.AspectRatioBox(ratio: _kCallerRatio, child: child),
        'clickable' => coui.Clickable(onPressed: () {}, child: child),
        _ => coui.FocusOutline(child: child),
      };
      final source = switch (family) {
        'aspect' => BoxObservationSourceSpec.aspectRatioLayoutHost,
        'clickable' => BoxObservationSourceSpec.clickableInteractionHost,
        _ => BoxObservationSourceSpec.focusOutlinePassThroughHost,
      };
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: result)),
      );
      await tester.pumpAndSettle();
      final binding = bindLayoutHostBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: source,
      )!;
      final element = foreign.currentContext! as Element;
      final frame = binding.frameSource;
      amount.value = _kChangedCallerInset;
      await tester.pumpAndSettle();
      expect(foreign.currentContext, same(element));
      expect(
        (element.widget as Padding).padding,
        const EdgeInsets.all(_kChangedCallerInset),
      );
      expect(binding.readDeclaredAbsence().owner, same(frame));
      expect(() => binding.scope.requireOwned(element), _changed());
      amount.dispose();
    });
  }
  testWidgets(
    'same-key producer replacement rejects old witness and fresh bind succeeds',
    (tester) async {
      final value = ValueNotifier<Widget>(
        const coui.AspectRatioBox(
          ratio: _kCallerRatio,
          child: SizedBox(width: _kCallerSize, height: _kCallerSize),
        ),
      );
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<Widget>(
            valueListenable: value,
            builder: (context, current, child) =>
                KeyedSubtree(key: capture, child: current),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final original = value.value;
      final root = capture.currentContext! as Element;
      final old = bindLayoutHostBoxSource(
        captureRoot: root,
        registryResult: original,
        source: BoxObservationSourceSpec.aspectRatioLayoutHost,
      )!;
      value.value = const coui.AspectRatioBox(
        ratio: 1,
        child: SizedBox(width: _kCallerSize, height: _kCallerSize),
      );
      await tester.pumpAndSettle();
      expect(old.readDeclaredAbsence, _changed());
      final fresh = bindLayoutHostBoxSource(
        captureRoot: root,
        registryResult: value.value,
        source: BoxObservationSourceSpec.aspectRatioLayoutHost,
      )!;
      expect(fresh.frameSource, same(old.frameSource));
      expect(fresh.readDeclaredAbsence().value, EdgeInsets.zero);
      value.dispose();
    },
  );
  testWidgets(
    'actual hover keeps a current witness without replaying callbacks',
    (tester) async {
      var presses = 0;
      final capture = GlobalKey();
      final result = coui.Clickable(
        onPressed: () => presses++,
        child: const SizedBox(width: _kCallerSize, height: _kCallerSize),
      );
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: result)),
      );
      await tester.pumpAndSettle();
      final binding = bindLayoutHostBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: BoxObservationSourceSpec.clickableInteractionHost,
      )!;
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await pointer.addPointer();
      await pointer.moveTo(tester.getCenter(find.byKey(capture)));
      await tester.pumpAndSettle();
      expect(binding.readDeclaredAbsence().owner, same(binding.frameSource));
      expect(presses, 0);
      await pointer.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'actual theme rebuild preserves source Widgets and frame Element',
    (tester) async {
      final data = ValueNotifier<coui.ThemeData>(
        coui.ThemeData.fromCore(coui.CoreThemePresets.light),
      );
      final capture = GlobalKey();
      var calls = 0;
      final result = coui.Clickable(
        onPressed: () => calls++,
        child: const SizedBox(width: _kCallerSize, height: _kCallerSize),
      );
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<coui.ThemeData>(
            valueListenable: data,
            builder: (context, value, child) => coui.Theme(
              data: value,
              child: KeyedSubtree(key: capture, child: result),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final root = capture.currentContext! as Element;
      final binding = bindLayoutHostBoxSource(
        captureRoot: root,
        registryResult: result,
        source: BoxObservationSourceSpec.clickableInteractionHost,
      )!;
      final frame = binding.frameSource;
      final originalFrameWidget = frame.widget;
      expect(
        frame.findAncestorWidgetOfExactType<coui.Theme>()!.data,
        same(data.value),
      );
      data.value = coui.ThemeData.fromCore(coui.CoreThemePresets.dark);
      await tester.pumpAndSettle();
      expect(capture.currentContext, same(root));
      expect(binding.registryResultElement.widget, same(result));
      expect(
        frame.findAncestorWidgetOfExactType<coui.Theme>()!.data,
        same(data.value),
      );
      expect(frame.widget, isNot(same(originalFrameWidget)));
      expect(binding.readDeclaredAbsence().owner, same(frame));
      expect(calls, 0);
      data.dispose();
    },
  );
  testWidgets('recreated capture wrapper around original producer is valid', (
    tester,
  ) async {
    final tick = ValueNotifier<int>(0);
    final capture = GlobalKey();
    const result = coui.FocusOutline(
      child: SizedBox(width: _kCallerSize, height: _kCallerSize),
    );
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<int>(
          valueListenable: tick,
          builder: (context, value, child) =>
              KeyedSubtree(key: capture, child: result),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final root = capture.currentContext! as Element;
    final before = root.widget;
    final binding = bindLayoutHostBoxSource(
      captureRoot: root,
      registryResult: result,
      source: BoxObservationSourceSpec.focusOutlinePassThroughHost,
    )!;
    tick.value++;
    await tester.pumpAndSettle();
    expect(root.widget, isNot(same(before)));
    expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
    tick.dispose();
  });
  for (final (index, input) in <(Widget, BoxObservationSourceSpec)>[
    (
      const coui.Stepper(steps: [coui.CoreStepItem(label: 'one source step')]),
      BoxObservationSourceSpec.stepperVerticalSequenceHost,
    ),
    (
      const coui.Clickable(focusOutline: false, child: SizedBox()),
      BoxObservationSourceSpec.clickableInteractionHost,
    ),
    (const _ForeignSteps(), BoxObservationSourceSpec.stepsSequenceHost),
    (
      const _ForeignAspect(child: SizedBox()),
      BoxObservationSourceSpec.aspectRatioLayoutHost,
    ),
  ].indexed) {
    testWidgets('unsupported public source $index rejects', (tester) async {
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: input.$1)),
      );
      await tester.pumpAndSettle();
      expect(
        () => bindLayoutHostBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: input.$1,
          source: input.$2,
        ),
        _changed(),
      );
    });
  }
  testWidgets(
    'stale tuple, unknown unit, missing producer and unmount fail closed',
    (tester) async {
      final capture = GlobalKey();
      const result = coui.FocusOutline(
        child: SizedBox(width: _kCallerSize, height: _kCallerSize),
      );
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: result)),
      );
      await tester.pumpAndSettle();
      final root = capture.currentContext! as Element;
      const source = BoxObservationSourceSpec.focusOutlinePassThroughHost;
      final wrong = BoxObservationSourceSpec(
        schemaVersion: 99,
        logicalUnitId: source.logicalUnitId,
        quantityId: source.quantityId,
        nativeAdapterId: source.nativeAdapterId,
        webAdapterId: source.webAdapterId,
      );
      expect(
        () => bindLayoutHostBoxSource(
          captureRoot: root,
          registryResult: result,
          source: wrong,
        ),
        _changed(),
      );
      expect(
        () => bindLayoutHostBoxSource(
          captureRoot: root,
          registryResult: const coui.FocusOutline(child: SizedBox()),
          source: source,
        ),
        _changed(),
      );
      expect(
        bindLayoutHostBoxSource(
          captureRoot: root,
          registryResult: result,
          source: BoxObservationSourceSpec.proxyHostFrames.first,
        ),
        isNull,
      );
      final binding = bindLayoutHostBoxSource(
        captureRoot: root,
        registryResult: result,
        source: source,
      )!;
      await tester.pumpWidget(const SizedBox.shrink());
      expect(binding.readDeclaredAbsence, _changed());
    },
  );
}

class _ForeignSteps extends coui.Steps {
  const _ForeignSteps() : super(items: const []);
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.all(_kCallerInset), child: SizedBox());
}

class _ForeignAspect extends coui.AspectRatioBox {
  const _ForeignAspect({required super.child}) : super(ratio: _kCallerRatio);
  @override
  Widget build(BuildContext context) => child;
}
