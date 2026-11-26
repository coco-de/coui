import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart'
    show
        BuildContext,
        Container,
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        SizedBox,
        Text,
        TextDirection,
        UniqueKey,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_extended_component_units.dart';
import 'box_padding_observation.dart';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: unit,
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$unit-v1',
  webAdapterId: '$unit-v1',
);

Widget _app(Widget child, {bool dark = false}) => buildTestApp(
  child,
  theme: coui.ThemeData.fromCore(
    dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
  ),
);

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having((error) => error.code, 'code', code),
);

void main() {
  const recipes =
      <({String component, String variant, String unit, String reader})>[
        (
          component: 'banner',
          variant: 'default',
          unit: 'banner-generated-frame',
          reader: 'current-container-v1',
        ),
        (
          component: 'banner',
          variant: 'info',
          unit: 'banner-generated-frame',
          reader: 'current-container-v1',
        ),
        (
          component: 'banner',
          variant: 'warning',
          unit: 'banner-generated-frame',
          reader: 'current-container-v1',
        ),
        (
          component: 'banner',
          variant: 'destructive',
          unit: 'banner-generated-frame',
          reader: 'current-container-v1',
        ),
        (
          component: 'banner',
          variant: 'success',
          unit: 'banner-generated-frame',
          reader: 'current-container-v1',
        ),
        (
          component: 'banner',
          variant: 'solid',
          unit: 'banner-generated-frame',
          reader: 'current-container-v1',
        ),
        (
          component: 'banner',
          variant: 'narrow',
          unit: 'banner-generated-frame',
          reader: 'current-container-v1',
        ),
        (
          component: 'description-card',
          variant: 'default',
          unit: 'description-card-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'description-card',
          variant: 'filled',
          unit: 'description-card-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'description-card',
          variant: 'ghost',
          unit: 'description-card-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'description-card',
          variant: 'vertical',
          unit: 'description-card-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'description-card',
          variant: 'space-between',
          unit: 'description-card-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'description-card',
          variant: 'placeholder',
          unit: 'description-card-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'formatted-input',
          variant: 'default',
          unit: 'formatted-input-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'formatted-input',
          variant: 'korean-phone',
          unit: 'formatted-input-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'formatted-input',
          variant: 'credit-card',
          unit: 'formatted-input-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'formatted-input',
          variant: 'date',
          unit: 'formatted-input-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'formatted-input',
          variant: 'verify',
          unit: 'formatted-input-generated-frame',
          reader: 'outlined-content-v1',
        ),
        (
          component: 'frame',
          variant: 'default',
          unit: 'frame-generated-content-inset',
          reader: 'current-render-padding-v1',
        ),
        (
          component: 'frame',
          variant: 'column',
          unit: 'frame-generated-content-inset',
          reader: 'current-render-padding-v1',
        ),
        (
          component: 'frame',
          variant: 'dashed',
          unit: 'frame-generated-content-inset',
          reader: 'current-render-padding-v1',
        ),
        (
          component: 'frame',
          variant: 'elevated',
          unit: 'frame-generated-content-inset',
          reader: 'current-render-padding-v1',
        ),
      ];
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark actual route',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final capture = GlobalKey();
          await tester.pumpWidget(
            _app(
              KeyedSubtree(key: capture, child: result),
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          final binding = bindExtendedComponentBoxSource(
            captureRoot: capture.currentContext! as Element,
            registryResult: result,
            source: _source(recipe.unit),
          )!;
          expect(binding.registryResultElement.widget, same(result));
          expect(binding.readerId, recipe.reader);
          expect(
            () => binding.scope.requireOwned(binding.paddingSource),
            returnsNormally,
          );
          expect(binding.frameSource, isNotNull);
          if (recipe.component == 'frame') {
            expect(binding.paddingSource.widget, isA<Padding>());
            expect(binding.frameSource!.widget, isA<Container>());
            expect(binding.paddingSource, isNot(same(binding.frameSource)));
          } else if (recipe.component == 'banner') {
            expect(binding.paddingSource.widget, isA<Container>());
          } else {
            expect(binding.paddingSource.widget, isA<coui.OutlinedContainer>());
          }
          for (final boundary in binding.scope.foreignBoundaries) {
            expect(
              () => binding.scope.requireOwned(boundary),
              _error('FOREIGN_SUPPLIED_CONTENT'),
            );
          }
        },
      );
    }
  }

  testWidgets(
    'Frame own inset stays distinct from equal margin and foreign inset',
    (tester) async {
      final values = ValueNotifier<(double, double, double)>((16, 16, 4));
      addTearDown(values.dispose);
      final capture = GlobalKey();
      final frameKey = GlobalKey();
      final foreignKey = GlobalKey();
      late Widget current;
      await tester.pumpWidget(
        _app(
          ValueListenableBuilder<(double, double, double)>(
            valueListenable: values,
            builder: (_, value, _) {
              current = coui.Frame(
                key: frameKey,
                padding: coui.CoreEdgeInsets.all(value.$1),
                margin: coui.CoreEdgeInsets.all(value.$2),
                borderColor: const coui.CoreColor.token(
                  coui.CoreColors.outline,
                ),
                borderWidth: coui.CoreStrokeWidth.stroke2,
                child: Padding(
                  key: foreignKey,
                  padding: EdgeInsets.all(value.$3),
                  child: const SizedBox(width: 40, height: 20),
                ),
              );
              return KeyedSubtree(key: capture, child: current);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      ExtendedComponentBoxSourceBinding bind() =>
          bindExtendedComponentBoxSource(
            captureRoot: capture.currentContext! as Element,
            registryResult: current,
            source: _source('frame-generated-content-inset'),
          )!;
      EdgeInsets parameter(Element owner) =>
          (owner.renderObject! as RenderPadding).padding.resolve(
            TextDirection.ltr,
          );
      final before = bind();
      final ownElement = before.paddingSource;
      final frameElement = before.frameSource;
      final foreignElement = foreignKey.currentContext! as Element;
      expect(parameter(ownElement), const EdgeInsets.all(16));
      expect(parameter(foreignElement), const EdgeInsets.all(4));
      final frameContainer = frameElement!.widget as Container;
      expect(frameContainer.padding, isNull);
      expect(
        frameContainer.decoration!.padding.resolve(TextDirection.ltr),
        const EdgeInsets.all(2),
      );
      expect(
        () => before.scope.requireOwned(foreignElement),
        _error('FOREIGN_SUPPLIED_CONTENT'),
      );
      values.value = (16, 24, 12);
      await tester.pumpAndSettle();
      final foreignChanged = bind();
      expect(foreignChanged.paddingSource, same(ownElement));
      expect(foreignChanged.frameSource, same(frameElement));
      expect(foreignKey.currentContext, same(foreignElement));
      expect(parameter(ownElement), const EdgeInsets.all(16));
      expect(parameter(foreignElement), const EdgeInsets.all(12));
      values.value = (24, 24, 12);
      await tester.pumpAndSettle();
      expect(bind().paddingSource, same(ownElement));
      expect(parameter(ownElement), const EdgeInsets.all(24));
    },
  );

  testWidgets('Frame zero own inset cannot borrow the foreign Padding', (
    tester,
  ) async {
    const result = coui.Frame(
      padding: coui.CoreEdgeInsets.zero,
      borderRadius: coui.CoreBorderRadius.all(coui.CoreRadius.radius8),
      child: Padding(padding: EdgeInsets.all(4), child: Text('Foreign')),
    );
    final capture = GlobalKey();
    await tester.pumpWidget(_app(KeyedSubtree(key: capture, child: result)));
    await tester.pumpAndSettle();
    expect(
      () => bindExtendedComponentBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source('frame-generated-content-inset'),
      ),
      _error('FOREIGN_SUPPLIED_CONTENT'),
    );
  });

  testWidgets('DescriptionCard scalar and nested row slots remain foreign', (
    tester,
  ) async {
    final supplied = List.generate(
      6,
      (index) => coui.OutlinedContainer(
        key: UniqueKey(),
        child: Text('Foreign $index'),
      ),
    );
    final result = coui.DescriptionCard(
      title: 'Title',
      titleLeading: supplied[0],
      titleTrailing: supplied[1],
      bottomAction: supplied[2],
      rows: [
        coui.DescriptionRow(
          label: 'Label',
          valueWidget: supplied[3],
          leading: supplied[4],
          trailing: supplied[5],
        ),
      ],
    );
    final capture = GlobalKey();
    await tester.pumpWidget(_app(KeyedSubtree(key: capture, child: result)));
    await tester.pumpAndSettle();
    final binding = bindExtendedComponentBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: _source('description-card-generated-frame'),
    )!;
    for (final widget in supplied) {
      expect(
        () => binding.scope.requireOwned(tester.element(find.byWidget(widget))),
        _error('FOREIGN_SUPPLIED_CONTENT'),
      );
    }
    expect(binding.paddingSource.widget, isA<coui.OutlinedContainer>());
  });

  testWidgets(
    'Banner copied action boundary preserves actual supplied references',
    (tester) async {
      var presses = 0;
      final child = coui.OutlinedContainer(
        key: UniqueKey(),
        child: const Text('Action'),
      );
      final action = coui.Button(onPressed: () => presses++, child: child);
      final result = coui.Banner.warning(
        message: const Text('Message'),
        action: action,
      );
      final capture = GlobalKey();
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: KeyedSubtree(key: capture, child: result),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final binding = bindExtendedComponentBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source('banner-generated-frame'),
      )!;
      final boundary = requireOneBoxOwner(
        binding.scope.foreignBoundaries.where((element) {
          final widget = element.widget;
          return widget is coui.Button &&
              identical(widget.child, action.child) &&
              identical(widget.leading, action.leading) &&
              identical(widget.trailing, action.trailing) &&
              identical(widget.onPressed, action.onPressed);
        }),
        'the existing factory-proven action boundary',
      );
      expect(
        () => binding.scope.requireOwned(boundary),
        _error('FOREIGN_SUPPLIED_CONTENT'),
      );
      expect(presses, 0);
      expect(binding.paddingSource.widget, isA<Container>());
    },
  );

  testWidgets('unknown Frame subclass cannot offer a foreign frame', (
    tester,
  ) async {
    const result = _ForeignFrame();
    final capture = GlobalKey();
    await tester.pumpWidget(_app(KeyedSubtree(key: capture, child: result)));
    expect(
      () => bindExtendedComponentBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source('frame-generated-content-inset'),
      ),
      _error('UNREGISTERED_COMPONENT_CONSTRUCTION'),
    );
  });
  testWidgets('wrong tuple or an unmounted result supplies no owner', (
    tester,
  ) async {
    final result = coui.Frame(
      key: UniqueKey(),
      padding: const coui.CoreEdgeInsets.all(16),
      borderRadius: const coui.CoreBorderRadius.all(coui.CoreRadius.radius8),
      child: const Text('Actual'),
    );
    final other = coui.Frame(key: UniqueKey(), child: const Text('Other'));
    final capture = GlobalKey();
    await tester.pumpWidget(_app(KeyedSubtree(key: capture, child: result)));
    expect(
      () => bindExtendedComponentBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: other,
        source: _source('frame-generated-content-inset'),
      ),
      _error('MISMATCHED_CONSTRUCTION_RESULT'),
    );
    expect(
      () => bindExtendedComponentBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: const BoxObservationSourceSpec(
          schemaVersion: 1,
          logicalUnitId: 'frame-generated-content-inset',
          quantityId: BoxObservationSourceSpec.quantity,
          nativeAdapterId: 'frame-generated-content-inset-v1',
          webAdapterId: 'banner-generated-frame-v1',
        ),
      ),
      _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH'),
    );
  });
}

class _ForeignFrame extends coui.Frame {
  const _ForeignFrame();

  @override
  Widget build(BuildContext context) => const coui.OutlinedContainer(
    child: Padding(padding: EdgeInsets.all(12), child: Text('Foreign')),
  );
}
