import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/text/text_modifiers_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_paired.dart';
import 'box_padding_text_showcase_units.dart';
import 'parity_matrix_entry.dart';

const _variants = <String>[
  'typography-display',
  'typography-headline',
  'typography-title',
  'typography-body',
  'typography-weight',
  'typography-primitive',
  'colors-brand',
  'colors-status',
  'colors-surface',
  'modifiers',
  'wrap',
  'keep-all',
  'textstyle',
  'opacity',
  'rich',
];

Future<void> _mount(
  WidgetTester tester,
  Widget result,
  GlobalKey capture, {
  bool dark = false,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      Directionality(
        textDirection: direction,
        child: SizedBox(
          width: 800,
          height: 600,
          child: SingleChildScrollView(
            child: KeyedSubtree(key: capture, child: result),
          ),
        ),
      ),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  await tester.pump();
}

TextShowcaseBoxSourceBinding _bind(GlobalKey capture, Widget result) =>
    bindTextShowcaseBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: kTextShowcaseOuterPaddingSource,
    )!;

Map<String, Object?> _sharedRoot(
  GlobalKey capture,
  Widget result, {
  required Map<String, Object?>? source,
  bool omitted = false,
  Set<String> fields = const {'paddingPx'},
}) {
  final payload = observePairedNativePadding(
    key: 'source-only-dispatch',
    probes: [
      ParityProbeSpec(
        role: 'root',
        flutterFinder: 'source-only',
        fields: fields,
        boxObservationSource: source,
      ),
    ],
    captureRoot: capture.currentContext! as Element,
    registryResult: result,
    legacyRootOmitted: omitted,
  );
  expect(payload['canonicalComparisonEligible'], isFalse);
  expect(payload['legacyRootOmitted'], omitted);
  return ((payload['byRole']! as Map)['root']! as Map).cast<String, Object?>();
}

class _UnknownShowcase extends TextModifiersExample {
  const _UnknownShowcase(this.onBuild);

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return const Padding(
      padding: EdgeInsets.fromLTRB(3, 5, 7, 11),
      child: Text('looks like a showcase'),
    );
  }
}

