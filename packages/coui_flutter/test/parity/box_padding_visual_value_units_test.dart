import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' show SvgPicture;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_visual_value_units.dart';

const _recipes = <({String component, String variant})>[
  (component: 'icon', variant: 'default'),
  (component: 'icon', variant: 'favorite'),
  (component: 'icon', variant: 'search'),
  (component: 'number-ticker', variant: 'default'),
  (component: 'skeleton', variant: 'text'),
  (component: 'countdown', variant: 'default'),
];

BoxObservationSourceSpec _source(String component) => switch (component) {
  'icon' => BoxObservationSourceSpec.iconVisualFrame,
  'number-ticker' => BoxObservationSourceSpec.numberTickerTextLayoutHost,
  'skeleton' => BoxObservationSourceSpec.skeletonTextLinesLayoutHost,
  'countdown' => BoxObservationSourceSpec.countdownValueLayoutHost,
  _ => throw StateError(component),
};

Future<void> _mount(
  WidgetTester tester,
  Widget result,
  GlobalKey capture, {
  bool dark = false,
}) async {
  // buildTestApp's Overlay initial entries retain their original child.
  // A fresh host makes every declared result the actual mounted input.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      SizedBox(
        width: 800,
        height: 600,
        child: Align(
          alignment: Alignment.topLeft,
          child: KeyedSubtree(key: capture, child: result),
        ),
      ),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  // Skeleton repeats indefinitely. Source binding needs its actual current
  // frame, not an invented settled animation value or pumpAndSettle timeout.
  await tester.pump(const Duration(milliseconds: 20));
}

VisualValueBoxSourceBinding _bind(
  GlobalKey capture,
  Widget result,
  String component,
) => bindVisualValueBoxSource(
  captureRoot: capture.currentContext! as Element,
  registryResult: result,
  source: _source(component),
)!;

class _UnknownIcon extends coui.Icon {
  const _UnknownIcon() : super(coui.LucideIcons.house);
  Widget get undeclaredSlot => const Padding(
    padding: EdgeInsets.all(71),
    child: Text('foreign'),
  );
}

class _UnknownTicker extends coui.NumberTicker {
  const _UnknownTicker() : super(value: 1);
}

class _UnknownSkeleton extends coui.Skeleton {
  const _UnknownSkeleton() : super.text();
}

class _UnknownCountdown extends coui.Countdown {
  const _UnknownCountdown() : super(value: 7);
}

