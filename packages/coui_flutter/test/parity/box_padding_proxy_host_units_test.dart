import 'dart:ui' show PointerDeviceKind;

import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/mask/mask_default_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show
        BuildContext,
        DecoratedBox,
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        SizedBox,
        Stack,
        UniqueKey,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_proxy_host_units.dart';

// Arbitrary caller-owned fixture data, deliberately independent of Core chrome.
// The changed input is reused by both the update and its observed-value check.
const double _kForeignCallerInset4 = 4;
const double _kChangedForeignCallerInset12 = 12;

const _kMask = 'mask-generated-clip-host';
const _kHover = 'hover-generated-effect-host';
const _kIndicator = 'indicator-generated-overlay-host';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: unit,
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$unit-v1',
  webAdapterId: '$unit-v1',
);

Matcher _changed() => throwsA(isA<BoxObservationError>());

void main() {
  const recipes = <({String component, String variant, String unit})>[
    (component: 'mask', variant: 'default', unit: _kMask),
    (component: 'mask', variant: 'circle', unit: _kMask),
    (component: 'mask', variant: 'heart', unit: _kMask),
    (component: 'mask', variant: 'hexagon', unit: _kMask),
    (component: 'mask', variant: 'star', unit: _kMask),
    (component: 'mask', variant: 'triangle', unit: _kMask),
    (component: 'hover', variant: 'default', unit: _kHover),
    (component: 'hover', variant: 'fade', unit: _kHover),
    (component: 'indicator', variant: 'default', unit: _kIndicator),
    (component: 'indicator', variant: 'bottom-start', unit: _kIndicator),
  ];
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark actual host',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final key = GlobalKey();
          await tester.pumpWidget(
            buildTestApp(
              KeyedSubtree(key: key, child: result),
              theme: coui.ThemeData.fromCore(
                dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final binding = bindProxyHostBoxSource(
            captureRoot: key.currentContext! as Element,
            registryResult: result,
            source: _source(recipe.unit),
          )!;
          final observed = binding.readDeclaredAbsence();
          expect(binding.registryResultElement.widget, same(result));
          expect(binding.paddingSource, same(binding.frameSource));
          expect(observed.owner, same(binding.frameSource));
          expect(observed.quantity, PaddingQuantityKind.declaredNoOwnPadding);
          expect(observed.paddingElement, isNull);
          expect(observed.value, EdgeInsets.zero);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('same mounted foreign padding changes without an own inset', (
    tester,
  ) async {
    final amount = ValueNotifier<double>(_kForeignCallerInset4);
    final foreign = GlobalKey();
    final capture = GlobalKey();
    final child = ValueListenableBuilder<double>(
      valueListenable: amount,
      builder: (context, value, child) => Padding(
        key: foreign,
        padding: EdgeInsets.all(value),
        child: const SizedBox(width: 20, height: 20),
      ),
    );
    final result = coui.Mask(child: child);
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: result)),
    );
    final bound = bindProxyHostBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: _source(_kMask),
    )!;
    final foreignElement = foreign.currentContext! as Element;
    expect(bound.readDeclaredAbsence().value, EdgeInsets.zero);
    amount.value = _kChangedForeignCallerInset12;
    await tester.pumpAndSettle();
    expect(foreign.currentContext, same(foreignElement));
    expect(
      (foreignElement.widget as Padding).padding,
      const EdgeInsets.all(_kChangedForeignCallerInset12),
    );
    expect(bound.readDeclaredAbsence().owner, same(bound.frameSource));
    expect(
      () => bound.scope.requireOwned(foreignElement),
      _changed(),
    );
    amount.dispose();
  });

  testWidgets('same-key producer update invalidates old witness only', (
    tester,
  ) async {
    final result = ValueNotifier<Widget>(
      const coui.Mask(child: SizedBox(width: 20, height: 20)),
    );
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<Widget>(
          valueListenable: result,
          builder: (context, widget, child) =>
              KeyedSubtree(key: capture, child: widget),
        ),
      ),
    );
    final old = bindProxyHostBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result.value,
      source: _source(_kMask),
    )!;
    result.value = const coui.Mask(
      shape: coui.CoreMaskShape.heart,
      child: SizedBox(width: 20, height: 20),
    );
    await tester.pumpAndSettle();
    expect(old.readDeclaredAbsence, _changed());
    final fresh = bindProxyHostBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result.value,
      source: _source(_kMask),
    )!;
    expect(fresh.frameSource, same(old.frameSource));
    expect(fresh.readDeclaredAbsence().owner, same(fresh.frameSource));
    result.dispose();
  });

  testWidgets('same registry Example cannot conceal new producer Widgets', (
    tester,
  ) async {
    final dark = ValueNotifier<bool>(false);
    final capture = GlobalKey();
    const result = MaskDefaultExample();
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<bool>(
          valueListenable: dark,
          builder: (context, value, child) => coui.Theme(
            data: coui.ThemeData.fromCore(
              value ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
            ),
            child: KeyedSubtree(key: capture, child: result),
          ),
        ),
      ),
    );
    ProxyHostBoxSourceBinding bind() => bindProxyHostBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: _source(_kMask),
    )!;
    final old = bind();
    dark.value = true;
    await tester.pumpAndSettle();
    expect(old.registryResultElement.widget, same(result));
    expect(old.readDeclaredAbsence, _changed());
    expect(bind().readDeclaredAbsence().value, EdgeInsets.zero);
    dark.dispose();
  });

  testWidgets('capture wrapper recreation preserves valid source identity', (
    tester,
  ) async {
    final tick = ValueNotifier<int>(0);
    final capture = GlobalKey();
    const result = coui.Mask(child: SizedBox(width: 20, height: 20));
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<int>(
          valueListenable: tick,
          builder: (context, value, child) =>
              KeyedSubtree(key: capture, child: result),
        ),
      ),
    );
    final root = capture.currentContext! as Element;
    final wrapper = root.widget;
    final bound = bindProxyHostBoxSource(
      captureRoot: root,
      registryResult: result,
      source: _source(_kMask),
    )!;
    tick.value++;
    await tester.pumpAndSettle();
    expect(root.widget, isNot(same(wrapper)));
    expect(bound.readDeclaredAbsence().value, EdgeInsets.zero);
    tick.dispose();
  });

  testWidgets('actual hover rebuild keeps frame and never replays callbacks', (
    tester,
  ) async {
    var calls = 0;
    final capture = GlobalKey();
    final result = coui.Hover(
      effect: coui.CoreHoverEffect.scaleUp,
      onEnter: () => calls++,
      child: const SizedBox(width: 40, height: 40),
    );
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: result)),
    );
    await tester.pumpAndSettle();
    final bound = bindProxyHostBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: _source(_kHover),
    )!;
    final frameWidget = bound.frameSource.widget;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byKey(capture)));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(bound.frameSource.widget, isNot(same(frameWidget)));
    expect(bound.readDeclaredAbsence().owner, same(bound.frameSource));
    expect(bound.readDeclaredAbsence().value, EdgeInsets.zero);
    expect(calls, 1);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('indicator child/item duplicate cannot disappear in a Set', (
    tester,
  ) async {
    const repeated = SizedBox(width: 20, height: 20);
    const result = coui.Indicator(item: repeated, child: repeated);
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: result)),
    );
    expect(
      () => bindProxyHostBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source(_kIndicator),
      ),
      _changed(),
    );
  });

  for (final ring in [0.0, 6.0]) {
    testWidgets('indicator overlay ring $ring is not the host inset', (
      tester,
    ) async {
      final item = GlobalKey();
      final capture = GlobalKey();
      final result = coui.Indicator(
        item: Padding(
          key: item,
          padding: const EdgeInsets.all(_kForeignCallerInset4),
          child: const SizedBox(width: 10, height: 10),
        ),
        indicatorStyle: coui.CoreIndicatorStyle(ringWidth: ring, offset: 3),
        child: const SizedBox(width: 40, height: 40),
      );
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: result)),
      );
      final binding = bindProxyHostBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source(_kIndicator),
      )!;
      expect(binding.readDeclaredAbsence().owner, same(binding.frameSource));
      expect(
        () => binding.scope.requireOwned(item.currentContext! as Element),
        _changed(),
      );
      if (ring != 0) {
        final position =
            (binding.frameSource.widget as Stack).children[1] as coui.Position;
        final positionElement = requireOneBoxOwner(
          boxElements(binding.frameSource).where(
            (element) => identical(element.widget, position),
          ),
          'the actual source overlay Position',
        );
        final decoration = elementOfDeclaredChild(
          positionElement,
          position.child!,
        );
        final padding = elementOfDeclaredChild(
          decoration,
          (decoration.widget as DecoratedBox).child!,
        );
        expect(padding.widget.runtimeType, Padding);
        expect(binding.paddingSource, isNot(same(padding)));
      }
    });
  }

  for (final (index, input) in <({Widget widget, String unit})>[
    (
      widget: const coui.Mask(
        shape: coui.CoreMaskShape.square,
        child: Padding(padding: EdgeInsets.all(_kForeignCallerInset4)),
      ),
      unit: _kMask,
    ),
    (
      widget: const coui.Mask(
        half: coui.CoreMaskHalf.first,
        child: SizedBox(width: 20, height: 20),
      ),
      unit: _kMask,
    ),
    (widget: const coui.Hover(), unit: _kHover),
    (
      widget: const coui.Hover(
        effect: coui.CoreHoverEffect.shadow,
        child: SizedBox(width: 20, height: 20),
      ),
      unit: _kHover,
    ),
    (widget: const _UnknownMask(), unit: _kMask),
    (widget: const _UnknownMaskExample(), unit: _kMask),
    (widget: const _UnknownHover(), unit: _kHover),
    (widget: const _UnknownIndicator(), unit: _kIndicator),
  ].indexed) {
    testWidgets('unsupported $index ${input.widget.runtimeType}', (
      tester,
    ) async {
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: input.widget)),
      );
      await tester.pumpAndSettle();
      expect(
        () => bindProxyHostBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: input.widget,
          source: _source(input.unit),
        ),
        _changed(),
      );
    });
  }

  testWidgets('unknown tuple/unmounted result reject, unknown unit delegates', (
    tester,
  ) async {
    final result = coui.Mask(
      key: UniqueKey(),
      child: const SizedBox(width: 20, height: 20),
    );
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: result)),
    );
    final root = capture.currentContext! as Element;
    for (final source in [
      const BoxObservationSourceSpec(
        schemaVersion: 99,
        logicalUnitId: _kMask,
        quantityId: BoxObservationSourceSpec.quantity,
        nativeAdapterId: 'mask-generated-clip-host-v1',
        webAdapterId: 'mask-generated-clip-host-v1',
      ),
      const BoxObservationSourceSpec(
        schemaVersion: 1,
        logicalUnitId: _kMask,
        quantityId: 'stale',
        nativeAdapterId: 'mask-generated-clip-host-v1',
        webAdapterId: 'mask-generated-clip-host-v1',
      ),
      const BoxObservationSourceSpec(
        schemaVersion: 1,
        logicalUnitId: _kMask,
        quantityId: BoxObservationSourceSpec.quantity,
        nativeAdapterId: 'mask-generated-clip-host-v1',
        webAdapterId: 'stale',
      ),
    ]) {
      expect(
        () => bindProxyHostBoxSource(
          captureRoot: root,
          registryResult: result,
          source: source,
        ),
        _changed(),
      );
    }
    expect(
      () => bindProxyHostBoxSource(
        captureRoot: root,
        registryResult: coui.Mask(child: result),
        source: _source(_kMask),
      ),
      _changed(),
    );
    final bound = bindProxyHostBoxSource(
      captureRoot: root,
      registryResult: result,
      source: _source(_kMask),
    )!;
    expect(
      bindProxyHostBoxSource(
        captureRoot: root,
        registryResult: result,
        source: _source('unknown'),
      ),
      isNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(bound.readDeclaredAbsence, _changed());
  });
}

class _UnknownMask extends coui.Mask {
  const _UnknownMask() : super(child: const SizedBox(width: 20, height: 20));
}

class _UnknownMaskExample extends MaskDefaultExample {
  const _UnknownMaskExample();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(_kForeignCallerInset4),
    child: SizedBox(width: 20, height: 20),
  );
}

class _UnknownHover extends coui.Hover {
  const _UnknownHover() : super(child: const SizedBox(width: 20, height: 20));
}

class _UnknownIndicator extends coui.Indicator {
  const _UnknownIndicator()
    : super(
        item: const SizedBox(width: 10, height: 10),
        child: const SizedBox(width: 20, height: 20),
      );
}
