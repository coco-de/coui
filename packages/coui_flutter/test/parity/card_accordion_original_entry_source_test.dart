import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_card_accordion_frame_source.dart';
import 'box_padding_observation.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

const _card = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'card-surface-frame-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'card-current-outlined-frame-content-v1',
  'webAdapterId': 'card-current-outlined-frame-content-v1',
};
const _accordion = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'accordion-surface-frame-content-inset',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'accordion-current-outlined-frame-content-v1',
  'webAdapterId': 'accordion-current-outlined-frame-content-v1',
};
const _cases = [
  ('card', 'default'),
  ('card', 'filled'),
  ('card', 'elevated'),
  ('accordion', 'default'),
];

void main() {
  _controls();
  for (final (component, variant) in _cases) {
    for (final theme in ['light', 'dark']) {
      testWidgets('frame original Native $component/$variant/$theme', (
        tester,
      ) async {
        final original = kFlutterPreviewRegistry[component]!(variant);
        final key = GlobalKey();
        await pumpTestApp(
          tester,
          SizedBox(
            width: 800,
            child: KeyedSubtree(key: key, child: original),
          ),
          theme: ThemeData.fromCore(
            theme == 'dark' ? CoreThemePresets.dark : CoreThemePresets.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (component == 'card') {
          final product = tester.widget<Card>(find.byType(Card));
          expect(product.onTap, isNull);
          expect(product.header, isNotNull);
          expect(product.body, isNotNull);
          expect(product.child, isNull);
          expect(product.media, isNull);
        } else {
          final product = tester.widget<Accordion>(find.byType(Accordion));
          expect(product.items, hasLength(3));
          expect(
            product.items.every((item) => item.runtimeType == AccordionItem),
            true,
          );
        }
        expect(find.byType(OutlinedContainer), findsWidgets);
        final paired = observePairedNativePadding(
          key: '$component-$variant-$theme-defaultStyle',
          probes: [
            ParityProbeSpec(
              role: 'root',
              flutterFinder:
                  'byType:${component == 'card' ? 'Card' : 'Accordion'}',
              fields: const {'paddingPx'},
              boxObservationSource: component == 'card' ? _card : _accordion,
            ),
          ],
          captureRoot: key.currentContext! as Element,
          registryResult: original,
          legacyRootOmitted: false,
        );
        final row = (paired['byRole']! as Map)['root']! as Map;
        expect(
          row['status'],
          'source-complete',
          reason: 'FRAME_NATIVE_ORIGINAL_ENTRY_SOURCE_RED',
        );
        expect(row['source'], component == 'card' ? _card : _accordion);
        expect(row['quantityKind'], 'frameworkOwnParameter');
        expect(row['canonicalComparisonEligible'], false);
        final identity = row['sourceIdentity']! as Map;
        expect(identity['distributedSlotAndItemInsetsIncluded'], false);
        expect(identity['rawDeclarationMountAuthority'], false);
        expect(
          identity['rawDeclarations'],
          hasLength(component == 'card' ? 6 : 3),
        );
      });
    }
  }
}

void _controls() {
  Future<CurrentCardAccordionFrame> mount(
    WidgetTester tester,
    Widget product, {
    TextDirection direction = TextDirection.ltr,
  }) async {
    await pumpTestApp(
      tester,
      Directionality(
        textDirection: direction,
        child: SizedBox(width: 800, child: product),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    return bindCurrentCardAccordionFrame(
      tester.element(find.byWidget(product)),
    );
  }

  for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
    testWidgets(
      [
        'custom Card reads asymmetric current frame, not ',
        'border or foreign padding $direction',
      ].join(),
      (tester) async {
        const foreign = Padding(
          padding: EdgeInsets.all(701),
          child: SizedBox(width: 2, height: 2),
        );
        const product = Card(
          variant: CoreCardVariant.outlined,
          cardStyle: CoreCardStyle(
            padding: CoreEdgeInsets.only(
              left: 11,
              right: 7,
              top: 3,
              bottom: 5,
            ),
            borderWidth: 4,
            borderColor: CoreColor.primary,
          ),
          child: foreign,
        );
        final binding = await mount(tester, product, direction: direction);
        final observed = binding.readActualPadding();
        expect(
          observed.value,
          const EdgeInsets.fromLTRB(
            11,
            3,
            7,
            5,
          ),
        );
        expect(observed.frameOwner, isNot(same(observed.owner)));
        final frame = observed.frameOwner!.widget as Container;
        expect(
          frame.decoration!.padding.resolve(direction),
          const EdgeInsets.all(4),
        );

        expect(observed.excludedMargin, EdgeInsets.zero);
        expect(observed.quantity, PaddingQuantityKind.frameworkOwnParameter);
        expect(binding.sourceIdentity['rawDeclarationMountAuthority'], false);
      },
    );
  }
  testWidgets(
    [
      'Card nullable, inactive overlay and repeated raw ',
      'declarations stay separate from generated content',
    ].join(),
    (tester) async {
      const repeated = Text('alias declaration');
      const product = Card(
        header: repeated,
        body: repeated,
        overlay: Padding(padding: EdgeInsets.all(999), child: Text('inactive')),
      );
      final binding = await mount(tester, product);
      final raw = binding.sourceIdentity['rawDeclarations']! as List;
      expect(raw, hasLength(6));
      expect((raw[3] as Map)['sourceAliasOf'], 2);
      expect((raw[5] as Map)['present'], true);
      expect(find.text('inactive'), findsNothing);
      final observed = binding.readActualPadding();
      expect(observed.contentBoundary, isNotNull);
      expect(observed.paddingElement, isNotNull);
      expect(observed.currentRenderPadding, observed.value);
    },
  );
  testWidgets('Card child precedence retains supplied inactive slots', (
    tester,
  ) async {
    const product = Card(
      header: Text('inactive header'),
      media: Text('inactive media'),
      overlay: Text('inactive overlay'),
      child: Text('active child'),
    );
    final binding = await mount(tester, product);
    expect(find.text('inactive header'), findsNothing);
    expect(find.text('inactive media'), findsNothing);
    expect(
      (binding.sourceIdentity['rawDeclarations']! as List).where(
        (r) => (r as Map)['present'] == true,
      ),
      hasLength(4),
    );
    expect(
      binding.readActualPadding().quantity,
      PaddingQuantityKind.frameworkOwnParameter,
    );
  });
  testWidgets('interactive Card is rejected without invoking callback', (
    tester,
  ) async {
    var calls = 0;
    final product = Card(
      onTap: () {
        calls++;
      },
      child: const Text('interactive'),
    );
    await pumpTestApp(tester, product);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      () =>
          bindCurrentCardAccordionFrame(tester.element(find.byWidget(product))),
      throwsA(isA<BoxObservationError>()),
    );
    expect(calls, 0);
  });
  testWidgets(
    [
      'Accordion public expansion leaves item interiors ',
      'opaque and fresh frame valid',
    ].join(),
    (tester) async {
      const item = AccordionItem(
        title: 'open actual item',
        content: Padding(
          padding: EdgeInsets.all(23),
          child: Text('opaque content'),
        ),
      );
      const product = Accordion(
        items: [
          item,
          AccordionItem(title: 'other item', content: Text('other')),
        ],
      );
      final before = await mount(tester, product);
      final first = before.readActualPadding();
      final oldOwnerWidget = first.owner.widget;
      await tester.tap(find.text('open actual item'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final fresh = bindCurrentCardAccordionFrame(
        tester.element(find.byWidget(product)),
      );
      final after = fresh.readActualPadding();
      expect(after.value, first.value);
      if (!identical(oldOwnerWidget, after.owner.widget)) {
        expect(
          before.validateCurrentBinding,
          throwsA(isA<BoxObservationError>()),
        );
      } else {
        before.validateCurrentBinding();
      }
      expect(fresh.sourceIdentity['rawDeclarations'], hasLength(2));
    },
  );
  testWidgets(
    [
      'Accordion repeated item inputs retain distinct ',
      'current seats and separators',
    ].join(),
    (tester) async {
      const item = AccordionItem(title: 'repeat', content: Text('inside'));
      const product = Accordion(items: [item, item]);
      final binding = await mount(tester, product);
      final raw = binding.sourceIdentity['rawDeclarations']! as List;
      expect((raw[1] as Map)['sourceAliasOf'], 0);
      expect(find.byWidget(item), findsNWidgets(2));
      expect(
        binding.readActualPadding().quantity,
        PaddingQuantityKind.frameworkOwnParameter,
      );
    },
  );
}