void main() {
  for (final recipe in _recipes) {
    for (final dark in [false, true]) {
      testWidgets('${recipe.component}/${recipe.variant}/$dark real frame', (
        tester,
      ) async {
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
          ..requireOwned(binding.paddingSource)
          ..requireOwned(binding.frameSource);
        expect(actual.owner, same(binding.fieldUnitElement));
        expect(actual.producer, same(binding.registryResultElement));
        expect(actual.frameOwner, same(binding.frameSource));
        expect(actual.quantity, PaddingQuantityKind.declaredNoOwnPadding);
        expect(actual.value, EdgeInsets.zero);
        expect(actual.paddingElement, isNull);
        expect(binding.scope.foreignBoundaries, isEmpty);
        expect(binding.readActualPadding, throwsA(isA<BoxObservationError>()));
        if (recipe.component == 'number-ticker') {
          expect(binding.allOriginalSuppliedSlots, [null]);
          expect(
            binding.fieldUnitElement.findRenderObject(),
            isA<RenderParagraph>(),
          );
        } else {
          expect(binding.allOriginalSuppliedSlots, isEmpty);
        }
        if (recipe.component == 'icon') {
          final frame = binding.fieldUnitElement.widget as SizedBox;
          expect(frame.child, isA<SvgPicture>());
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Skeleton current generated lines survive animation', (
    tester,
  ) async {
    const result = coui.Skeleton.text(
      skeletonStyle: coui.CoreSkeletonStyle(lines: 4),
    );
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result, 'skeleton');
    final frame = binding.frameSource;
    expect((frame.widget as Column).children, hasLength(4));
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 37));
      binding.validateExistingCurrentBinding();
      expect(binding.readDeclaredAbsence().frameOwner, same(frame));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ticker animation is observed without replaying its builder', (
    tester,
  ) async {
    const result = coui.NumberTicker(value: 987, initialValue: 0);
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result, 'number-ticker');
    final frame = binding.frameSource;
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 41));
      binding.validateExistingCurrentBinding();
      expect(binding.readDeclaredAbsence().frameOwner, same(frame));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('an actual unloaded Icon still owns its constrained frame', (
    tester,
  ) async {
    // TestWidgetsFlutterBinding blocks real HttpClient requests. The public
    // unbundled operation therefore retains its genuine unloaded placeholder;
    // no private State or resolver cache is replaced by this test.
    const result = coui.Icon(
      coui.IconName('visual-value-source-test', 'missing-glyph'),
    );
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result, 'icon');
    final field = binding.fieldUnitElement;
    expect(field.widget, isA<SizedBox>());
    expect((field.widget as SizedBox).child, isNull);
    expect(field.findRenderObject(), isA<RenderConstrainedBox>());
    expect(binding.readDeclaredAbsence().frameOwner, same(field));
    expect(tester.takeException(), isNull);
  });

  testWidgets('plain constructor modes reject caller builder and formatter', (
    tester,
  ) async {
    var builderCalls = 0;
    const foreign = Padding(
      padding: EdgeInsets.fromLTRB(71, 83, 97, 113),
      child: Text('whole caller slot'),
    );
    final custom = coui.NumberTicker.builder(
      value: 3,
      child: foreign,
      builder: (context, value, child) {
        builderCalls++;
        return child!;
      },
    );
    final capture = GlobalKey();
    await _mount(tester, custom, capture);
    final originalBuilderCalls = builderCalls;
    expect(originalBuilderCalls, greaterThan(0));
    expect(
      () => _bind(capture, custom, 'number-ticker'),
      throwsA(isA<BoxObservationError>()),
    );
    expect(builderCalls, originalBuilderCalls);

    var formatterCalls = 0;
    final formatted = coui.NumberTicker(
      value: 3,
      formatter: (value) {
        formatterCalls++;
        return '$value';
      },
    );
    await _mount(tester, formatted, capture);
    final originalFormatterCalls = formatterCalls;
    expect(originalFormatterCalls, greaterThan(0));
    expect(
      () => _bind(capture, formatted, 'number-ticker'),
      throwsA(isA<BoxObservationError>()),
    );
    expect(formatterCalls, originalFormatterCalls);
  });

  testWidgets('held binding rejects replacement on the same mounted Element', (
    tester,
  ) async {
    const first = coui.Countdown(value: 7);
    const second = coui.Countdown(value: 8);
    final current = ValueNotifier<Widget>(first);
    addTearDown(current.dispose);
    final capture = GlobalKey();
    final host = ValueListenableBuilder<Widget>(
      valueListenable: current,
      builder: (context, result, child) =>
          KeyedSubtree(key: capture, child: result),
    );
    await _mount(tester, host, GlobalKey());
    final binding = _bind(capture, first, 'countdown');
    final originalElement = binding.registryResultElement;
    current.value = second;
    await tester.pump(const Duration(milliseconds: 20));
    final replacement = _bind(capture, second, 'countdown');
    expect(originalElement.mounted, isTrue);
    expect(replacement.registryResultElement, same(originalElement));
    expect(originalElement.widget, same(second));
    expect(
      replacement.readDeclaredAbsence().frameOwner,
      same(replacement.frameSource),
    );
    expect(binding.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unmounted and unrelated results cannot supply zero', (
    tester,
  ) async {
    const result = coui.Icon(coui.LucideIcons.house);
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result, 'icon');
    expect(
      () => _bind(capture, const SizedBox(), 'icon'),
      throwsA(isA<BoxObservationError>()),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(binding.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
  });

  for (final (component, result) in <(String, Widget)>[
    ('icon', const _UnknownIcon()),
    ('number-ticker', const _UnknownTicker()),
    ('skeleton', const _UnknownSkeleton()),
    ('countdown', const _UnknownCountdown()),
    ('skeleton', const coui.Skeleton()),
    ('skeleton', const coui.Skeleton.circle(size: 48)),
    (
      'icon',
      const Padding(
        padding: EdgeInsets.all(113),
        child: coui.Icon(coui.LucideIcons.house),
      ),
    ),
  ]) {
    testWidgets('unknown or noncanonical $component ${result.runtimeType}', (
      tester,
    ) async {
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      expect(
        () => _bind(capture, result, component),
        throwsA(isA<BoxObservationError>()),
      );
    });
  }

  testWidgets('closed source rejects a cross-unit adapter tuple', (
    tester,
  ) async {
    const result = coui.Icon(coui.LucideIcons.search);
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    const source = BoxObservationSourceSpec.iconVisualFrame;
    final wrong = BoxObservationSourceSpec(
      schemaVersion: 1,
      logicalUnitId: source.logicalUnitId,
      quantityId: source.quantityId,
      nativeAdapterId: 'unknown-adapter-v1',
      webAdapterId: source.webAdapterId,
    );
    expect(
      () => bindVisualValueBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: wrong,
      ),
      throwsA(isA<BoxObservationError>()),
    );
  });
}
