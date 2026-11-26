import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_validation_viewport_units.dart';

const _recipes = <({String component, String variant})>[
  (component: 'formatter', variant: 'default'),
  (component: 'validated', variant: 'default'),
  (component: 'validator-hint', variant: 'default'),
  (component: 'scroll-area', variant: 'default'),
  (component: 'fade-scroll', variant: 'default'),
  (component: 'fade-scroll', variant: 'horizontal'),
  (component: 'fade-scroll', variant: 'with-scrollbar'),
  (component: 'overflow-marquee', variant: 'default'),
  (component: 'hover', variant: 'shadow'),
  (component: 'kbd', variant: 'default'),
  (component: 'kbd', variant: 'combo'),
  (component: 'kbd', variant: 'four'),
];
BoxObservationSourceSpec _source(String component) => switch (component) {
  'formatter' => BoxObservationSourceSpec.textFieldContentInset,
  'validated' => BoxObservationSourceSpec.validatedLayoutHost,
  'validator-hint' => BoxObservationSourceSpec.validatorHintMessageLayoutHost,
  'scroll-area' => BoxObservationSourceSpec.scrollAreaViewportLayoutHost,
  'fade-scroll' => BoxObservationSourceSpec.fadeScrollViewportLayoutHost,
  'overflow-marquee' =>
    BoxObservationSourceSpec.overflowMarqueeViewportLayoutHost,
  'hover' => BoxObservationSourceSpec.hoverEffectHost,
  'kbd' => BoxObservationSourceSpec.kbdKeySequenceLayoutHost,
  _ => throw StateError(component),
};
Widget _app(Widget child, {bool dark = false}) => buildTestApp(
  SizedBox(width: 480, height: 400, child: Center(child: child)),
  theme: coui.ThemeData.fromCore(
    dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
  ),
);
Future<GlobalKey> _mount(
  WidgetTester tester,
  Widget widget, {
  bool dark = false,
}) async {
  // Remount buildTestApp to refresh the Overlay initialEntries.
  await tester.pumpWidget(const SizedBox.shrink());
  final key = GlobalKey();
  await tester.pumpWidget(
    _app(
      KeyedSubtree(key: key, child: widget),
      dark: dark,
    ),
  );
  await tester.pump(const Duration(milliseconds: 32));
  await tester.pump(const Duration(milliseconds: 32));
  return key;
}

ValidationViewportBoxSourceBinding _bind(
  GlobalKey key,
  Widget widget,
  String component,
) => bindValidationViewportBoxSource(
  captureRoot: key.currentContext! as Element,
  registryResult: widget,
  source: _source(component),
)!;
BoxPaddingObservation _read(ValidationViewportBoxSourceBinding binding) =>
    binding.readerId == 'current-render-padding-v1'
    ? binding.readActualPadding()
    : binding.readDeclaredAbsence();
Widget _foreign(double inset) => Padding(
  padding: EdgeInsets.all(inset),
  child: const SizedBox(width: 120, height: 24),
);
Widget _producer(String component, double inset) => switch (component) {
  'validated' => coui.Validated(
    state: coui.CoreValidationState.invalid,
    message: _foreign(inset),
    child: _foreign(inset),
  ),
  'validator-hint' => coui.ValidatorHint(
    message: _foreign(inset),
    icon: _foreign(inset),
  ),
  'scroll-area' => coui.ScrollArea(
    scrollAreaStyle: const coui.CoreScrollAreaStyle(maxHeight: 160),
    child: _foreign(inset),
  ),
  'fade-scroll' => SizedBox(
    height: 160,
    child: coui.FadeScroll(child: _foreign(inset)),
  ),
  'overflow-marquee' => coui.OverflowMarquee(child: _foreign(inset)),
  'hover' => coui.Hover(
    effect: coui.CoreHoverEffect.shadow,
    child: _foreign(inset),
  ),
  _ => throw StateError(component),
};

