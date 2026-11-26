import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter/widgets.dart'
    show Container, Element, GlobalKey, KeyedSubtree, Padding, SizedBox, Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_control_shell_units.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: unit,
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$unit-v1',
  webAdapterId: '$unit-v1',
);

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having((error) => error.code, 'code', code),
);

void main() {
  const recipes = <({String component, String variant, String unit})>[
    (
      component: 'number-input',
      variant: 'default',
      unit: 'number-input-generated-field-frame',
    ),
    (
      component: 'number-input',
      variant: 'filled',
      unit: 'number-input-generated-field-frame',
    ),
    (
      component: 'number-input',
      variant: 'error',
      unit: 'number-input-generated-field-frame',
    ),
    (
      component: 'number-input',
      variant: 'disabled',
      unit: 'number-input-generated-field-frame',
    ),
    (
      component: 'chip',
      variant: 'removable',
      unit: 'chip-generated-frame',
    ),
    (
      component: 'chip',
      variant: 'disabled',
      unit: 'chip-generated-frame',
    ),
  ];
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark source references',
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
          final binding = bindControlShellBoxSource(
            captureRoot: key.currentContext! as Element,
            registryResult: result,
            source: _source(recipe.unit),
          )!;
          expect(binding.registryResultElement.widget, same(result));
          expect(binding.fieldUnitElement, same(binding.frameSource));
          expect(
            binding.fieldUnitElement,
            isNot(same(binding.registryResultElement)),
          );
          if (recipe.component == 'number-input') {
            expect(binding.frameSource!.widget.runtimeType, Container);
            expect(binding.paddingSource.widget.runtimeType, Padding);
            final raw = binding.paddingSource.renderObject! as RenderPadding;
            final observed = observeSourceOwnedRenderPadding(
              owner: binding.paddingSource,
              scope: binding.scope,
            );
            expect(observed.value, raw.padding.resolve(raw.textDirection));
            expect(binding.readerId, 'current-render-padding-v1');
          } else {
            expect(
              binding.paddingSource.widget.runtimeType,
              coui.OutlinedContainer,
            );
            final observed = observeOutlinedContainerContentPadding(
              primitive: binding.paddingSource,
              declaringScope: binding.scope,
            );
            expect(observed.owner, isNot(same(binding.registryResultElement)));
            expect(binding.readerId, 'outlined-content-v1');
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('supplied nested Chip cannot donate its frame', (tester) async {
    final foreignKey = GlobalKey();
    final capture = GlobalKey();
    final result = coui.Chip(
      onTap: () {},
      leading: coui.Chip(key: foreignKey, label: 'foreign', onTap: () {}),
      label: 'owned',
    );
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: capture, child: result)),
    );
    await tester.pumpAndSettle();
    final binding = bindControlShellBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: _source('chip-generated-frame'),
    )!;
    expect(
      () => binding.scope.requireOwned(foreignKey.currentContext! as Element),
      _error('FOREIGN_SUPPLIED_CONTENT'),
    );
    expect(binding.paddingSource, isNot(same(foreignKey.currentContext)));
  });

  testWidgets('observation never reinvokes public callbacks', (tester) async {
    var calls = 0;
    final result = coui.Chip(
      label: 'remove',
      onTap: () => calls++,
      onRemove: () => calls++,
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      bindControlShellBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: _source('chip-generated-frame'),
      );
    }
    expect(calls, 0);
  });

  for (final result in <Widget>[
    const _UnknownNumberInput(),
    const _UnknownChip(),
    const SizedBox(),
  ]) {
    testWidgets('${result.runtimeType} unknown construction rejects', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: key, child: result)),
      );
      await tester.pumpAndSettle();
      expect(
        () => bindControlShellBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: _source('number-input-generated-field-frame'),
        ),
        _error('UNREGISTERED_COMPONENT_CONSTRUCTION'),
      );
    });
  }

  testWidgets('display-only Chip is not an interactive source fallback', (
    tester,
  ) async {
    const result = coui.Chip(label: 'display');
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pumpAndSettle();
    expect(
      () => bindControlShellBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: _source('chip-generated-frame'),
      ),
      _error('CONTROL_SHELL_SOURCE_CHANGED'),
    );
  });

  testWidgets('missing result and wrong tuple fail closed', (tester) async {
    final mounted = coui.NumberInput(onChanged: (_) {});
    final other = coui.NumberInput(onChanged: (_) {});
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: mounted)),
    );
    await tester.pumpAndSettle();
    expect(
      () => bindControlShellBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: other,
        source: _source('number-input-generated-field-frame'),
      ),
      _error('CONTROL_SHELL_SOURCE_CHANGED'),
    );
    final json = _source('number-input-generated-field-frame').toJson();
    for (final mutation in <Map<String, Object?>>[
      {...json, 'schemaVersion': 2},
      {...json, 'webAdapterId': 'chip-generated-frame-v1'},
      {...json, 'quantityId': 'unknown'},
    ]) {
      expect(
        () => bindControlShellBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: mounted,
          source: BoxObservationSourceSpec.fromJson(mutation),
        ),
        throwsA(isA<BoxObservationError>()),
      );
    }
    expect(
      bindControlShellBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: mounted,
        source: _source('unsupported'),
      ),
      isNull,
    );
  });
}

class _UnknownNumberInput extends coui.NumberInput {
  const _UnknownNumberInput();
}

class _UnknownChip extends coui.Chip {
  const _UnknownChip();
}
