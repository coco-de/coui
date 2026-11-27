import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/breakpoint/breakpoint_default_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_breakpoint_showcase_units.dart';
import 'box_padding_observation.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

Future<void> _mount(
  WidgetTester tester,
  Widget result,
  GlobalKey key, {
  bool dark = false,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      SizedBox(
        width: 800,
        height: 600,
        child: KeyedSubtree(key: key, child: result),
      ),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  await tester.pump();
}

BreakpointShowcaseBoxSourceBinding _bind(GlobalKey key, Widget result) =>
    bindBreakpointShowcaseBoxSource(
      captureRoot: key.currentContext! as Element,
      registryResult: result,
      source: kBreakpointShowcaseContentInsetSource,
    )!;
Map<String, Object?> _shared(
  GlobalKey key,
  Widget result,
  Map<String, Object?>? source,
) =>
    (observePairedNativePadding(
              key: 'non-owner-key',
              probes: [
                ParityProbeSpec(
                  role: 'root',
                  flutterFinder: 'unrelated',
                  fields: const {'paddingPx'},
                  boxObservationSource: source,
                ),
              ],
              captureRoot: key.currentContext! as Element,
              registryResult: result,
              legacyRootOmitted: true,
            )['byRole']!
            as Map<String, Object?>)['root']!
        as Map<String, Object?>;

class _Unknown extends BreakpointDefaultExample {
  const _Unknown();
}

void main() {
  const BreakpointDefaultExample Function() createExample =
      BreakpointDefaultExample.new;
  for (final dark in [false, true]) {
    testWidgets(
      'default/$dark real route and shared entry own Container allocation',
      (tester) async {
        final result = kFlutterPreviewRegistry['breakpoint']!('default');
        final key = GlobalKey();
        await _mount(tester, result, key, dark: dark);
        final b = _bind(key, result);
        final c = b.fieldUnitElement.widget as Container;
        expect(c.decoration.runtimeType, BoxDecoration);
        expect((c.decoration! as BoxDecoration).border, isNull);
        expect(b.allOriginalSuppliedSlots, [same(c.child)]);
        expect(b.scope.foreignBoundaries, hasLength(1));
        final foreign = b.scope.foreignBoundaries.single;
        expect(foreign.widget, same(c.child));
        expect(
          () => b.scope.requireOwned(foreign),
          throwsA(isA<BoxObservationError>()),
        );
        final actual = b.readActualPadding();
        final render = b.actualPaddingElement.renderObject! as RenderPadding;
        expect(actual.quantity, PaddingQuantityKind.frameworkOwnParameter);
        expect(actual.value, render.padding.resolve(render.textDirection));
        expect(actual.owner, same(b.paddingSource));
        expect(actual.paddingElement, same(b.actualPaddingElement));
        expect(actual.frameOwner, same(b.frameSource));
        expect(actual.contentBoundary, same(foreign));
        expect(actual.allocatedDecorationInsets, EdgeInsets.zero);
        expect(
          _shared(
            key,
            result,
            kBreakpointShowcaseContentInsetSource.toJson(),
          )['status'],
          'source-complete',
        );
        expect(_shared(key, result, null)['status'], 'incomplete');
        expect(b.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
      },
    );
  }
  testWidgets(
    'unknown subclass, copied registry and forged tuple remain incomplete',
    (tester) async {
      const unknown = _Unknown();
      final key = GlobalKey();
      await _mount(tester, unknown, key);
      expect(
        _shared(
          key,
          unknown,
          kBreakpointShowcaseContentInsetSource.toJson(),
        )['status'],
        'incomplete',
      );
      final result = createExample();
      await _mount(tester, result, key);
      final copiedResult = createExample();
      expect(identical(result, copiedResult), isFalse);
      expect(
        _shared(
          key,
          copiedResult,
          kBreakpointShowcaseContentInsetSource.toJson(),
        )['status'],
        'incomplete',
      );
      expect(
        _shared(key, result, {
          ...kBreakpointShowcaseContentInsetSource.toJson(),
          'nativeAdapterId': 'foreign',
        })['status'],
        'incomplete',
      );
      expect(
        bindBreakpointShowcaseBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: BoxObservationSourceSpec.textShowcaseOuterPadding,
        ),
        isNull,
      );
    },
  );
  testWidgets(
    'held binding rejects public same Element declaration replacement',
    (tester) async {
      final result = createExample();
      final key = GlobalKey();
      await _mount(tester, result, key);
      final b = _bind(key, result);
      final element = b.fieldUnitElement;
      final old = element.widget as Container;
      element.owner!.buildScope(element, () {
        element.update(
          Container(
            padding: old.padding,
            decoration: old.decoration,
            child: const Padding(
              padding: EdgeInsets.all(53),
              child: Text('foreign child'),
            ),
          ),
        );
      });
      await tester.pump();
      expect(b.readActualPadding, throwsA(isA<BoxObservationError>()));
      element.owner!.buildScope(element, () {
        element.update(old);
      });
      await tester.pump();
      expect(_bind(key, result).readActualPadding().owner, same(element));
    },
  );
  testWidgets('actual border insertion cannot become a padding authority', (
    tester,
  ) async {
    final result = createExample();
    final key = GlobalKey();
    await _mount(tester, result, key);
    final b = _bind(key, result);
    final element = b.fieldUnitElement;
    final old = element.widget as Container;
    element.owner!.buildScope(element, () {
      element.update(
        Container(
          padding: old.padding,
          decoration: BoxDecoration(border: Border.all(width: 3)),
          child: old.child,
        ),
      );
    });
    await tester.pump();
    expect(() => _bind(key, result), throwsA(isA<BoxObservationError>()));
    element.owner!.buildScope(element, () {
      element.update(old);
    });
    await tester.pump();
    expect(
      _bind(key, result).readActualPadding().quantity,
      PaddingQuantityKind.frameworkOwnParameter,
    );
  });
  testWidgets(
    'same mounted Example after parent theme rebuild needs fresh binding',
    (tester) async {
      const result = BreakpointDefaultExample();
      final key = GlobalKey();
      final dark = ValueNotifier(false);
      addTearDown(dark.dispose);
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<bool>(
            valueListenable: dark,
            builder: (context, value, child) => coui.Theme(
              data: coui.ThemeData.fromCore(
                value
                    ? coui.CoreThemePresets.dark
                    : coui.CoreThemePresets.light,
              ),
              child: SizedBox(
                width: 800,
                height: 600,
                child: KeyedSubtree(key: key, child: result),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final b = _bind(key, result);
      final example = b.registryResultElement;
      dark.value = true;
      await tester.pump();
      expect(_bind(key, result).registryResultElement, same(example));
      expect(b.readActualPadding, throwsA(isA<BoxObservationError>()));
      expect(
        _bind(key, result).readActualPadding().owner,
        same(b.fieldUnitElement),
      );
    },
  );
}
