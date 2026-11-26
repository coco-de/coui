import 'package:coui_flutter/coui_flutter.dart' as c;
import 'package:docs_core/internal/preview/flutter_stage.dart'
    show DocsStage, FlutterDocsSizeSpec;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:docs_core/shared/size_spec.dart' show docsSizeSpecFor;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/manifest/capture_probes.dart';
import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

Map<String, Object?> _observe(
  Element root,
  Widget result,
  BoxObservationSourceSpec source, {
  bool omitted = false,
}) =>
    (observePairedNativePadding(
              key: 'unit',
              probes: [
                ParityProbeSpec(
                  role: 'root',
                  flutterFinder: 'unused-sanity-finder',
                  fields: const {'paddingPx'},
                  boxObservationSource: source.toJson(),
                ),
              ],
              captureRoot: root,
              registryResult: result,
              legacyRootOmitted: omitted,
            )['byRole']!
            as Map)['root']!
        as Map<String, Object?>;

Widget _app(Widget child) => buildTestApp(
  child,
  theme: c.ThemeData.fromCore(c.CoreThemePresets.light),
);

void main() {
  const recipes = <({String component, String variant})>[
    (component: 'code-diff', variant: 'default'),
    (component: 'command', variant: 'default'),
    (component: 'command', variant: 'scrollable'),
    (component: 'command', variant: 'empty'),
    (component: 'fieldset', variant: 'default'),
    (component: 'fieldset', variant: 'outlined'),
    (component: 'fieldset', variant: 'plain'),
    (component: 'item-picker', variant: 'default'),
    (component: 'mockup-browser', variant: 'default'),
    (component: 'object-input', variant: 'default'),
  ];
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        'registered ${recipe.component}/${recipe.variant} dark=$dark reaches the shared observer',
        (tester) async {
          final source = captureProbes(
            key: 'unit',
            component: recipe.component,
            variant: recipe.variant,
            flutterClassName: 'sanity-only',
          ).single.boxObservationSource!;
          final unit = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final key = GlobalKey();
          await tester.pumpWidget(
            buildTestApp(
              KeyedSubtree(key: key, child: unit),
              theme: c.ThemeData.fromCore(
                dark ? c.CoreThemePresets.dark : c.CoreThemePresets.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final observed = _observe(
            key.currentContext! as Element,
            unit,
            source,
          );
          expect(observed['status'], 'source-complete');
          expect(observed['source'], source.toJson());
          expect(observed['sourceReaderId'], 'outlined-content-v1');
          expect(observed['declaredPaddingSourceElement'], isNotNull);
          expect(
            observed['declaringProducerElement'],
            observed['layoutRootElement'],
          );
          expect(observed['value'], hasLength(4));
          expect(observed['canonicalComparisonEligible'], isFalse);
        },
      );
    }
  }

  testWidgets(
    'SizeSpec paired dispatch binds preview without changing its root',
    (
      tester,
    ) async {
      final key = GlobalKey();
      final unit = FlutterDocsSizeSpec(
        component: 'button',
        spec: docsSizeSpecFor('button')!,
        attributes: const {'component': 'button'},
      );
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: KeyedSubtree(key: key, child: unit),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final observed = _observe(
        key.currentContext! as Element,
        unit,
        BoxObservationSourceSpec.docsSizePreview,
      );
      expect(observed['status'], 'source-complete');
      expect(
        observed['layoutRootElement'],
        isNot(observed['fieldUnitElement']),
      );
      expect(
        observed['declaredPaddingSourceElement'],
        isNot(observed['fieldUnitElement']),
      );
      expect(observed['sourceReaderId'], 'current-render-padding-v1');
      expect(observed['canonicalComparisonEligible'], isFalse);
    },
  );

  testWidgets(
    'NoPaint own16 is observed without resurrecting an omitted role',
    (
      tester,
    ) async {
      final key = GlobalKey();
      final unit = Container(
        key: key,
        padding: const EdgeInsets.all(16),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: SizedBox(width: 10, height: 10),
        ),
      );
      await tester.pumpWidget(_app(unit));
      final observed = _observe(
        key.currentContext! as Element,
        unit,
        BoxObservationSourceSpec.declaredLayout,
        omitted: true,
      );
      expect(observed['status'], 'source-complete');
      expect(observed['value'], [16.0, 16.0, 16.0, 16.0]);
      expect(observed['frameSourceOwnerElement'], isNull);
      expect(observed['legacyRoleEligible'], isFalse);
      expect(observed['canonicalComparisonEligible'], isFalse);
    },
  );

  testWidgets('direct shared unit preserves its foreign content boundary', (
    tester,
  ) async {
    final key = GlobalKey();
    final unit = c.OutlinedContainer(
      key: key,
      containerStyle: const c.CoreOutlinedContainerStyle(
        padding: c.CoreEdgeInsets.all(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: SizedBox(width: 10, height: 10),
      ),
    );
    await tester.pumpWidget(_app(unit));
    await tester.pumpAndSettle();
    final observed = _observe(
      key.currentContext! as Element,
      unit,
      BoxObservationSourceSpec.outlined,
    );
    expect(observed['status'], 'source-complete');
    expect(observed['value'], [16.0, 16.0, 16.0, 16.0]);
    expect(observed['frameSourceOwnerElement'], isNotNull);
    expect(
      observed['frameSourceOwnerElement'],
      isNot(observed['ownerElement']),
    );
  });

  testWidgets(
    'the paired adapter reads current interpolation, not its target',
    (
      tester,
    ) async {
      final key = GlobalKey();
      final target = ValueNotifier<double>(0);
      late AnimatedContainer unit;
      await tester.pumpWidget(
        _app(
          ValueListenableBuilder<double>(
            valueListenable: target,
            builder: (_, value, child) => unit = AnimatedContainer(
              key: key,
              duration: const Duration(milliseconds: 100),
              padding: EdgeInsets.all(value),
              child: child,
            ),
            child: const Text('Current layout'),
          ),
        ),
      );
      target.value = 16;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final observed = _observe(
        key.currentContext! as Element,
        unit,
        BoxObservationSourceSpec.declaredLayout,
      );
      expect(observed['status'], 'source-complete', reason: '$observed');
      expect(observed['value'], [8.0, 8.0, 8.0, 8.0]);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox.shrink());
      target.dispose();
    },
  );

  testWidgets(
    'DocsStage binds the constructor result and generated Container',
    (
      tester,
    ) async {
      final key = GlobalKey();
      final unit = DocsStage(
        key: key,
        attributes: const {'component': 'button', 'height': 'hug'},
      );
      await tester.pumpWidget(_app(unit));
      await tester.pumpAndSettle();
      final observed = _observe(
        key.currentContext! as Element,
        unit,
        BoxObservationSourceSpec.docsStage,
      );
      expect(observed['status'], 'source-complete');
      expect(observed['value'], [24.0, 24.0, 24.0, 24.0]);
    },
  );

  testWidgets('a supplied descendant cannot impersonate the registry result', (
    tester,
  ) async {
    final key = GlobalKey();
    final supplied = Container(
      padding: const EdgeInsets.all(4),
      child: const Text('Child'),
    );
    await tester.pumpWidget(
      _app(
        KeyedSubtree(
          key: key,
          child: Container(child: supplied),
        ),
      ),
    );
    final observed = _observe(
      key.currentContext! as Element,
      supplied,
      BoxObservationSourceSpec.declaredLayout,
    );
    expect(observed['status'], 'incomplete');
    expect(observed['error'], 'MISMATCHED_CONSTRUCTION_RESULT');
    expect(observed.containsKey('value'), isFalse);
  });

  testWidgets('a wrong source constructor is incomplete with no value', (
    tester,
  ) async {
    final key = GlobalKey();
    final unit = Container(key: key, child: const Text('Not an outlined unit'));
    await tester.pumpWidget(_app(unit));
    final observed = _observe(
      key.currentContext! as Element,
      unit,
      BoxObservationSourceSpec.outlined,
    );
    expect(observed['status'], 'incomplete');
    expect(observed.containsKey('value'), isFalse);
  });
}
