import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/skeleton/skeleton_circle_example.dart';
import 'package:docs_core/previews/examples/flutter/status/status_default_example.dart';
import 'package:docs_core/previews/examples/flutter/tag/tag_default_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show
        Builder,
        Container,
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        SizedBox,
        UniqueKey,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_display_parameter_units.dart';
import 'box_padding_observation.dart';

const BoxObservationSourceSpec _kStatus =
    BoxObservationSourceSpec.statusDotContentInset;
const BoxObservationSourceSpec _kTag =
    BoxObservationSourceSpec.tagLabelContentInset;
const BoxObservationSourceSpec _kSkeleton =
    BoxObservationSourceSpec.skeletonCircularContentInset;
const _kRecipes =
    <({String component, String variant, BoxObservationSourceSpec source})>[
      (component: 'status', variant: 'default', source: _kStatus),
      (component: 'status', variant: 'success', source: _kStatus),
      (component: 'status', variant: 'warning', source: _kStatus),
      (component: 'status', variant: 'error', source: _kStatus),
      (component: 'tag', variant: 'default', source: _kTag),
      (component: 'skeleton', variant: 'circle', source: _kSkeleton),
    ];

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having((error) => error.code, 'code', code),
);

BoxPaddingObservation _read(DisplayParameterBoxSourceBinding binding) {
  binding.validateCurrentConstruction();
  return observeCurrentContainerPadding(
    owner: binding.paddingSource,
    scope: binding.scope,
  );
}

class _UnknownStatus extends coui.Status {
  const _UnknownStatus();
}

class _UnknownTag extends coui.Tag {
  const _UnknownTag() : super(child: const coui.Text('foreign'));
}

class _UnknownSkeleton extends coui.Skeleton {
  const _UnknownSkeleton() : super.circle(size: 48);
}