void main() {
  for (final variant in _variants) {
    for (final dark in [false, true]) {
      testWidgets('Text $variant/$dark binds its actual outer allocation', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry['text']!(variant);
        final capture = GlobalKey();
        await _mount(tester, result, capture, dark: dark);
        final binding = _bind(capture, result)
          ..validateExistingCurrentBinding();
        final padding = binding.paddingSource;
        expect(padding.widget.runtimeType, Padding);
        expect(binding.fieldUnitElement, same(padding));
        expect(binding.frameSource, same(padding));
        expect(binding.scope.producer, same(binding.registryResultElement));
        final input = padding.widget as Padding;
        expect(binding.allOriginalSuppliedSlots, [same(input.child)]);
        expect(binding.scope.foreignBoundaries, hasLength(1));
        final foreign = binding.scope.foreignBoundaries.single;
        expect(foreign.widget, same(input.child));
        binding.scope.requireOwned(padding);
        expect(
          () => binding.scope.requireOwned(foreign),
          throwsA(isA<BoxObservationError>()),
        );

        final render = padding.renderObject! as RenderPadding;
        final actual = binding.readActualPadding();
        expect(actual.quantity, PaddingQuantityKind.frameworkOwnParameter);
        expect(actual.value, render.padding.resolve(render.textDirection));
        expect(actual.currentRenderPadding, actual.value);
        expect(actual.owner, same(padding));
        expect(actual.paddingElement, same(padding));
        expect(actual.frameOwner, same(padding));
        expect(actual.producer, same(binding.registryResultElement));
        expect(actual.contentBoundary, same(foreign));
        expect(actual.allocatedDecorationInsets, EdgeInsets.zero);
        expect(actual.excludedMargin, EdgeInsets.zero);
        expect(
          binding.readDeclaredAbsence,
          throwsA(isA<BoxObservationError>()),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('unknown tuple is not enabled by a matching logical ID', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['text']!('modifiers');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    expect(
      bindTextShowcaseBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: BoxObservationSourceSpec.outlined,
      ),
      isNull,
    );
    const source = kTextShowcaseOuterPaddingSource;
    final forged = BoxObservationSourceSpec(
      schemaVersion: source.schemaVersion,
      logicalUnitId: source.logicalUnitId,
      quantityId: source.quantityId,
      nativeAdapterId: 'unreviewed-adapter',
      webAdapterId: source.webAdapterId,
    );
    expect(
      () => bindTextShowcaseBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: forged,
      ),
      throwsA(isA<BoxObservationError>()),
    );
  });

  testWidgets('unknown subclass is rejected without replaying its build', (
    tester,
  ) async {
    var calls = 0;
    final result = _UnknownShowcase(() => calls++);
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final before = calls;
    expect(before, greaterThan(0));
    expect(() => _bind(capture, result), throwsA(isA<BoxObservationError>()));
    expect(calls, before);
  });

  testWidgets('an outer wrapper cannot lend an inner showcase owner', (
    tester,
  ) async {
    final inner = kFlutterPreviewRegistry['text']!('modifiers');
    final result = Padding(
      padding: const EdgeInsets.all(97),
      child: inner,
    );
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    expect(() => _bind(capture, result), throwsA(isA<BoxObservationError>()));
    expect(() => _bind(capture, inner), throwsA(isA<BoxObservationError>()));
  });

  testWidgets('a copied unmounted construction is not the registry result', (
    tester,
  ) async {
    final result = TextModifiersExample(key: UniqueKey());
    final copy = TextModifiersExample(key: UniqueKey());
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    expect(() => _bind(capture, copy), throwsA(isA<BoxObservationError>()));
  });

  testWidgets('mutating a retained scope cannot erase foreign ownership', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['text']!('modifiers');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result);
    binding.scope.foreignBoundaries.clear();
    expect(binding.readActualPadding, throwsA(isA<BoxObservationError>()));
    expect(
      binding.validateExistingCurrentBinding,
      throwsA(isA<BoxObservationError>()),
    );
  });

  testWidgets('foreign content padding never becomes the outer allocation', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['text']!('colors-surface');
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(capture, result);
    final before = binding.readActualPadding().value;
    final foreign = binding.scope.foreignBoundaries.single;
    final renderers = <RenderPadding>{};
    for (final element in boxElements(foreign)) {
      if (element is RenderObjectElement &&
          element.renderObject is RenderPadding) {
        renderers.add(element.renderObject as RenderPadding);
      }
    }
    expect(renderers, isNotEmpty);
    final original = {
      for (final render in renderers) render: render.padding,
    };
    try {
      // Adversarial public-renderer mutation stays entirely behind the
      // retained foreign boundary; no fixture build or observer is replayed.
      for (final render in renderers) {
        render.padding = const EdgeInsets.fromLTRB(41, 43, 47, 53);
      }
      await tester.pump();
      expect(binding.readActualPadding().value, before);
      expect(
        () => binding.scope.requireOwned(foreign),
        throwsA(isA<BoxObservationError>()),
      );
    } finally {
      original.forEach((render, padding) => render.padding = padding);
    }
  });

  testWidgets('reads asymmetric RTL renderer input and preserves zero kind', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['text']!('modifiers');
    final capture = GlobalKey();
    await _mount(tester, result, capture, direction: TextDirection.rtl);
    final binding = _bind(capture, result);
    final render = binding.paddingSource.renderObject! as RenderPadding;
    final original = render.padding;
    try {
      // Public renderer inputs, not Core/style expectations, distinguish
      // the actual read from copying the generated Widget's target inset.
      render.padding = const EdgeInsetsDirectional.fromSTEB(3, 5, 7, 11);
      await tester.pump();
      expect(
        binding.readActualPadding().value,
        const EdgeInsets.fromLTRB(7, 5, 3, 11),
      );
      render.padding = EdgeInsets.zero;
      await tester.pump();
      final zero = binding.readActualPadding();
      expect(zero.value, EdgeInsets.zero);
      expect(zero.quantity, PaddingQuantityKind.frameworkOwnParameter);
      expect(zero.paddingElement, same(binding.paddingSource));
      expect(
        binding.readDeclaredAbsence,
        throwsA(isA<BoxObservationError>()),
      );
    } finally {
      render.padding = original;
    }
  });

  testWidgets('a real inherited Theme rebuild makes the old raw child stale', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['text']!('modifiers');
    final capture = GlobalKey();
    final theme = ValueNotifier(
      coui.ThemeData.fromCore(coui.CoreThemePresets.light),
    );
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<coui.ThemeData>(
          valueListenable: theme,
          builder: (context, current, _) => coui.Theme(
            data: current,
            child: KeyedSubtree(key: capture, child: result),
          ),
        ),
      ),
    );
    await tester.pump();
    final held = _bind(capture, result);
    final oldChild = held.allOriginalSuppliedSlots.single;
    final registryElement = held.registryResultElement;
    theme.value = coui.ThemeData.fromCore(coui.CoreThemePresets.dark);
    await tester.pump();
    expect(
      held.validateExistingCurrentBinding,
      throwsA(isA<BoxObservationError>()),
    );
    final current = _bind(capture, result);
    expect(current.registryResultElement, same(registryElement));
    expect(current.allOriginalSuppliedSlots.single, isNot(same(oldChild)));
    final render = current.paddingSource.renderObject! as RenderPadding;
    expect(
      current.readActualPadding().value,
      render.padding.resolve(render.textDirection),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing a mounted result invalidates the held binding', (
    tester,
  ) async {
    final first = TextModifiersExample(key: UniqueKey());
    final selected = ValueNotifier<Widget>(first);
    addTearDown(selected.dispose);
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<Widget>(
          valueListenable: selected,
          builder: (context, result, _) =>
              KeyedSubtree(key: capture, child: result),
        ),
      ),
    );
    await tester.pump();
    final held = _bind(capture, first);
    final replacement = TextModifiersExample(key: UniqueKey());
    selected.value = replacement;
    await tester.pump();
    expect(held.readActualPadding, throwsA(isA<BoxObservationError>()));
    expect(_bind(capture, replacement).readActualPadding().owner, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(held.readActualPadding, throwsA(isA<BoxObservationError>()));
  });

  group('shared Text showcase dispatch', () {
    for (final variant in _variants) {
      for (final dark in [false, true]) {
        testWidgets('$variant/$dark retains the actual outer allocation', (
          tester,
        ) async {
          final result = kFlutterPreviewRegistry['text']!(variant);
          final capture = GlobalKey();
          await _mount(tester, result, capture, dark: dark);
          final bound = _bind(capture, result);
          final current = bound.readActualPadding().toJson();
          for (final omitted in [false, true]) {
            final observed = _sharedRoot(
              capture,
              result,
              source: kTextShowcaseOuterPaddingSource.toJson(),
              omitted: omitted,
            );
            expect(observed['status'], 'source-complete', reason: '$observed');
            expect(observed['sourceUnitValidated'], isTrue);
            expect(
              observed['source'],
              kTextShowcaseOuterPaddingSource.toJson(),
            );
            expect(observed['sourceReaderId'], bound.readerId);
            expect(observed['sourceBindingAuthority'], bound.authority);
            expect(observed['quantityKind'], 'frameworkOwnParameter');
            expect(observed['value'], current['value']);
            expect(
              observed['currentRenderPadding'],
              current['currentRenderPadding'],
            );
            expect(
              observed['fieldUnitElement'],
              identityHashCode(bound.fieldUnitElement),
            );
            expect(
              observed['declaredPaddingSourceElement'],
              identityHashCode(bound.paddingSource),
            );
            expect(
              observed['declaredFrameSourceElement'],
              identityHashCode(bound.frameSource),
            );
            expect(
              observed['frameSourceOwnerElement'],
              observed['declaredFrameSourceElement'],
            );
            expect(
              observed['contentBoundaryElement'],
              current['contentBoundaryElement'],
            );
            expect(observed['legacyRoleEligible'], !omitted);
            expect(observed['canonicalComparisonEligible'], isFalse);
            expect(observed['paintRequired'], isFalse);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('missing declaration stays incomplete', (tester) async {
      final result = kFlutterPreviewRegistry['text']!('modifiers');
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final observed = _sharedRoot(capture, result, source: null);
      expect(observed['status'], 'incomplete');
      expect(observed['error'], 'MISSING_PAIRED_BOX_SOURCE');
      expect(observed.containsKey('value'), isFalse);
    });

    testWidgets('malformed or forged declarations never borrow the binder', (
      tester,
    ) async {
      final result = kFlutterPreviewRegistry['text']!('modifiers');
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      for (final (field, value) in const <(String, Object?)>[
        ('schemaVersion', 2),
        ('quantityId', 'unreviewed-quantity'),
        ('logicalUnitId', 'unreviewed-unit'),
        ('nativeAdapterId', 'unreviewed-adapter'),
        ('webAdapterId', 'unreviewed-adapter'),
        ('webAdapterId', null),
        ('unreviewedExtraField', true),
      ]) {
        final declared = kTextShowcaseOuterPaddingSource.toJson()
          ..[field] = value;
        final observed = _sharedRoot(capture, result, source: declared);
        expect(observed['status'], 'incomplete', reason: '$observed');
        expect(observed.containsKey('value'), isFalse);
        expect(observed.containsKey('sourceUnitValidated'), isFalse);
      }
    });

    testWidgets('unknown subclass is incomplete without another build', (
      tester,
    ) async {
      var builds = 0;
      final result = _UnknownShowcase(() => builds++);
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final before = builds;
      final observed = _sharedRoot(
        capture,
        result,
        source: kTextShowcaseOuterPaddingSource.toJson(),
      );
      expect(observed['status'], 'incomplete');
      expect(observed.containsKey('value'), isFalse);
      expect(builds, before);
    });

    testWidgets('copied registry input is incomplete', (tester) async {
      final result = TextModifiersExample(key: UniqueKey());
      final copied = TextModifiersExample(key: UniqueKey());
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final observed = _sharedRoot(
        capture,
        copied,
        source: kTextShowcaseOuterPaddingSource.toJson(),
      );
      expect(observed['status'], 'incomplete');
      expect(observed.containsKey('value'), isFalse);
    });

    testWidgets('outer wrapper cannot supply another showcase owner', (
      tester,
    ) async {
      final inner = kFlutterPreviewRegistry['text']!('modifiers');
      final result = Padding(padding: const EdgeInsets.all(97), child: inner);
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final observed = _sharedRoot(
        capture,
        result,
        source: kTextShowcaseOuterPaddingSource.toJson(),
      );
      expect(observed['status'], 'incomplete');
      expect(observed.containsKey('value'), isFalse);
    });

    testWidgets('existing outlined route stays separate', (tester) async {
      final result = kFlutterPreviewRegistry['outlined-container']!(null);
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final observed = _sharedRoot(
        capture,
        result,
        source: BoxObservationSourceSpec.outlined.toJson(),
      );
      expect(observed['status'], 'source-complete', reason: '$observed');
      expect(observed['source'], BoxObservationSourceSpec.outlined.toJson());
      expect(observed['sourceReaderId'], isNull);
    });

    testWidgets('nonpadding role stays not requested', (tester) async {
      final result = kFlutterPreviewRegistry['text']!('modifiers');
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final observed = _sharedRoot(
        capture,
        result,
        source: null,
        fields: const {'widthPx', 'heightPx'},
      );
      expect(observed, {'status': 'not-requested'});
    });
  });
}
