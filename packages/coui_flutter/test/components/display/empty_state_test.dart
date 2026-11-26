import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kTestIconSize = 64.0;
const _kTestMinHeight = 300.0;
const _kTestPadding = 24.0;
const _kTestColor = CoreColor(0xFFFF0000);

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: material.Scaffold(body: child),
    ),
  );
}

Finder _iconFinder(IconName name) =>
    find.byWidgetPredicate((widget) => widget is Icon && widget.icon == name);

void main() {
  group('EmptyState widget', () {
    testWidgets('renders with required title', (tester) async {
      await tester.pumpWidget(
        _buildApp(const EmptyState(title: Text('No results found'))),
      );

      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState(
            title: Text('No results found'),
            icon: Icon(LucideIcons.searchX),
          ),
        ),
      );

      expect(_iconFinder(LucideIcons.searchX), findsOneWidget);
      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('renders with description', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState(
            title: Text('No results found'),
            description: Text('Try adjusting your search'),
          ),
        ),
      );

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try adjusting your search'), findsOneWidget);
    });

    testWidgets('renders with action', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          EmptyState(
            title: const Text('No results found'),
            action: Button(
              onPressed: () {},
              child: const Text('Clear Filters'),
            ),
          ),
        ),
      );

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);
    });

    testWidgets('renders with all optional widgets', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          EmptyState(
            title: const Text('Error'),
            icon: const Icon(LucideIcons.circleAlert),
            description: const Text('Something went wrong'),
            action: Button(
              onPressed: () {},
              child: const Text('Retry'),
            ),
          ),
        ),
      );

      expect(_iconFinder(LucideIcons.circleAlert), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders compact variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(const EmptyState.compact(title: Text('No results'))),
      );

      expect(find.text('No results'), findsOneWidget);
      final widget = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(widget.variant, equals(CoreEmptyStateVariant.compact));
    });

    testWidgets('default constructor is normal variant', (tester) async {
      const widget = EmptyState(title: Text('No results'));

      expect(widget.variant, equals(CoreEmptyStateVariant.normal));
    });

    Size boxSize(WidgetTester tester) => tester.getSize(
      find
          .ancestor(
            of: _iconFinder(LucideIcons.inbox),
            matching: find.byType(SizedBox),
          )
          .first,
    );

    for (final (variant, edge) in [
      (CoreEmptyStateVariant.normal, 64.0),
      (CoreEmptyStateVariant.compact, 48.0),
      (CoreEmptyStateVariant.large, 72.0),
    ]) {
      testWidgets('icon box is a ${edge.toInt()} circle for $variant', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            EmptyState(
              variant: variant,
              title: const Text('t'),
              icon: const Icon(LucideIcons.inbox),
            ),
          ),
        );
        expect(boxSize(tester), Size.square(edge));
        final decorated = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: _iconFinder(LucideIcons.inbox),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final deco = decorated.decoration as BoxDecoration;
        expect(deco.borderRadius, isNotNull);
        expect(deco.color, isNotNull);
      });
    }

    testWidgets('success tone tints the box and glyph', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState(
            tone: CoreEmptyStateTone.success,
            title: Text('Done'),
            icon: Icon(LucideIcons.inbox),
          ),
        ),
      );
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('renders icon with custom size via iconStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState(
            title: Text('No results found'),
            icon: Icon(
              LucideIcons.searchX,
              iconStyle: CoreIconStyle(size: _kTestIconSize),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(_iconFinder(LucideIcons.searchX));
      expect(icon.iconStyle?.size, equals(_kTestIconSize));
    });

    testWidgets('renders icon with custom color via iconStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState(
            title: Text('No results found'),
            icon: Icon(
              LucideIcons.searchX,
              iconStyle: CoreIconStyle(color: _kTestColor),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(_iconFinder(LucideIcons.searchX));
      expect(icon.iconStyle?.color, equals(_kTestColor));
    });

    testWidgets('renders with custom minHeight via emptyStateStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState(
            title: Text('No results found'),
            emptyStateStyle: CoreEmptyStateStyle(minHeight: _kTestMinHeight),
          ),
        ),
      );

      final widget = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(widget.emptyStateStyle?.minHeight, equals(_kTestMinHeight));
    });

    testWidgets('renders with custom padding via emptyStateStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState(
            title: Text('No results found'),
            emptyStateStyle: CoreEmptyStateStyle(
              padding: CoreEdgeInsets.all(_kTestPadding),
            ),
          ),
        ),
      );

      final widget = tester.widget<EmptyState>(find.byType(EmptyState));
      expect(
        widget.emptyStateStyle?.padding,
        equals(const CoreEdgeInsets.all(_kTestPadding)),
      );
    });

    testWidgets('respects provided key', (tester) async {
      const testKey = Key('test-empty-state');

      await tester.pumpWidget(
        _buildApp(
          const EmptyState(key: testKey, title: Text('No results found')),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('action button callback fires on tap', (tester) async {
      var buttonTapped = false;

      await tester.pumpWidget(
        _buildApp(
          EmptyState(
            title: const Text('No results found'),
            action: Button(
              onPressed: () {
                buttonTapped = true;
              },
              child: const Text('Clear Filters'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Clear Filters'));
      await tester.pump();

      expect(buttonTapped, isTrue);
    });

    testWidgets('compact renders with icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState.compact(
            title: Text('Empty'),
            icon: Icon(LucideIcons.inbox),
          ),
        ),
      );

      expect(_iconFinder(LucideIcons.inbox), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('compact renders with description', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState.compact(
            title: Text('Empty'),
            description: Text('No items here'),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('No items here'), findsOneWidget);
    });

    testWidgets('compact renders with action', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          EmptyState.compact(
            title: const Text('Empty'),
            action: Button(
              onPressed: () {},
              child: const Text('Add Item'),
            ),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });
  });

  // The title role is a row of `defaultsByVariant`, not a choice the
  // resolver makes — the Figma export reads that table, so a role picked
  // anywhere else reaches the screen and never the canvas.
  group('EmptyState title role', () {
    const title = 'No results';

    // `Text` folds the ambient `DefaultTextStyle` into the span it paints,
    // so this is the size the title actually renders at.
    double? renderedSize(WidgetTester tester) => tester
        .widget<RichText>(
          find.descendant(
            of: find.text(title),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style
        ?.fontSize;

    double? roleSize(WidgetTester tester, CoreTextStyleToken role) =>
        CoreTextStyle.token(
          role,
        ).toValue(theme: Theme.of(tester.element(find.text(title)))).fontSize;

    testWidgets('normal renders the titleMedium size', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState(
            title: Text(title),
          ),
        ),
      );

      expect(
        renderedSize(tester),
        roleSize(tester, CoreTextStyles.titleMedium),
      );
    });

    testWidgets('compact renders the titleSmall size', (tester) async {
      await tester.pumpWidget(
        _buildApp(const EmptyState.compact(title: Text(title))),
      );

      expect(renderedSize(tester), roleSize(tester, CoreTextStyles.titleSmall));
      // The two roles must differ, or the assertion above could not tell
      // them apart.
      expect(
        roleSize(tester, CoreTextStyles.titleSmall),
        isNot(roleSize(tester, CoreTextStyles.titleMedium)),
      );
    });
  });

  // The title states no weight of its own and draws at its role's — semibold
  // for every title role (semibold 600), the rule Card's header and Footer's
  // section title follow too. A caller's weight still replaces it.
  //
  // The Web twin (`coui_web/test/components/display/empty_state_test.dart`)
  // pins the same weights on the emitted class and inline overlay.
  group('EmptyState title weight', () {
    const title = 'No results';

    // The weight the title actually paints at — `Text` folds the ambient
    // `DefaultTextStyle` the widget wraps it in into the span.
    FontWeight? renderedWeight(WidgetTester tester) => tester
        .widget<RichText>(
          find.descendant(
            of: find.text(title),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style
        ?.fontWeight;

    test('no default title style states a weight', () {
      expect(CoreEmptyStateStyle.defaultTitleTextStyle.fontWeight, isNull);
      for (final variant in CoreEmptyStateVariant.values) {
        expect(
          CoreEmptyStateStyle
              .defaultsByVariant[variant]!
              .titleTextStyle
              .fontWeight,
          isNull,
          reason: variant.name,
        );
      }
      // The roles they read are semibold, so the w600 below is the role's.
      expect(
        CoreTypography.coui.titleMedium.fontWeight,
        CoreFontWeight.semiBold,
      );
      expect(
        CoreTypography.coui.titleSmall.fontWeight,
        CoreFontWeight.semiBold,
      );
    });

    for (final variant in CoreEmptyStateVariant.values) {
      testWidgets('${variant.name} renders the role weight w600', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(EmptyState(variant: variant, title: const Text(title))),
        );

        expect(renderedWeight(tester), FontWeight.w600);
      });

      testWidgets('${variant.name}: a titleTextStyle weight still wins', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            EmptyState(
              variant: variant,
              emptyStateStyle: const CoreEmptyStateStyle(
                titleTextStyle: CoreTextStyle(
                  fontWeight: CoreFontWeight.regular,
                ),
              ),
              title: const Text(title),
            ),
          ),
        );

        expect(renderedWeight(tester), FontWeight.w400);
      });
    }
  });

  // `minHeight` is the height of the whole stack, padding included — the
  // Web's `min-height` on a border-box root, and the 240 the design draws.
  // The floor once sat inside the padding, so `normal` stood
  // 240 + 2 × 32 = 304 tall and `large` 240 + 2 × 40 = 320.
  group('EmptyState box height', () {
    // A scroll view gives its child unbounded height — the stack takes the
    // height of its own content, or its floor, instead of filling the host.
    Future<double> heightOf(
      WidgetTester tester, {
      required Widget child,
      double scaling = 1,
    }) async {
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: ThemeData(scaling: scaling),
            child: material.Scaffold(
              body: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: 400, child: child),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(EmptyState)).height;
    }

    for (final variant in [
      CoreEmptyStateVariant.normal,
      CoreEmptyStateVariant.large,
    ]) {
      testWidgets('${variant.name} is the 240 floor, not 240 plus padding', (
        tester,
      ) async {
        expect(
          await heightOf(
            tester,
            child: EmptyState(
              variant: variant,
              title: const Text('Nothing here'),
              icon: const Icon(LucideIcons.inbox),
            ),
          ),
          CoreEmptyStateStyle.defaultMinHeight,
        );
      });

      testWidgets('${variant.name} floor follows the theme scaling', (
        tester,
      ) async {
        expect(
          await heightOf(
            tester,
            scaling: 1.25,
            child: EmptyState(
              variant: variant,
              title: const Text('Nothing here'),
            ),
          ),
          CoreEmptyStateStyle.defaultMinHeight * 1.25,
        );
      });
    }

    // The first `Column` under an `EmptyState` is its content stack — icon,
    // title block and action; the padding is everything outside it.
    double contentHeight(WidgetTester tester) => tester
        .getSize(
          find
              .descendant(
                of: find.byType(EmptyState),
                matching: find.byType(Column),
              )
              .first,
        )
        .height;

    testWidgets('a stack taller than the floor grows by its padding', (
      tester,
    ) async {
      final height = await heightOf(
        tester,
        child: const EmptyState(
          title: Text('Nothing here'),
          action: SizedBox(height: 260, width: 40),
        ),
      );
      // A 260 action alone overruns the 240 floor once the 2 × 32 padding of
      // the normal variant is added around the content.
      expect(height, greaterThan(CoreEmptyStateStyle.defaultMinHeight));
      expect(height - contentHeight(tester), 64);
    });

    testWidgets('compact keeps its content height — it states no floor', (
      tester,
    ) async {
      final height = await heightOf(
        tester,
        child: const EmptyState.compact(title: Text('Nothing here')),
      );
      expect(
        CoreEmptyStateStyle
            .defaultsByVariant[CoreEmptyStateVariant.compact]!
            .minHeight,
        0,
      );
      // The compact padding is 2 × 24 around the content, nothing more.
      expect(height - contentHeight(tester), 48);
      expect(height, lessThan(CoreEmptyStateStyle.defaultMinHeight));
    });

    testWidgets('a minHeight override is the box height too', (tester) async {
      expect(
        await heightOf(
          tester,
          child: const EmptyState(
            title: Text('Nothing here'),
            emptyStateStyle: CoreEmptyStateStyle(minHeight: _kTestMinHeight),
          ),
        ),
        _kTestMinHeight,
      );
    });

    testWidgets('a bounded host is still filled', (tester) async {
      await tester.pumpWidget(
        _buildApp(const EmptyState(title: Text('Nothing here'))),
      );
      final host = tester.getSize(find.byType(material.Scaffold)).height;
      expect(tester.getSize(find.byType(EmptyState)).height, host);
    });
  });

  // #6468: compact keeps the ~0.44 icon/box ratio (20 in 48), sits the
  // title 6 above its sentence, steps the action 16 off, and reads the
  // sentence one role smaller than `normal`.
  group('EmptyState compact redesign (#6468)', () {
    testWidgets('glyph 20, gaps 12 / 6 / 16, description bodySmall', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const EmptyState.compact(
            icon: Icon(LucideIcons.inbox),
            title: Text('T'),
            description: Text('D'),
            action: SizedBox(key: ValueKey('action'), height: 10),
          ),
        ),
      );
      expect(tester.getSize(_iconFinder(LucideIcons.inbox)).width, 20);
      final box = tester.getRect(
        find
            .ancestor(
              of: _iconFinder(LucideIcons.inbox),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      final title = tester.getRect(find.text('T'));
      final desc = tester.getRect(find.text('D'));
      final action = tester.getRect(find.byKey(const ValueKey('action')));
      expect(title.top - box.bottom, closeTo(12, 0.5));
      expect(desc.top - title.bottom, closeTo(6, 0.5));
      expect(action.top - desc.bottom, closeTo(16, 0.5));
      final descStyle = tester
          .widget<RichText>(
            find.descendant(
              of: find.text('D'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;
      expect(descStyle.fontSize, CoreTypography.coui.bodySmall.fontSize);
    });
  });
}