void main() {
  for (final recipe in _kRecipes) {
    for (final dark in [false, true]) {
      testWidgets('${recipe.component}/${recipe.variant} dark=$dark source', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry[recipe.component]!(
          recipe.variant == 'default' ? null : recipe.variant,
        );
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
        final binding = bindDisplayParameterBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: recipe.source,
        )!;
        expect(binding.registryResultElement.widget, same(result));
        expect(binding.scope.producer, same(binding.registryResultElement));
        expect(binding.paddingSource.widget.runtimeType, Container);
        expect(binding.fieldUnitElement, same(binding.paddingSource));
        expect(binding.frameSource, same(binding.paddingSource));
        expect(binding.readerId, 'current-container-v1');
        final observation = _read(binding);
        expect(observation.owner, same(binding.paddingSource));
        expect(observation.quantity, PaddingQuantityKind.frameworkOwnParameter);
        // Actual framework slot/allocation evidence, never a guessed zero.
        expect(observation.generatedSlots, isNotEmpty);
        for (final boundary in binding.scope.foreignBoundaries) {
          expect(
            () => binding.scope.requireOwned(boundary),
            _error('FOREIGN_SUPPLIED_CONTENT'),
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('same Tag input follows current owned theme padding', (
    tester,
  ) async {
    final amount = ValueNotifier<double>(coui.CoreSpace.space4);
    addTearDown(amount.dispose);
    final key = GlobalKey();
    const result = TagDefaultExample();
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<double>(
          valueListenable: amount,
          child: KeyedSubtree(key: key, child: result),
          builder: (_, value, child) => coui.Theme(
            data: coui.ThemeData.fromCore(coui.CoreThemePresets.light).copyWith(
              coreComponentTheme: () => coui.CoreComponentTheme(
                tag: coui.CoreTagTheme(
                  style: coui.CoreTagStyle(
                    padding: coui.CoreEdgeInsets.all(value),
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
    final binding = bindDisplayParameterBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: _kTag,
    )!;
    final before = _read(binding);
    final originalFrameWidget = binding.frameSource.widget;
    amount.value = coui.CoreSpace.space12;
    await tester.pump();
    final after = _read(binding);
    expect(binding.frameSource.widget, isNot(same(originalFrameWidget)));
    expect(after.value, isNot(before.value));
    expect(after.value, EdgeInsets.all(amount.value));
    expect(tester.takeException(), isNull);
  });

  testWidgets('foreign Tag child mutation never supplies own inset', (
    tester,
  ) async {
    final amount = ValueNotifier<double>(4);
    addTearDown(amount.dispose);
    var calls = 0;
    final foreignKey = GlobalKey();
    final supplied = ValueListenableBuilder<double>(
      valueListenable: amount,
      builder: (_, value, _) => Padding(
        key: foreignKey,
        padding: EdgeInsets.all(value),
        child: Builder(
          builder: (_) {
            calls++;
            return const coui.Text('opaque supplied child');
          },
        ),
      ),
    );
    final result = coui.Tag(child: supplied);
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pump();
    final binding = bindDisplayParameterBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: _kTag,
    )!;
    final before = _read(binding).value;
    final callsBeforeRead = calls;
    _read(binding);
    expect(calls, callsBeforeRead);
    expect(
      () => binding.scope.requireOwned(foreignKey.currentContext! as Element),
      _error('FOREIGN_SUPPLIED_CONTENT'),
    );
    amount.value = 12;
    await tester.pump();
    expect(_read(binding).value, before);
    expect(
      (foreignKey.currentWidget! as Padding).padding,
      EdgeInsets.all(amount.value),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skeleton animation replaces frame Widget without stale input', (
    tester,
  ) async {
    const result = SkeletonCircleExample();
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pump();
    final binding = bindDisplayParameterBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: _kSkeleton,
    )!;
    final before = _read(binding).value;
    final widget = binding.frameSource.widget;
    await tester.pump(const Duration(milliseconds: 120));
    expect(binding.frameSource.widget, isNot(same(widget)));
    expect(_read(binding).value, before);
    expect(tester.takeException(), isNull);
  });

  for (final source in [_kStatus, _kTag, _kSkeleton]) {
    for (final example in [true, false]) {
      testWidgets('same-mounted ${source.logicalUnitId} example=$example', (
        tester,
      ) async {
        final inputKey = UniqueKey();
        Widget input() => switch (source.logicalUnitId) {
          'status-generated-dot-content-inset' =>
            example
                ? StatusDefaultExample(key: inputKey)
                : coui.Status(key: inputKey),
          'tag-generated-label-content-inset' =>
            example
                ? TagDefaultExample(key: inputKey)
                : coui.Tag(key: inputKey, child: const coui.Text('value')),
          _ =>
            example
                ? SkeletonCircleExample(key: inputKey)
                : coui.Skeleton.circle(key: inputKey, size: 48),
        };
        final current = ValueNotifier<Widget>(input());
        addTearDown(current.dispose);
        final key = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(
            ValueListenableBuilder<Widget>(
              valueListenable: current,
              builder: (_, value, _) => KeyedSubtree(key: key, child: value),
            ),
            disableAnimations: true,
          ),
        );
        await tester.pump();
        DisplayParameterBoxSourceBinding bind() =>
            bindDisplayParameterBoxSource(
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
        expect(
          old.validateCurrentConstruction,
          _error('STALE_DISPLAY_PARAMETER_CONSTRUCTION'),
        );
        expect(() => _read(bind()), returnsNormally);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('unknown wrappers subclasses and unregistered branches reject', (
    tester,
  ) async {
    const cases = <(Widget, BoxObservationSourceSpec)>[
      (_UnknownStatus(), _kStatus),
      (_UnknownTag(), _kTag),
      (_UnknownSkeleton(), _kSkeleton),
      (coui.Status(label: coui.Text('visible')), _kStatus),
      (coui.Status(animated: true), _kStatus),
      (coui.Skeleton.text(), _kSkeleton),
      (coui.Skeleton(), _kSkeleton),
      (Padding(padding: EdgeInsets.zero, child: coui.Status()), _kStatus),
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
        () => bindDisplayParameterBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: source,
        ),
        throwsA(isA<BoxObservationError>()),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('schema tuple actual result and unmount fail closed', (
    tester,
  ) async {
    const result = StatusDefaultExample();
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pump();
    for (final change in [
      {'schemaVersion': 99},
      {'quantityId': 'unknown'},
      {'nativeAdapterId': 'unknown'},
      {'webAdapterId': 'unknown'},
    ]) {
      expect(
        () => bindDisplayParameterBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: BoxObservationSourceSpec.fromJson({
            ..._kStatus.toJson(),
            ...change,
          }),
        ),
        throwsA(isA<BoxObservationError>()),
      );
    }
    expect(
      () => bindDisplayParameterBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: StatusDefaultExample(key: UniqueKey()),
        source: _kStatus,
      ),
      _error('MISMATCHED_DISPLAY_PARAMETER_RESULT'),
    );
    final unknown = BoxObservationSourceSpec.fromJson({
      ..._kStatus.toJson(),
      'logicalUnitId': 'unknown',
    });
    expect(
      bindDisplayParameterBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: unknown,
      ),
      isNull,
    );
    final binding = bindDisplayParameterBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: _kStatus,
    )!;
    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      binding.validateCurrentConstruction,
      _error('STALE_DISPLAY_PARAMETER_CONSTRUCTION'),
    );
  });
}
