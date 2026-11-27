import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart' show RenderPadding;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_bottom_action_bar_source.dart';
import 'box_padding_observation.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

const _source = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'bottom-action-bar-owned-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'bottom-action-bar-owned-content-inset-v1',
  'webAdapterId': 'bottom-action-bar-owned-content-inset-v1',
};
void main() {
  _controls();
  for (final variant in ['default', 'horizontal', 'summary-compact']) {
    for (final theme in ['light', 'dark']) {
      testWidgets('BottomActionBar original Native entry $variant/$theme', (
        tester,
      ) async {
        final example = kFlutterPreviewRegistry['bottom-action-bar']!(variant);
        final rootKey = GlobalKey();
        await pumpTestApp(
          tester,
          SizedBox(
            width: 800,
            child: KeyedSubtree(key: rootKey, child: example),
          ),
          theme: ThemeData.fromCore(
            theme == 'dark' ? CoreThemePresets.dark : CoreThemePresets.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final products = find.byType(BottomActionBar);
        expect(products, findsOneWidget);
        final product = tester.widget<BottomActionBar>(products);
        expect(find.byWidget(product.primaryAction), findsOneWidget);
        final safeFinder = find.descendant(
          of: products,
          matching: find.byType(SafeArea),
        );
        expect(safeFinder, findsOneWidget);
        final safe = tester.widget<SafeArea>(safeFinder);
        expect(safe.bottom, true);
        expect(safe.top || safe.left || safe.right, false);
        expect(safe.child, isA<Padding>());
        expect(find.byWidget(safe.child), findsOneWidget);
        expect((safe.child as Padding).child, isA<Column>());
        final observed = observePairedNativePadding(
          key: 'bottom-action-bar-$variant-$theme-defaultStyle',
          probes: const [
            ParityProbeSpec(
              role: 'root',
              flutterFinder: 'byType:BottomActionBar',
              fields: {'paddingPx'},
              boxObservationSource: _source,
            ),
          ],
          captureRoot: rootKey.currentContext! as Element,
          registryResult: example,
          legacyRootOmitted: true,
        );
        final row = (observed['byRole']! as Map)['root']! as Map;
        // Normal product, original required action and two-layer source health
        // precede the source assertion in the qualified current entry.
        expect(
          row['status'],
          'source-complete',
          reason: 'BOTTOM_ACTION_BAR_NATIVE_ORIGINAL_SOURCE_RED',
        );
        expect(row['quantityKind'], 'frameworkOwnedPaddingComposition');
        expect(row['source'], _source);
        expect(row['legacyRoleEligible'], false);
        expect(row['canonicalComparisonEligible'], false);
      });
    }
  }
}

void _controls() {
  ValueNotifier<Widget>? currentContent;
  setUp(() {
    currentContent = null;
  });
  tearDown(() {
    currentContent?.dispose();
  });
  BottomActionBar bar({
    double divider = 1,
    Widget? primary,
    Widget? secondary,
    Widget? label,
    Widget? value,
    CoreBottomActionBarLayout layout = .vertical,
  }) => BottomActionBar(
    primaryAction: primary ?? const SizedBox(width: 8, height: 8),
    secondaryAction: secondary,
    summaryLabel: label,
    summaryValue: value,
    layout: layout,
    bottomActionBarStyle: CoreBottomActionBarStyle(
      padding: const CoreEdgeInsets.directional(
        start: 11,
        end: 7,
        top: 3,
        bottom: 5,
      ),
      dividerWidth: divider,
    ),
  );
  Future<CurrentBottomActionBarSource> mount(
    WidgetTester tester,
    BottomActionBar product, {
    TextDirection direction = TextDirection.ltr,
    double bottom = 29,
  }) async {
    final content = Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.fromLTRB(17, 19, 23, bottom)),
        child: SizedBox(width: 800, child: product),
      ),
    );
    if (currentContent == null) {
      final state = ValueNotifier<Widget>(content);
      currentContent = state;
      await pumpTestApp(
        tester,
        ValueListenableBuilder<Widget>(
          valueListenable: state,
          builder: (_, child, _) => child,
        ),
        theme: ThemeData.fromCore(CoreThemePresets.light),
      );
    } else {
      currentContent!.value = content;
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return bindCurrentBottomActionBarProduct(
      tester.element(find.byType(BottomActionBar)),
    );
  }

  Map<String, Object?> measured(CurrentBottomActionBarSource source) =>
      source.readActualPadding().toJson();
  testWidgets(
    'two actual padding contributions include nonzero bottom SafeArea only',
    (tester) async {
      final source = await mount(tester, bar());
      final row = measured(source);
      expect(row['quantityKind'], 'frameworkOwnedPaddingComposition');
      expect(row['value'], [3, 7, 34, 11]);
      expect((row['measurement']! as Map)['contributors'], [
        {
          'ordinal': 0,
          'paddingPx': [0, 0, 29, 0],
        },
        {
          'ordinal': 1,
          'paddingPx': [3, 7, 5, 11],
        },
      ]);
      expect(row.containsKey('currentRenderPadding'), false);
      expect(row.containsKey('actualPaddingElement'), false);
    },
  );
  testWidgets(
    'normal RTL rebuild resolves actual directional contribution and stales '
    'old source',
    (tester) async {
      final old = await mount(tester, bar());
      expect(measured(old)['value'], [3, 7, 34, 11]);
      final current = await mount(tester, bar(), direction: TextDirection.rtl);
      expect(old.validateCurrentBinding, throwsA(isA<BoxObservationError>()));
      expect(measured(current)['value'], [3, 11, 34, 7]);
    },
  );
  testWidgets(
    'border allocation is excluded while both real own contributors remain',
    (tester) async {
      final thin = measured(await mount(tester, bar(divider: 1)));
      final thick = measured(await mount(tester, bar(divider: 13)));
      expect(thin['value'], [3, 7, 34, 11]);
      expect(thick['value'], thin['value']);
      expect((thick['sourceIdentity']! as Map)['contributors'], hasLength(2));
    },
  );
  testWidgets(
    'zero bottom safe inset still retains a real first Padding contributor',
    (tester) async {
      final row = measured(await mount(tester, bar(), bottom: 0));
      expect(row['quantityKind'], 'frameworkOwnedPaddingComposition');
      expect(row['value'], [3, 7, 5, 11]);
      final contributors =
          (row['sourceIdentity']! as Map)['contributors']! as List;
      expect(contributors, hasLength(2));
      expect((contributors.first as Map)['slot'], 'SafeArea.generatedPadding');
    },
  );
  testWidgets('caller padding is opaque to the own composition', (
    tester,
  ) async {
    final first = measured(
      await mount(
        tester,
        bar(
          primary: const Padding(
            padding: EdgeInsets.all(100),
            child: SizedBox(width: 8, height: 8),
          ),
        ),
      ),
    );
    final second = measured(
      await mount(
        tester,
        bar(
          primary: const Padding(
            padding: EdgeInsets.all(200),
            child: SizedBox(width: 8, height: 8),
          ),
        ),
      ),
    );
    expect(first['value'], [3, 7, 34, 11]);
    expect(second['value'], first['value']);
  });
  testWidgets(
    'stable foreign boundary may replace its own renderer without staling '
    'own source',
    (tester) async {
      final change = ValueNotifier<bool>(false);
      addTearDown(change.dispose);
      final foreign = ValueListenableBuilder<bool>(
        valueListenable: change,
        builder: (_, padded, _) => padded
            ? const Padding(
                padding: EdgeInsets.all(70),
                child: SizedBox(width: 8, height: 8),
              )
            : const SizedBox(width: 8, height: 8),
      );
      final source = await mount(tester, bar(primary: foreign));
      // Test-only public witness of the counterexample: the observer itself
      // must
      // stop at the fixed supplied Widget/Element and never read this renderer.
      final boundary = tester.element(find.byWidget(foreign));
      final previousForeignRender = boundary.renderObject;
      expect(measured(source)['value'], [3, 7, 34, 11]);
      change.value = true;
      await tester.pumpAndSettle();
      expect(identical(previousForeignRender, boundary.renderObject), false);
      source.validateCurrentBinding();
      expect(measured(source)['value'], [3, 7, 34, 11]);
    },
  );
  testWidgets(
    'all five seats retain inactive supplied secondary and null summary in '
    'compact layout',
    (tester) async {
      final source = await mount(
        tester,
        bar(
          layout: .summaryCompact,
          secondary: const SizedBox(width: 9, height: 9),
        ),
      );
      final seats = source.sourceIdentity['declaredSeats']! as List;
      expect(seats, hasLength(5));
      final inactive = seats[1] as Map;
      expect(inactive['present'], true);
      expect(inactive['layoutActive'], false);
      expect(inactive['mountedFrontierPresent'], false);
      expect((seats[3] as Map)['present'], false);
      expect((seats[4] as Map)['present'], false);
      expect(measured(source)['value'], [3, 7, 34, 11]);
    },
  );
  testWidgets(
    'actual installed parameter mutation rejects source independently of '
    'measurement',
    (tester) async {
      final held = await mount(tester, bar());
      final safe = tester.widget<SafeArea>(
        find.descendant(
          of: find.byType(BottomActionBar),
          matching: find.byType(SafeArea),
        ),
      );
      final render =
          tester.element(find.byWidget(safe.child)).renderObject!
              as RenderPadding;
      final original = render.padding;
      const changed = EdgeInsets.fromLTRB(41, 43, 47, 53);
      try {
        render.padding = changed;
        expect(identical(render.padding, changed), true);
        expect(identical(render.padding, original), false);
        expect(
          held.validateCurrentBinding,
          throwsA(isA<BoxObservationError>()),
        );
      } finally {
        render.padding = original;
      }
      held.validateCurrentBinding();
    },
  );
  testWidgets('public render direction mutation rejects held source', (
    tester,
  ) async {
    final held = await mount(tester, bar());
    final safe = tester.widget<SafeArea>(
      find.descendant(
        of: find.byType(BottomActionBar),
        matching: find.byType(SafeArea),
      ),
    );
    final render =
        tester.element(find.byWidget(safe.child)).renderObject!
            as RenderPadding;
    final direction = render.textDirection;
    try {
      render.textDirection = TextDirection.rtl;
      expect(render.textDirection, TextDirection.rtl);
      expect(held.validateCurrentBinding, throwsA(isA<BoxObservationError>()));
    } finally {
      render.textDirection = direction;
    }
    held.validateCurrentBinding();
  });
  testWidgets(
    'fresh equal-value rebuild accepts independent current Widget and render '
    'parameter refs',
    (tester) async {
      await mount(tester, bar());
      final safe1 = tester.widget<SafeArea>(
        find.descendant(
          of: find.byType(BottomActionBar),
          matching: find.byType(SafeArea),
        ),
      );
      final render1 =
          tester.element(find.byWidget(safe1.child)).renderObject!
              as RenderPadding;
      final before = render1.padding;
      final current = await mount(tester, bar());
      final safe2 = tester.widget<SafeArea>(
        find.descendant(
          of: find.byType(BottomActionBar),
          matching: find.byType(SafeArea),
        ),
      );
      final explicit = safe2.child as Padding;
      final render2 =
          tester.element(find.byWidget(explicit)).renderObject!
              as RenderPadding;
      expect(identical(render1, render2), true);
      expect(identical(render2.padding, before), true);
      expect(identical(explicit.padding, render2.padding), false);
      expect(measured(current)['value'], [3, 7, 34, 11]);
    },
  );
}
