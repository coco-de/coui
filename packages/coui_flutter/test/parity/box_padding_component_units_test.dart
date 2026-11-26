import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/code_diff/code_diff_default_example.dart';
import 'package:docs_core/previews/examples/flutter/command/command_dialog_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show
        BuildContext,
        Element,
        GlobalKey,
        KeyedSubtree,
        SizedBox,
        Text,
        UniqueKey,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_component_units.dart';
import 'box_padding_observation.dart';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: '$unit-generated-frame',
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$unit-generated-frame-v1',
  webAdapterId: '$unit-generated-frame-v1',
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
  const recipes = <({String component, String variant, String unit})>[
    (component: 'code-diff', variant: 'default', unit: 'code-diff'),
    (component: 'command', variant: 'default', unit: 'command-panel'),
    (component: 'command', variant: 'scrollable', unit: 'command-panel'),
    (component: 'command', variant: 'empty', unit: 'command-panel'),
    (component: 'fieldset', variant: 'default', unit: 'fieldset'),
    (component: 'fieldset', variant: 'outlined', unit: 'fieldset'),
    (component: 'fieldset', variant: 'plain', unit: 'fieldset'),
    (component: 'item-picker', variant: 'default', unit: 'item-picker'),
    (component: 'mockup-browser', variant: 'default', unit: 'mockup-browser'),
    (component: 'object-input', variant: 'default', unit: 'object-input'),
  ];
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark binds actual source',
        (tester) async {
          // This is the input actually mounted, not a second factory result
          // manufactured by the observer to resemble the mounted object.
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
          final bound = bindComponentBoxSource(
            captureRoot: capture.currentContext! as Element,
            registryResult: result,
            source: _source(recipe.unit),
          )!;
          expect(bound.registryResultElement.widget, same(result));
          expect(bound.paddingSource.widget, isA<coui.OutlinedContainer>());
          expect(bound.frameSource, same(bound.paddingSource));
          expect(bound.readerId, 'outlined-content-v1');
          expect(bound.fieldUnitElement, isNot(same(bound.paddingSource)));
          expect(
            () => bound.scope.requireOwned(bound.paddingSource),
            returnsNormally,
          );
          if (bound.fieldUnitElement.widget case final coui.Fieldset field) {
            for (final supplied in [
              ?field.legend,
              ?field.description,
              ...field.children,
            ]) {
              final element = requireOneBoxOwner(
                boxElements(bound.fieldUnitElement).where(
                  (element) => identical(element.widget, supplied),
                ),
                'the actual fieldset public slot',
              );
              expect(
                () => bound.scope.requireOwned(element),
                _error('FOREIGN_SUPPLIED_CONTENT'),
              );
            }
          }
        },
      );
    }
  }
  testWidgets('an unmounted same-class object cannot stand in for the result', (
    tester,
  ) async {
    final actual = CodeDiffDefaultExample(key: UniqueKey());
    final other = CodeDiffDefaultExample(key: UniqueKey());
    final capture = GlobalKey();
    await tester.pumpWidget(
      _app(KeyedSubtree(key: capture, child: actual)),
    );
    expect(
      () => bindComponentBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: other,
        source: _source('code-diff'),
      ),
      _error('MISMATCHED_CONSTRUCTION_RESULT'),
    );
  });
  for (final result in <Widget>[
    const _ForeignCodeDiffExample(),
    const CommandDialogExample(),
    const SizedBox(child: CodeDiffDefaultExample()),
  ]) {
    testWidgets('unknown constructor ${result.runtimeType} stays unsupported', (
      tester,
    ) async {
      final capture = GlobalKey();
      await tester.pumpWidget(
        _app(KeyedSubtree(key: capture, child: result)),
      );
      expect(
        () => bindComponentBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: result,
          source: _source(
            result is CommandDialogExample ? 'command-panel' : 'code-diff',
          ),
        ),
        _error('UNREGISTERED_COMPONENT_CONSTRUCTION'),
      );
    });
  }
  testWidgets('adapter mismatch fails before it can borrow another frame', (
    tester,
  ) async {
    const result = CodeDiffDefaultExample();
    final capture = GlobalKey();
    await tester.pumpWidget(_app(KeyedSubtree(key: capture, child: result)));
    expect(
      () => bindComponentBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: const BoxObservationSourceSpec(
          schemaVersion: 1,
          logicalUnitId: 'code-diff-generated-frame',
          quantityId: BoxObservationSourceSpec.quantity,
          nativeAdapterId: 'code-diff-generated-frame-v1',
          webAdapterId: 'object-input-generated-frame-v1',
        ),
      ),
      _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH'),
    );
    expect(
      bindComponentBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source('code-snippet'),
      ),
      isNull,
    );
  });
}

class _ForeignCodeDiffExample extends CodeDiffDefaultExample {
  const _ForeignCodeDiffExample();

  @override
  Widget build(BuildContext context) => const coui.OutlinedContainer(
    child: Text('Foreign frame from an unaudited subclass'),
  );
}
