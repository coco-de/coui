import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show
        Center,
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
import 'box_padding_paired.dart';
import 'box_padding_validation_viewport_units.dart';
import 'parity_matrix_entry.dart';

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
  _ => throw ArgumentError(component),
};
Future<void> _mount(
  WidgetTester tester,
  GlobalKey capture,
  Widget result, {
  bool dark = false,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      SizedBox(
        width: 480,
        height: 400,
        child: Center(
          child: KeyedSubtree(key: capture, child: result),
        ),
      ),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  // Marquee and FadeScroll own live operations; do not wait for all tickers.
  await tester.pump(const Duration(milliseconds: 32));
  await tester.pump(const Duration(milliseconds: 32));
}

Map<String, Object?> _observe(
  Element capture,
  Widget result,
  Map<String, Object?> source, {
  bool omitted = false,
  String key = 'any-capture-key',
}) {
  final payload = observePairedNativePadding(
    key: key,
    probes: [
      ParityProbeSpec(
        role: 'root',
        flutterFinder: 'unused-sanity-finder',
        fields: const {'paddingPx'},
        boxObservationSource: source,
      ),
    ],
    captureRoot: capture,
    registryResult: result,
    legacyRootOmitted: omitted,
  );
  expect(payload['mode'], 'additive-only');
  expect(payload['legacyRootOmitted'], omitted);
  expect(payload['canonicalComparisonEligible'], false);
  return ((payload['byRole']! as Map)['root']! as Map).cast<String, Object?>();
}

void _expectCurrent(
  Map<String, Object?> actual,
  ValidationViewportBoxSourceBinding binding,
  BoxObservationSourceSpec source, {
  required bool omitted,
}) {
  expect(actual['status'], 'source-complete', reason: '$actual');
  expect(actual['source'], source.toJson());
  expect(actual['sourceUnitValidated'], true);
  expect(actual['sourceReaderId'], binding.readerId);
  expect(
    actual['sourceReaderId'],
    source == BoxObservationSourceSpec.textFieldContentInset
        ? 'current-render-padding-v1'
        : 'validation-viewport-declared-absence-v1',
  );
  expect(actual['sourceBindingAuthority'], binding.authority);
  expect(
    actual['layoutRootElement'],
    identityHashCode(binding.registryResultElement),
  );
  expect(
    actual['declaringProducerElement'],
    identityHashCode(binding.scope.producer),
  );
  expect(
    actual['fieldUnitElement'],
    identityHashCode(binding.fieldUnitElement),
  );
  expect(
    actual['declaredPaddingSourceElement'],
    identityHashCode(binding.paddingSource),
  );
  expect(actual['ownerElement'], identityHashCode(binding.paddingSource));
  expect(
    actual['declaredFrameSourceElement'],
    identityHashCode(binding.frameSource),
  );
  expect(
    actual['frameSourceOwnerElement'],
    identityHashCode(binding.frameSource),
  );
  expect(actual['frameSourceStatus'], 'bound-configured-frame');
  expect(actual['legacyRoleEligible'], !omitted);
  expect(actual['canonicalComparisonEligible'], false);
  expect(actual['paintRequired'], false);
  expect(actual['paintPresenceInferred'], false);
  if (source == BoxObservationSourceSpec.textFieldContentInset) {
    expect(actual['quantityKind'], 'frameworkOwnParameter');
    expect(
      actual['actualPaddingElement'],
      actual['declaredPaddingSourceElement'],
    );
    expect(
      actual['declaredFrameSourceElement'],
      isNot(actual['actualPaddingElement']),
    );
  } else {
    expect(actual['quantityKind'], 'declaredNoOwnPadding');
    expect(actual['actualPaddingElement'], null);
    expect(actual['declaredAbsenceKind'], source.logicalUnitId);
    expect(actual['value'], [0, 0, 0, 0]);
  }
}

class _UnknownHint extends coui.ValidatorHint {
  const _UnknownHint() : super(message: const SizedBox());
}

class _UnknownHover extends coui.Hover {
  const _UnknownHover()
    : super(
        effect: coui.CoreHoverEffect.shadow,
        child: const SizedBox(width: 40, height: 20),
      );
}

void main() {
  for (final recipe in _recipes) {
    for (final dark in [false, true]) {
      testWidgets('${recipe.component}/${recipe.variant}/$dark shared unit', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry[recipe.component]!(
          recipe.variant == 'default' ? null : recipe.variant,
        );
        final capture = GlobalKey();
        await _mount(tester, capture, result, dark: dark);
        final root = capture.currentContext! as Element;
        final source = _source(recipe.component);
        final binding = bindValidationViewportBoxSource(
          captureRoot: root,
          registryResult: result,
          source: source,
        )!;
        for (final omitted in [false, true]) {
          _expectCurrent(
            _observe(root, result, source.toJson(), omitted: omitted),
            binding,
            source,
            omitted: omitted,
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('shared TextField reads arbitrary own inset, not foreign boxes', (
    tester,
  ) async {
    const foreign = Padding(
      padding: EdgeInsets.all(71),
      child: SizedBox(width: 8, height: 8),
    );
    final result = coui.TextField(
      placeholder: const coui.Text('placeholder'),
      prefix: foreign,
      textFieldStyle: const coui.CoreTextFieldStyle(
        padding: coui.CoreEdgeInsets.fromLTRB(3, 5, 7, 11),
      ),
    );
    final capture = GlobalKey();
    await _mount(tester, capture, result);
    final root = capture.currentContext! as Element;
    const source = BoxObservationSourceSpec.textFieldContentInset;
    final first = _observe(root, result, source.toJson(), omitted: true);
    expect(first['status'], 'source-complete');
    expect(first['value'], [5, 7, 11, 3]);
    expect(first['currentRenderPadding'], [5, 7, 11, 3]);
    expect(first['legacyRoleEligible'], false);
    expect(
      first['ownerElement'],
      isNot(identityHashCode(tester.element(find.byWidget(foreign)))),
    );
    expect(
      _observe(root, result, source.toJson(), omitted: true, key: 'unrelated'),
      first,
    );
  });

  testWidgets('shared shadow excludes every mounted copy of its one raw slot', (
    tester,
  ) async {
    const foreign = Padding(
      padding: EdgeInsets.all(89),
      child: SizedBox(width: 40, height: 20),
    );
    const result = coui.Hover(
      effect: coui.CoreHoverEffect.shadow,
      child: foreign,
    );
    final capture = GlobalKey();
    await _mount(tester, capture, result);
    final root = capture.currentContext! as Element;
    const source = BoxObservationSourceSpec.hoverEffectHost;
    final binding = bindValidationViewportBoxSource(
      captureRoot: root,
      registryResult: result,
      source: source,
    )!;
    final copies = tester.elementList(find.byWidget(foreign)).toList();
    expect(copies.length, greaterThan(1));
    expect(binding.scope.foreignBoundaries, unorderedEquals(copies));
    final actual = _observe(root, result, source.toJson(), omitted: true);
    _expectCurrent(actual, binding, source, omitted: true);
    for (final copy in copies) {
      expect(
        () => binding.scope.requireOwned(copy),
        throwsA(isA<BoxObservationError>()),
      );
      expect(actual['ownerElement'], isNot(identityHashCode(copy)));
    }
  });

  for (final variant in ['default', 'fade']) {
    testWidgets('old Hover $variant retains its existing proxy reader', (
      tester,
    ) async {
      final example = kFlutterPreviewRegistry['hover']!(
        variant == 'default' ? null : variant,
      );
      for (final result in [
        example,
        coui.Hover(
          effect: variant == 'default'
              ? coui.CoreHoverEffect.scaleUp
              : coui.CoreHoverEffect.fade,
          child: const SizedBox(width: 40, height: 20),
        ),
      ]) {
        final capture = GlobalKey();
        await _mount(tester, capture, result);
        final root = capture.currentContext! as Element;
        const source = BoxObservationSourceSpec.hoverEffectHost;
        expect(
          bindValidationViewportBoxSource(
            captureRoot: root,
            registryResult: result,
            source: source,
          ),
          null,
        );
        final actual = _observe(root, result, source.toJson(), omitted: true);
        expect(actual['status'], 'source-complete', reason: '$actual');
        expect(actual['sourceReaderId'], 'proxy-host-declared-absence-v1');
        expect(actual['legacyRoleEligible'], false);
        expect(actual['canonicalComparisonEligible'], false);
      }
    });
  }

  testWidgets('unsupported Hover branches cannot fall back to the old proxy', (
    tester,
  ) async {
    const source = BoxObservationSourceSpec.hoverEffectHost;
    for (final result in [
      const coui.Hover(effect: coui.CoreHoverEffect.shadow),
      const _UnknownHover(),
      for (final effect in [
        coui.CoreHoverEffect.none,
        coui.CoreHoverEffect.scaleDown,
        coui.CoreHoverEffect.brighten,
      ])
        coui.Hover(
          effect: effect,
          child: const SizedBox(width: 40, height: 20),
        ),
    ]) {
      final capture = GlobalKey();
      await _mount(tester, capture, result);
      final root = capture.currentContext! as Element;
      expect(
        () => bindValidationViewportBoxSource(
          captureRoot: root,
          registryResult: result,
          source: source,
        ),
        throwsA(isA<BoxObservationError>()),
      );
      final actual = _observe(root, result, source.toJson());
      expect(actual['status'], 'incomplete');
      expect(actual['error'], 'VALIDATION_VIEWPORT_SOURCE_CHANGED');
    }
  });

  testWidgets('unknown tuples, foreign roots and raw duplicates fail closed', (
    tester,
  ) async {
    final capture = GlobalKey();
    const result = coui.ValidatorHint(message: coui.Text('actual'));
    await _mount(tester, capture, result);
    final source = BoxObservationSourceSpec.validatorHintMessageLayoutHost
        .toJson();
    for (final field in ['logicalUnitId', 'nativeAdapterId', 'webAdapterId']) {
      final actual = _observe(
        capture.currentContext! as Element,
        result,
        {...source, field: 'unregistered'},
      );
      expect(actual['status'], 'incomplete');
      expect(actual['error'], 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
    }
    for (final input in [
      const _UnknownHint(),
      const Padding(padding: EdgeInsets.all(17), child: result),
    ]) {
      await _mount(tester, capture, input);
      expect(
        _observe(capture.currentContext! as Element, input, source)['status'],
        'incomplete',
      );
    }
    const slot = SizedBox(width: 20, height: 20);
    const duplicate = coui.Validated(message: slot, child: slot);
    await _mount(tester, capture, duplicate);
    final actual = _observe(
      capture.currentContext! as Element,
      duplicate,
      BoxObservationSourceSpec.validatedLayoutHost.toJson(),
    );
    expect(actual['status'], 'incomplete');
    expect(actual['error'], 'VALIDATION_VIEWPORT_SOURCE_CHANGED');
  });

  testWidgets('shared dispatch rejects stale registry on a current Element', (
    tester,
  ) async {
    final capture = GlobalKey();
    const first = coui.ValidatorHint(message: coui.Text('first'));
    final current = ValueNotifier<Widget>(first);
    addTearDown(current.dispose);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<Widget>(
          valueListenable: current,
          builder: (_, value, _) => KeyedSubtree(key: capture, child: value),
        ),
      ),
    );
    await tester.pump();
    final root = capture.currentContext! as Element;
    final source = BoxObservationSourceSpec.validatorHintMessageLayoutHost
        .toJson();
    expect(_observe(root, first, source)['status'], 'source-complete');
    const next = coui.ValidatorHint(message: coui.Text('next'));
    current.value = next;
    await tester.pump();
    expect(capture.currentContext, same(root));
    final stale = _observe(root, first, source);
    expect(stale['status'], 'incomplete');
    expect(stale['error'], 'MISMATCHED_CONSTRUCTION_RESULT');
    expect(
      _observe(root, next, source, omitted: true)['legacyRoleEligible'],
      false,
    );
  });

  testWidgets('unrequested stage fields and legacy omission remain unchanged', (
    tester,
  ) async {
    final capture = GlobalKey();
    const result = coui.ValidatorHint(message: coui.Text('actual'));
    await _mount(tester, capture, result);
    final probe = ParityProbeSpec(
      role: 'stage',
      flutterFinder: 'unused',
      fields: const {'widthPx', 'heightPx'},
      boxObservationSource: BoxObservationSourceSpec
          .validatorHintMessageLayoutHost
          .toJson(),
    );
    final payload = observePairedNativePadding(
      key: 'stage-unit',
      probes: [probe],
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      legacyRootOmitted: true,
    );
    expect(payload['mode'], 'additive-only');
    expect(payload['legacyRootOmitted'], true);
    expect(payload['canonicalComparisonEligible'], false);
    expect((payload['byRole']! as Map)['stage'], {'status': 'not-requested'});
    expect(probe.fields, {'widthPx', 'heightPx'});
  });
}