class _UnknownHint extends coui.ValidatorHint {
  const _UnknownHint() : super(message: const SizedBox());
}

class _UnknownField extends coui.TextField {
  _UnknownField() : super();
}

class _UnknownScroll extends coui.ScrollArea {
  const _UnknownScroll() : super(child: const SizedBox());
}

void main() {
  group('actual registry construction, all validation24 recipes', () {
    for (final recipe in _recipes) {
      for (final dark in [false, true]) {
        testWidgets('${recipe.component}/${recipe.variant}/$dark', (
          tester,
        ) async {
          final widget = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant,
          );
          final key = await _mount(tester, widget, dark: dark);
          final binding = _bind(key, widget, recipe.component)
            ..validateExistingCurrentBinding();
          expect(binding.registryResultElement.widget, same(widget));
          expect(binding.scope.producer, same(binding.registryResultElement));
          binding.scope.requireOwned(binding.fieldUnitElement);
          binding.scope.requireOwned(binding.paddingSource);
          binding.scope.requireOwned(binding.frameSource);
          final read = _read(binding);
          expect(
            read.quantity,
            recipe.component == 'formatter'
                ? PaddingQuantityKind.frameworkOwnParameter
                : PaddingQuantityKind.declaredNoOwnPadding,
          );
          if (recipe.component != 'formatter') {
            expect(read.value, EdgeInsets.zero);
          }
          if (recipe.component == 'hover') {
            // The source fold mounts each whole raw child repeatedly.
            expect(binding.scope.foreignBoundaries.length, greaterThan(1));
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  });

  for (final affixes in [
    (false, false),
    (true, false),
    (false, true),
    (true, true),
  ]) {
    testWidgets('actual TextField asymmetric parameter, affixes $affixes', (
      tester,
    ) async {
      final input = coui.TextField(
        placeholder: const coui.Text('placeholder'),
        prefix: affixes.$1
            ? const Padding(
                padding: EdgeInsets.all(71),
                child: SizedBox(width: 8, height: 8),
              )
            : null,
        suffix: affixes.$2
            ? const Padding(
                padding: EdgeInsets.all(83),
                child: SizedBox(width: 8, height: 8),
              )
            : null,
        textFieldStyle: const coui.CoreTextFieldStyle(
          padding: coui.CoreEdgeInsets.only(
            top: 3,
            right: 17,
            bottom: 5,
            left: 29,
          ),
        ),
      );
      final key = await _mount(tester, input);
      final binding = _bind(key, input, 'formatter');
      expect(
        binding.readActualPadding().value,
        const EdgeInsets.fromLTRB(29, 3, 17, 5),
      );
      for (final foreign in binding.scope.foreignBoundaries) {
        expect(
          () => binding.scope.requireOwned(foreign),
          throwsA(isA<BoxObservationError>()),
        );
      }
    });
  }

  testWidgets('TextField retains own padding across placeholder visibility', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final input = coui.TextField(
      controller: controller,
      placeholder: const coui.Text('foreign placeholder'),
    );
    final key = await _mount(tester, input);
    final binding = _bind(key, input, 'formatter');
    final before = binding.readActualPadding();
    final frame = binding.frameSource;
    final foreign = List<Element>.of(binding.scope.foreignBoundaries);
    controller.text = '47';
    await tester.pump();
    // Visibility maintains the complete placeholder subtree in current source.
    expect(binding.readActualPadding().value, before.value);
    expect(binding.frameSource, same(frame));
    expect(binding.scope.foreignBoundaries, orderedEquals(foreign));
  });

  for (final component in [
    'validated',
    'validator-hint',
    'scroll-area',
    'overflow-marquee',
    'hover',
  ]) {
    testWidgets('$component excludes every whole foreign padding subtree', (
      tester,
    ) async {
      for (final inset in [7.0, 29.0]) {
        final input = _producer(component, inset);
        final key = await _mount(tester, input);
        final binding = _bind(key, input, component);
        expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
        expect(binding.scope.foreignBoundaries, isNotEmpty);
        for (final foreign in binding.scope.foreignBoundaries) {
          expect(
            () => binding.scope.requireOwned(foreign),
            throwsA(isA<BoxObservationError>()),
          );
        }
        if (component == 'overflow-marquee') {
          expect(binding.scope.foreignBoundaries, hasLength(1));
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'pending validation checks duplicate raw identities before omission',
    (tester) async {
      const slot = SizedBox(width: 40, height: 20);
      const input = coui.Validated(
        message: slot,
        child: slot,
      );
      final key = await _mount(tester, input);
      expect(
        () => _bind(key, input, 'validated'),
        throwsA(isA<BoxObservationError>()),
      );
    },
  );
  testWidgets('invisible or empty validation has no absence witness', (
    tester,
  ) async {
    const invisible = coui.ValidatorHint(
      visible: false,
      message: coui.Text('hidden'),
    );
    var key = await _mount(tester, invisible);
    expect(
      () => _bind(key, invisible, 'validator-hint'),
      throwsA(isA<BoxObservationError>()),
    );
    const empty = coui.Validated(
      message: coui.Text('hidden'),
    );
    key = await _mount(tester, empty);
    expect(
      () => _bind(key, empty, 'validated'),
      throwsA(isA<BoxObservationError>()),
    );
  });
  testWidgets('hint duplicate icon/message identities rejected', (
    tester,
  ) async {
    const slot = SizedBox(width: 12, height: 12);
    const input = coui.ValidatorHint(message: slot, icon: slot);
    final key = await _mount(tester, input);
    expect(
      () => _bind(key, input, 'validator-hint'),
      throwsA(isA<BoxObservationError>()),
    );
  });
  testWidgets(
    'unknown concrete builds fail before providing source authority',
    (tester) async {
      for (final entry in <(Widget, String)>[
        (const _UnknownHint(), 'validator-hint'),
        (_UnknownField(), 'formatter'),
        (const _UnknownScroll(), 'scroll-area'),
      ]) {
        final key = await _mount(tester, entry.$1);
        expect(
          () => _bind(key, entry.$1, entry.$2),
          throwsA(isA<BoxObservationError>()),
        );
      }
    },
  );
  testWidgets('single keycap input cannot masquerade as a key sequence', (
    tester,
  ) async {
    const input = coui.Kbd.icon(
      keyContent: Padding(padding: EdgeInsets.all(99), child: coui.Text('X')),
    );
    final key = await _mount(tester, input);
    expect(() => _bind(key, input, 'kbd'), throwsA(isA<BoxObservationError>()));
  });
  testWidgets('held current validation source rejects live state replacement', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final current = ValueNotifier<Widget>(
      const coui.Validated(
        state: coui.CoreValidationState.invalid,
        message: coui.Text('message'),
        child: SizedBox(width: 40, height: 20),
      ),
    );
    addTearDown(current.dispose);
    final capture = GlobalKey();
    await tester.pumpWidget(
      _app(
        ValueListenableBuilder<Widget>(
          valueListenable: current,
          builder: (_, value, _) => KeyedSubtree(key: capture, child: value),
        ),
      ),
    );
    final oldElement = capture.currentContext;
    final binding = _bind(capture, current.value, 'validated')
      ..readDeclaredAbsence();
    current.value = const coui.Validated(
      message: coui.Text('message'),
      child: SizedBox(width: 40, height: 20),
    );
    await tester.pump();
    expect(capture.currentContext, same(oldElement));
    expect(
      binding.validateExistingCurrentBinding,
      throwsA(isA<BoxObservationError>()),
    );
    expect(
      _bind(capture, current.value, 'validated').readDeclaredAbsence().value,
      EdgeInsets.zero,
    );
  });
}
