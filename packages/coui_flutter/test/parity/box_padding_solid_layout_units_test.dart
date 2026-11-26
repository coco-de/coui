import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/app_bar/app_bar_default_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart'
    show
        BuildContext,
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        UniqueKey,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_solid_layout_units.dart';
import 'box_padding_source_bindings.dart';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: unit,
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$unit-v1',
  webAdapterId: '$unit-v1',
);

const _bar = 'app-bar-solid-content-inset';
const _empty = 'empty-state-generated-content-inset';

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having((error) => error.code, 'code', code),
);

void main() {
  const recipes = <({String component, String variant})>[
    (component: 'app-bar', variant: 'default'),
    (component: 'app-bar', variant: 'compact'),
    (component: 'app-bar', variant: 'dense'),
    (component: 'app-bar', variant: 'prominent'),
    (component: 'app-bar', variant: 'centered'),
    (component: 'app-bar', variant: 'text'),
    (component: 'empty-state', variant: 'default'),
    (component: 'empty-state', variant: 'large'),
    (component: 'empty-state', variant: 'failure'),
    (component: 'empty-state', variant: 'success'),
  ];
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark content source',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
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
          final binding = bindSolidLayoutBoxSource(
            captureRoot: capture.currentContext! as Element,
            registryResult: result,
            source: _source(recipe.component == 'app-bar' ? _bar : _empty),
          )!;
          expect(binding.registryResultElement.widget, same(result));
          expect(binding.fieldUnitElement, isNot(same(binding.paddingSource)));
          expect(binding.paddingSource.widget.runtimeType, Padding);
          expect(binding.readerId, 'current-render-padding-v1');
          final raw = binding.paddingSource.renderObject! as RenderPadding;
          final observed = observeSourceOwnedRenderPadding(
            owner: binding.paddingSource,
            scope: binding.scope,
          );
          expect(observed.owner, same(binding.paddingSource));
          expect(observed.quantity, PaddingQuantityKind.frameworkOwnParameter);
          expect(observed.value, raw.padding.resolve(raw.textDirection));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('same-mounted foreign padding cannot donate its inset', (
    tester,
  ) async {
    final value = ValueNotifier<double>(4);
    final foreign = GlobalKey();
    final capture = GlobalKey();
    late Widget result;
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<double>(
          valueListenable: value,
          builder: (context, amount, child) {
            result = coui.AppBar(
              title: Padding(
                key: foreign,
                padding: EdgeInsets.all(amount),
                child: const coui.Text('foreign title'),
              ),
              appBarStyle: const coui.CoreAppBarStyle(
                height: 120,
                padding: coui.CoreEdgeInsets.all(coui.CoreSpace.space12),
              ),
            );
            return KeyedSubtree(key: capture, child: result);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    SolidLayoutBoxSourceBinding bind() => bindSolidLayoutBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: _source(_bar),
    )!;
    final before = bind();
    final foreignElement = foreign.currentContext! as Element;
    final own = observeSourceOwnedRenderPadding(
      owner: before.paddingSource,
      scope: before.scope,
    ).value;
    value.value = 12;
    await tester.pumpAndSettle();
    final after = bind();
    expect(foreign.currentContext, same(foreignElement));
    expect(
      (foreignElement.widget as Padding).padding,
      const EdgeInsets.all(12),
    );
    expect(after.paddingSource, same(before.paddingSource));
    expect(
      observeSourceOwnedRenderPadding(
        owner: after.paddingSource,
        scope: after.scope,
      ).value,
      own,
    );
    expect(
      () => after.scope.requireOwned(foreignElement),
      _error('FOREIGN_SUPPLIED_CONTENT'),
    );
    value.dispose();
  });

  testWidgets('same source parameter updates while divider toggles', (
    tester,
  ) async {
    final value = ValueNotifier<double>(8);
    final capture = GlobalKey();
    late Widget result;
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<double>(
          valueListenable: value,
          builder: (context, amount, child) {
            result = coui.AppBar(
              showDivider: amount == 8,
              title: const coui.Text('owned'),
              appBarStyle: coui.CoreAppBarStyle(
                padding: coui.CoreEdgeInsets.all(amount),
              ),
            );
            return KeyedSubtree(key: capture, child: result);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    SolidLayoutBoxSourceBinding bind() => bindSolidLayoutBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: _source(_bar),
    )!;
    final before = bind();
    expect(
      observeSourceOwnedRenderPadding(
        owner: before.paddingSource,
        scope: before.scope,
      ).value,
      const EdgeInsets.all(8),
    );
    value.value = 16;
    await tester.pumpAndSettle();
    final after = bind();
    expect(after.paddingSource, same(before.paddingSource));
    expect(after.frameSource, same(before.frameSource));
    expect(
      observeSourceOwnedRenderPadding(
        owner: after.paddingSource,
        scope: after.scope,
      ).value,
      const EdgeInsets.all(16),
    );
    value.dispose();
  });

  testWidgets('EmptyState supplied icon/action chrome remains foreign', (
    tester,
  ) async {
    final icon = GlobalKey();
    final action = GlobalKey();
    final capture = GlobalKey();
    final result = coui.EmptyState(
      title: const coui.Text('title'),
      icon: Padding(
        key: icon,
        padding: const EdgeInsets.all(4),
        child: const coui.Text('icon'),
      ),
      action: Padding(
        key: action,
        padding: const EdgeInsets.all(4),
        child: const coui.Text('action'),
      ),
    );
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: result)),
    );
    await tester.pumpAndSettle();
    final binding = bindSolidLayoutBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: _source(_empty),
    )!;
    for (final foreign in [icon, action]) {
      expect(
        () => binding.scope.requireOwned(foreign.currentContext! as Element),
        _error('FOREIGN_SUPPLIED_CONTENT'),
      );
    }
  });

  for (final result in <Widget>[
    const coui.AppBar(variant: coui.CoreAppBarVariant.medium),
    const _UnknownAppBar(),
    const _UnknownExample(),
    const _UnknownEmptyState(),
  ]) {
    testWidgets('unaudited branch/subclass ${result.runtimeType} rejects', (
      tester,
    ) async {
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: capture, child: result)),
      );
      await tester.pumpAndSettle();
      expect(
        () => bindSolidLayoutBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: result,
          source: _source(result is coui.EmptyState ? _empty : _bar),
        ),
        throwsA(isA<BoxObservationError>()),
      );
    });
  }

  testWidgets('glass branch cannot borrow an action or title Padding', (
    tester,
  ) async {
    const result = coui.AppBar(title: coui.Text('glass'));
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(
        KeyedSubtree(key: capture, child: result),
        surfaceStyle: coui.CoreSurfaceStyleId.liquidGlass,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      () => bindSolidLayoutBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source(_bar),
      ),
      _error('SOLID_LAYOUT_SOURCE_CHANGED'),
    );
  });

  testWidgets('hidden supplied slot remains unresolved', (
    tester,
  ) async {
    const result = coui.EmptyState(
      title: coui.Text('title'),
      icon: coui.Text('hidden icon'),
      showIcon: false,
    );
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: result)),
    );
    expect(
      () => bindSolidLayoutBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source(_empty),
      ),
      _error('UNRESOLVED_SUPPLIED_SLOT_SOURCE'),
    );
  });

  testWidgets('duplicate supplied identity is not an owned source', (
    tester,
  ) async {
    const repeated = coui.Text('same Widget identity');
    const result = coui.EmptyState(title: repeated, description: repeated);
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: result)),
    );
    expect(
      () => bindSolidLayoutBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source(_empty),
      ),
      _error('DUPLICATE_OWNER'),
    );
  });

  testWidgets('omitted header/subtitle preserve duplicate slot identity', (
    tester,
  ) async {
    const omitted = coui.Text('same omitted Widget');
    const visible = coui.Text('actual child');
    const result = coui.AppBar(
      header: omitted,
      subtitle: omitted,
      child: visible,
    );
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: result)),
    );
    await tester.pumpAndSettle();
    final root = capture.currentContext! as Element;
    final producer = requireOneBoxOwner(
      boxElements(root).where((element) => identical(element.widget, result)),
      'the actual public AppBar source input',
    );
    final declaration = DeclaredBoxProducer.bind(
      producer: producer,
      sourceContract: 'renderer-frame-padding-v1',
    );
    expect(declaration.unrenderedSuppliedSlots, hasLength(2));
    expect(
      declaration.unrenderedSuppliedSlots.every(
        (widget) => identical(widget, omitted),
      ),
      true,
    );
    expect(declaration.scope.suppliedSlots, [same(visible)]);
    expect(
      boxElements(
        producer,
      ).any((element) => identical(element.widget, omitted)),
      false,
    );
    expect(
      () => bindSolidLayoutBoxSource(
        captureRoot: root,
        registryResult: result,
        source: _source(_bar),
      ),
      _error('DUPLICATE_OWNER'),
    );
  });

  testWidgets('stale tuple/result and unknown unit never fall back', (
    tester,
  ) async {
    final actual = AppBarDefaultExample(key: UniqueKey());
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: actual)),
    );
    final root = capture.currentContext! as Element;
    expect(
      () => bindSolidLayoutBoxSource(
        captureRoot: root,
        registryResult: AppBarDefaultExample(key: UniqueKey()),
        source: _source(_bar),
      ),
      _error('MISMATCHED_CONSTRUCTION_RESULT'),
    );
    for (final source in [
      const BoxObservationSourceSpec(
        schemaVersion: 99,
        logicalUnitId: _bar,
        quantityId: BoxObservationSourceSpec.quantity,
        nativeAdapterId: 'app-bar-solid-content-inset-v1',
        webAdapterId: 'app-bar-solid-content-inset-v1',
      ),
      const BoxObservationSourceSpec(
        schemaVersion: 1,
        logicalUnitId: _bar,
        quantityId: 'stale',
        nativeAdapterId: 'app-bar-solid-content-inset-v1',
        webAdapterId: 'app-bar-solid-content-inset-v1',
      ),
      const BoxObservationSourceSpec(
        schemaVersion: 1,
        logicalUnitId: _bar,
        quantityId: BoxObservationSourceSpec.quantity,
        nativeAdapterId: 'app-bar-solid-content-inset-v1',
        webAdapterId: 'stale',
      ),
    ]) {
      expect(
        () => bindSolidLayoutBoxSource(
          captureRoot: root,
          registryResult: actual,
          source: source,
        ),
        throwsA(isA<BoxObservationError>()),
      );
    }
    expect(
      bindSolidLayoutBoxSource(
        captureRoot: root,
        registryResult: actual,
        source: _source('unknown'),
      ),
      isNull,
    );
  });
}

class _UnknownAppBar extends coui.AppBar {
  const _UnknownAppBar();
}

class _UnknownExample extends AppBarDefaultExample {
  const _UnknownExample();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(4),
    child: coui.Text('foreign'),
  );
}

class _UnknownEmptyState extends coui.EmptyState {
  const _UnknownEmptyState() : super(title: const coui.Text('unknown'));
}
