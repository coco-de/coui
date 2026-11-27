import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_stepper_horizontal_source.dart';

const _kProduct = ValueKey<String>('actual-public-stepper');
const _kItems = [
  coui.CoreStepItem(label: 'One'),
  coui.CoreStepItem(label: 'Two', description: ''),
  coui.CoreStepItem(label: 'Three', description: 'public input only'),
];

class _Fixture {
  _Fixture(Widget initial) : child = ValueNotifier(initial);
  final ValueNotifier<Widget> child;
  final ValueNotifier<TextDirection> direction = ValueNotifier(
    TextDirection.ltr,
  );

  Future<void> mount(WidgetTester tester) async {
    await pumpTestApp(
      tester,
      ValueListenableBuilder<Widget>(
        valueListenable: child,
        builder: (context, current, _) => ValueListenableBuilder<TextDirection>(
          valueListenable: direction,
          builder: (context, value, _) => Directionality(
            textDirection: value,
            child: SizedBox(width: 800, child: current),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    addTearDown(() {
      child.dispose();
      direction.dispose();
    });
  }

  Future<void> show(WidgetTester tester, Widget next) async {
    child.value = next;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
}

Element _product(WidgetTester tester) => tester.element(find.byKey(_kProduct));
List<Element> _columns(StepperHorizontalBinding binding) {
  final elements = <Element>[];
  binding.frameSource.visitChildren(elements.add);
  return elements;
}

List<RenderBox> _renderColumns(StepperHorizontalBinding binding) {
  final renderer = (binding.frameSource as RenderObjectElement).renderObject;
  final children = <RenderBox>[];
  renderer.visitChildren((child) {
    expect(child, isA<RenderBox>());
    children.add(child as RenderBox);
  });
  return children;
}

ContainerRenderObjectMixin<RenderBox, ContainerBoxParentData<RenderBox>>
_roster(
  StepperHorizontalBinding binding,
) =>
    (binding.frameSource as RenderObjectElement).renderObject
        as ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >;

void _changed(void Function() operation) {
  expect(
    operation,
    throwsA(
      isA<BoxObservationError>().having(
        (error) => error.code,
        'exact source boundary failure',
        'STEPPER_HORIZONTAL_SOURCE_CHANGED',
      ),
    ),
  );
}

void _healthy(StepperHorizontalBinding binding) {
  binding.validateCurrentBinding();
  final observed = binding.readDeclaredAbsence();
  expect(observed.quantity, PaddingQuantityKind.declaredNoOwnPadding);
  expect(observed.owner, same(binding.frameSource));
  expect(binding.sourceIdentity['buildOrIntrinsicReexecuted'], false);
}

class _CounterfeitStepper extends coui.Stepper {
  const _CounterfeitStepper() : super(key: _kProduct, steps: _kItems);
  @override
  Widget build(BuildContext context) => const Column(
    children: [SizedBox(width: 20, height: 20)],
  );
}

void main() {
  testWidgets('normal factory, callback non-replay, opaque pressed interior', (
    tester,
  ) async {
    var callbackCalls = 0;
    final fixture = _Fixture(
      coui.Stepper(
        key: _kProduct,
        steps: _kItems,
        currentStep: 1,
        enabled: true,
        onStepChanged: (_) {
          callbackCalls++;
        },
        stepperStyle: const coui.CoreStepperStyle(indicatorSize: 20),
      ),
    );
    await fixture.mount(tester);
    final product = _product(tester);
    expect(product.runtimeType, StatelessElement);
    final binding = bindCurrentStepperHorizontal(product);
    _healthy(binding);
    _healthy(binding);
    expect(callbackCalls, 0);

    // Real public pointer input establishes the callback is live; the reader
    // remains outside the opaque generated columns during their pressed state.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(coui.Clickable).first),
    );
    await tester.pump();
    _healthy(binding);
    expect(callbackCalls, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(callbackCalls, 1);
    _healthy(binding);
    expect(callbackCalls, 1);
  });

  testWidgets('raw nullable descriptions, empty strings and aliases stay raw', (
    tester,
  ) async {
    const aliased = coui.CoreStepItem(label: 'alias');
    final items = <coui.CoreStepItem>[
      aliased,
      const coui.CoreStepItem(label: '', description: ''),
      aliased,
    ];
    expect(identical(items[0], items[2]), true);
    final fixture = _Fixture(coui.Stepper(key: _kProduct, steps: items));
    await fixture.mount(tester);
    final binding = bindCurrentStepperHorizontal(_product(tester));
    _healthy(binding);
    final identity = binding.sourceIdentity;
    final raw = identity['rawStepItems']! as List;
    expect(raw, hasLength(3));
    expect((raw[0] as Map)['description'], isNull);
    expect((raw[1] as Map)['label'], '');
    expect((raw[1] as Map)['description'], '');
    expect((raw[2] as Map)['aliasesEarlier'], [0]);
    expect(
      raw.every((row) => (row as Map)['descriptionMountedClaim'] == false),
      true,
    );
    final elements = _columns(binding);
    final renderers = _renderColumns(binding);
    expect((Set<Element>.identity()..addAll(elements)), hasLength(3));
    expect((Set<RenderBox>.identity()..addAll(renderers)), hasLength(3));
    expect(identity['generatedColumns'], hasLength(3));
    void noMeasurements(Object? value) {
      if (value is Map) {
        expect(
          value.keys,
          isNot(
            anyElement(
              isIn(const {
                'value',
                'currentRenderPadding',
                'allocatedDecorationInsets',
                'excludedMargin',
                'measurement',
              }),
            ),
          ),
        );
        value.values.forEach(noMeasurements);
      } else if (value is List) {
        value.forEach(noMeasurements);
      }
    }

    noMeasurements(identity);
  });

  testWidgets('empty normal operation still proves its whole factory', (
    tester,
  ) async {
    final fixture = _Fixture(const coui.Stepper(key: _kProduct, steps: []));
    await fixture.mount(tester);
    final binding = bindCurrentStepperHorizontal(_product(tester));
    _healthy(binding);
    expect(_columns(binding), isEmpty);
    expect(_renderColumns(binding), isEmpty);
    expect(binding.sourceIdentity['rawStepItems'], isEmpty);
    expect(binding.sourceIdentity['generatedColumns'], isEmpty);
  });

  testWidgets('counterfeit public subclass is healthy but not the factory', (
    tester,
  ) async {
    final fixture = _Fixture(const _CounterfeitStepper());
    await fixture.mount(tester);
    _changed(() => bindCurrentStepperHorizontal(_product(tester)));
  });
  testWidgets('an unrelated generic layout cannot supply this absence', (
    tester,
  ) async {
    final fixture = _Fixture(
      const Column(
        key: _kProduct,
        children: [SizedBox(width: 20, height: 20)],
      ),
    );
    await fixture.mount(tester);
    _changed(() => bindCurrentStepperHorizontal(_product(tester)));
  });
  testWidgets('healthy vertical public Stepper is outside horizontal proof', (
    tester,
  ) async {
    final fixture = _Fixture(
      const coui.Stepper(
        key: _kProduct,
        steps: _kItems,
        orientation: coui.CoreStepperOrientation.vertical,
      ),
    );
    await fixture.mount(tester);
    _changed(() => bindCurrentStepperHorizontal(_product(tester)));
  });

  for (final mutation in ['drop', 'extra', 'reorder']) {
    testWidgets('complete public generated widget roster rejects $mutation', (
      tester,
    ) async {
      final fixture = _Fixture(
        const coui.Stepper(key: _kProduct, steps: _kItems),
      );
      await fixture.mount(tester);
      final binding = bindCurrentStepperHorizontal(_product(tester));
      _healthy(binding);
      final generated =
          (binding.frameSource.widget as MultiChildRenderObjectWidget).children;
      final originals = List<Widget>.of(generated);
      try {
        switch (mutation) {
          case 'drop':
            generated.removeAt(1);
          case 'extra':
            generated.add(const Column());
          case 'reorder':
            generated[0] = originals[1];
            generated[1] = originals[0];
        }
        _changed(binding.validateCurrentBinding);
        _changed(binding.readDeclaredAbsence);
      } finally {
        generated
          ..clear()
          ..addAll(originals);
      }
      await tester.pump();
      _healthy(binding);
      _healthy(bindCurrentStepperHorizontal(_product(tester)));
    });
  }

  for (final mutation in ['missing', 'extra', 'reorder']) {
    testWidgets('actual complete renderer roster rejects $mutation', (
      tester,
    ) async {
      final fixture = _Fixture(
        const coui.Stepper(key: _kProduct, steps: _kItems),
      );
      await fixture.mount(tester);
      final binding = bindCurrentStepperHorizontal(_product(tester));
      _healthy(binding);
      final roster = _roster(binding);
      final originals = _renderColumns(binding);
      final extra = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(
          width: 1,
          height: 1,
        ),
      );
      try {
        switch (mutation) {
          case 'missing':
            roster.remove(originals[1]);
          case 'extra':
            roster.insert(extra, after: originals.last);
          case 'reorder':
            roster.move(originals[0], after: originals.last);
        }
        _changed(binding.validateCurrentBinding);
        _changed(binding.readDeclaredAbsence);
      } finally {
        switch (mutation) {
          case 'missing':
            roster.insert(originals[1], after: originals[0]);
          case 'extra':
            roster.remove(extra);
          case 'reorder':
            roster.move(originals[0], after: null);
        }
        extra.dispose();
      }
      await tester.pump();
      _healthy(binding);
      _healthy(bindCurrentStepperHorizontal(_product(tester)));
    });
  }

  testWidgets(
    'raw item replacement is rejected before quantities, restore works',
    (
      tester,
    ) async {
      final items = List<coui.CoreStepItem>.of(_kItems);
      final fixture = _Fixture(coui.Stepper(key: _kProduct, steps: items));
      await fixture.mount(tester);
      final binding = bindCurrentStepperHorizontal(_product(tester));
      try {
        items[1] = const coui.CoreStepItem(label: 'replaced raw input');
        _changed(binding.validateCurrentBinding);
        _changed(binding.readDeclaredAbsence);
      } finally {
        items[1] = _kItems[1];
      }
      _healthy(binding);
    },
  );

  testWidgets(
    'public widget rebuild invalidates held and permits fresh binding',
    (
      tester,
    ) async {
      final fixture = _Fixture(
        const coui.Stepper(key: _kProduct, steps: _kItems),
      );
      await fixture.mount(tester);
      final oldProduct = _product(tester);
      final binding = bindCurrentStepperHorizontal(oldProduct);
      await fixture.show(
        tester,
        const coui.Stepper(
          key: _kProduct,
          steps: _kItems,
          currentStep: 2,
          enabled: false,
          stepperStyle: coui.CoreStepperStyle(indicatorSize: 24),
        ),
      );
      expect(_product(tester), same(oldProduct));
      _changed(binding.validateCurrentBinding);
      _healthy(bindCurrentStepperHorizontal(_product(tester)));
    },
  );
  testWidgets('inherited direction change invalidates held and fresh binds', (
    tester,
  ) async {
    final fixture = _Fixture(
      const coui.Stepper(key: _kProduct, steps: _kItems),
    );
    await fixture.mount(tester);
    final binding = bindCurrentStepperHorizontal(_product(tester));
    fixture.direction.value = TextDirection.rtl;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    _changed(binding.validateCurrentBinding);
    _healthy(bindCurrentStepperHorizontal(_product(tester)));
  });
  testWidgets(
    'public detach invalidates old root without another mount claim',
    (
      tester,
    ) async {
      final fixture = _Fixture(
        const coui.Stepper(key: _kProduct, steps: _kItems),
      );
      await fixture.mount(tester);
      final oldProduct = _product(tester);
      final binding = bindCurrentStepperHorizontal(oldProduct);
      await fixture.show(tester, const SizedBox.shrink());
      expect(oldProduct.mounted, false);
      _changed(binding.validateCurrentBinding);
      _changed(binding.readDeclaredAbsence);
    },
  );
}
