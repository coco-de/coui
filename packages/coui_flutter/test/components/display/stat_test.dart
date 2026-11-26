import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

/// The colour [token] resolves to under the harness theme.
Color _ink(WidgetTester tester, CoreColorToken token) => Theme.of(
  tester.element(find.byType(Stat).first),
).colorScheme.resolve(CoreColor.token(token)).toValue();

/// The card box the composed `OutlinedContainer` paints — its face and
/// its border, read off the rendered decoration rather than the style
/// handed to it. Scoped to the stat's subtree.
BoxDecoration _cardBox(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(of: find.byType(Stat), matching: find.byType(Container)),
    )
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((d) => d.border != null);

/// The alphabetic baseline of the text drawn for [finder], in global
/// coordinates.
double _baseline(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderBox>(
    find.descendant(of: finder, matching: find.byType(RichText)),
  );
  return paragraph.localToGlobal(Offset.zero).dy +
      paragraph.getDryBaseline(
        paragraph.constraints,
        TextBaseline.alphabetic,
      )!;
}

void main() {
  group('Stat variant', () {
    testWidgets('filled is a surfaceContainerLow face, no line', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Stat(label: 'Users', value: '128', variant: .filled),
        ),
      );

      final box = _cardBox(tester);
      expect(box.color, _ink(tester, CoreColors.surfaceContainerLow));
      final border = box.border! as Border;
      expect(border.top.width, 0);
      expect(border.top.color.a, 0);
    });

    testWidgets('outlined is the default — page face, 1px outline-variant', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const Stat(label: 'Users', value: '128')),
      );

      expect(
        tester.widget<Stat>(find.byType(Stat)).variant,
        CoreStatVariant.outlined,
      );

      final box = _cardBox(tester);
      expect(box.color, _ink(tester, CoreColors.surface));
      final border = box.border! as Border;
      expect(border.top.width, CoreStrokeWidth.stroke1);
      expect(border.top.color, _ink(tester, CoreColors.outlineVariant));
    });

    testWidgets('a theme variantStyles entry retunes only its variant', (
      tester,
    ) async {
      const themed = CoreColor.token(CoreColors.primaryContainer);
      await tester.pumpWidget(
        const material.MaterialApp(
          home: Theme(
            data: ThemeData(
              coreComponentTheme: CoreComponentTheme(
                stat: CoreStatTheme(
                  variantStyles: {
                    CoreStatVariant.filled: CoreStatStyle(
                      backgroundColor: themed,
                    ),
                  },
                ),
              ),
            ),
            child: Column(
              children: [
                Stat(label: 'Filled', value: '1', variant: .filled),
                Stat(label: 'Outlined', value: '2'),
              ],
            ),
          ),
        ),
      );

      final faces = tester
          .widgetList<OutlinedContainer>(find.byType(OutlinedContainer))
          .map((c) => c.containerStyle!.backgroundColor)
          .toList();
      expect(faces.first, themed);
      expect(faces.last!.token, CoreColors.surface);
    });
  });

  group('Stat size', () {
    testWidgets('sm is the compact card — 14 / 16 padding, titleLarge figure', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Stat(label: 'Users', value: '128', size: .sm),
        ),
      );

      final container = tester.widget<OutlinedContainer>(
        find.byType(OutlinedContainer),
      );
      expect(
        container.containerStyle!.padding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space16,
          vertical: CoreSpace.space14,
        ),
      );
      final value = tester.widget<Text>(find.text('128')).style!;
      expect(value.fontSize, CoreTypography.coui.titleLarge.fontSize);
      // The role's own weight (SemiBold), not a Bold overlay.
      expect(value.fontWeight, FontWeight.w600);
      final label = tester.widget<Text>(find.text('Users')).style!;
      expect(label.fontSize, CoreTypography.coui.bodySmall.fontSize);
      expect(label.fontWeight, FontWeight.w400);
    });

    testWidgets('md is the default and keeps 20 / 24 padding', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Stat(label: 'Users', value: '128')),
      );
      expect(tester.widget<Stat>(find.byType(Stat)).size, CoreComponentSize.md);
      final container = tester.widget<OutlinedContainer>(
        find.byType(OutlinedContainer),
      );
      expect(container.containerStyle!.padding, CoreStatStyle.defaultPadding);
    });
  });

  group('Stat value row', () {
    testWidgets('the unit sits on the value baseline, 4 after it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const Stat(label: 'Subscribers', value: '12,480', unit: '명')),
      );

      final value = find.text('12,480');
      final unit = find.text('명');
      expect(
        _baseline(tester, unit),
        moreOrLessEquals(_baseline(tester, value), epsilon: 0.01),
      );
      expect(
        tester.getTopLeft(unit).dx - tester.getTopRight(value).dx,
        moreOrLessEquals(CoreSpace.space4),
      );
      // The unit is the smaller line, so its top sits below the value's.
      expect(
        tester.getTopLeft(unit).dy,
        greaterThan(tester.getTopLeft(value).dy),
      );
    });

    testWidgets('the unit is titleMedium at 500 in the second text tier', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const Stat(label: 'Subscribers', value: '12,480', unit: '명')),
      );

      final style = tester.widget<Text>(find.text('명')).style!;
      expect(style.fontSize, CoreTypography.coui.titleMedium.fontSize);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, _ink(tester, CoreColors.onSurfaceVariant));
      // The value stays the 700 figure beside it.
      final value = tester.widget<Text>(find.text('12,480')).style!;
      expect(value.fontWeight, FontWeight.w700);
      expect(value.color, _ink(tester, CoreColors.onSurface));
    });

    testWidgets('a null value draws an em dash in the second text tier', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const Stat(label: 'Pending', unit: '명')),
      );

      final dash = find.text(CoreStatContract.defaultEmptyValue);
      expect(dash, findsOneWidget);
      final style = tester.widget<Text>(dash).style!;
      // The value's role, the empty-value colour.
      expect(style.fontSize, CoreTypography.coui.headlineLarge.fontSize);
      expect(style.color, _ink(tester, CoreColors.onSurfaceVariant));
      expect(style.color, isNot(_ink(tester, CoreColors.onSurface)));
      // No unit beside the dash: a unit qualifies a figure.
      expect(find.text('명'), findsNothing);
    });

    testWidgets('a long value wraps inside a narrow card', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: SizedBox(
              width: 160,
              child: Stat(
                label: 'Revenue',
                value: '1,234,567,890',
                unit: '원',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final value = tester.getSize(find.text('1,234,567,890'));
      expect(
        value.height,
        greaterThan(CoreTypography.coui.headlineLarge.fontSize! * 1.5),
      );
    });

    testWidgets('a wrapped value keeps its unit on the first line', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: SizedBox(
              width: 160,
              child: Stat(
                label: 'Revenue',
                value: '1,234,567,890',
                unit: '원',
              ),
            ),
          ),
        ),
      );

      final value = find.text('1,234,567,890');
      final unit = find.text('원');
      final fontSize = CoreTypography.coui.headlineLarge.fontSize!;
      // The row aligns the first baselines, so the unit rides the value's
      // first line — to the right of its box, not at the end of the last.
      expect(tester.getSize(value).height, greaterThan(fontSize * 1.5));
      expect(
        _baseline(tester, unit),
        moreOrLessEquals(_baseline(tester, value), epsilon: 0.01),
      );
      expect(
        tester.getBottomLeft(unit).dy,
        lessThan(tester.getBottomLeft(value).dy - fontSize),
      );
      expect(
        tester.getTopLeft(unit).dx - tester.getTopRight(value).dx,
        moreOrLessEquals(CoreSpace.space4),
      );
    });

    testWidgets('lays out under an unbounded width', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SingleChildScrollView(
            scrollDirection: .horizontal,
            child: Stat(label: 'Revenue', value: '45,231', unit: '원'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('원'), findsOneWidget);
    });
  });

  group('Stat description', () {
    testWidgets('reads last, bodySmall (Regular) in the third text tier', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Stat(
            label: 'Revenue',
            value: '45,231',
            change: '+20.1%',
            changeType: .positive,
            description: 'Last 30 days',
          ),
        ),
      );

      final description = find.text('Last 30 days');
      final style = tester.widget<Text>(description).style!;
      expect(style.fontSize, CoreTypography.coui.bodySmall.fontSize);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, _ink(tester, CoreColors.onSurfaceSubtle));
      // Row order: label → value → change → description, a 10 gap apart.
      final change = find.text('+20.1%');
      expect(
        tester.getTopLeft(description).dy - tester.getBottomLeft(change).dy,
        moreOrLessEquals(CoreSpace.space10),
      );
      // No trend arrow of its own: the only arrow is the change row's.
      expect(find.text('\u{2191}'), findsOneWidget);
    });

    testWidgets('is absent when not given', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Stat(label: 'Revenue', value: '45,231')),
      );

      // Label + value only: two text lines in the card.
      expect(
        find.descendant(of: find.byType(Stat), matching: find.byType(Text)),
        findsNWidgets(2),
      );
    });
  });

  group('Stat new style slots', () {
    testWidgets('statStyle overrides reach the rendered rows', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Column(
            children: [
              Stat(
                label: 'A',
                value: '1',
                unit: 'u',
                description: 'd',
                statStyle: CoreStatStyle(
                  unitColor: CoreColor.token(CoreColors.primary),
                  descriptionColor: CoreColor.token(CoreColors.error),
                  valueUnitGapStyle: CoreGapStyle(size: CoreSpace.space12),
                  descriptionTextStyle: CoreTextStyle.token(
                    CoreTextStyles.labelSmall,
                  ),
                ),
              ),
              Stat(
                label: 'B',
                statStyle: CoreStatStyle(
                  emptyValueColor: CoreColor.token(CoreColors.error),
                ),
              ),
            ],
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.text('u')).style!.color,
        _ink(tester, CoreColors.primary),
      );
      final description = tester.widget<Text>(find.text('d')).style!;
      expect(description.color, _ink(tester, CoreColors.error));
      expect(description.fontSize, CoreTypography.coui.labelSmall.fontSize);
      expect(
        tester.getTopLeft(find.text('u')).dx -
            tester.getTopRight(find.text('1')).dx,
        moreOrLessEquals(CoreSpace.space12),
      );
      expect(
        tester
            .widget<Text>(find.text(CoreStatContract.defaultEmptyValue))
            .style!
            .color,
        _ink(tester, CoreColors.error),
      );
    });
  });

  group('Stat', () {
    testWidgets('valueTextStyle displaySmall uses the display role', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Stat(
            label: 'Users',
            value: '128',
            statStyle: CoreStatStyle(
              valueTextStyle: CoreTextStyle.token(CoreTextStyles.displaySmall),
            ),
          ),
        ),
      );

      final value = tester.widget<Text>(find.text('128'));
      expect(value.style?.fontSize, CoreTypography.coui.displaySmall.fontSize);
      expect(
        value.style?.fontSize,
        isNot(CoreTypography.coui.headlineLarge.fontSize),
      );
    });

    testWidgets('style slots zero the card border and set radius and fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Stat(
            label: 'Users',
            value: '128',
            statStyle: CoreStatStyle(
              borderWidth: CoreStrokeWidth.stroke0,
              borderRadius: CoreBorderRadius.zero,
              backgroundColor: CoreColor.transparent,
            ),
          ),
        ),
      );

      final box = tester.widget<OutlinedContainer>(
        find.byType(OutlinedContainer),
      );
      expect(box.containerStyle?.borderWidth, CoreStrokeWidth.stroke0);
      expect(
        box.containerStyle?.borderRadius,
        CoreBorderRadius.zero,
      );
      expect(box.containerStyle?.backgroundColor, CoreColor.transparent);
    });

    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Stat(label: 'Total Revenue', value: r'$45,231.89')),
      );

      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text(r'$45,231.89'), findsOneWidget);
    });

    testWidgets('renders change row when change + changeType supplied', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Stat(
            label: 'Revenue',
            value: r'$45,231',
            change: '+20.1%',
            changeType: .positive,
          ),
        ),
      );

      expect(find.text('+20.1%'), findsOneWidget);
      // Up-arrow glyph for the positive change.
      expect(find.text('\u{2191}'), findsOneWidget);
    });

    testWidgets('omits change row when changeType is null', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Stat(label: 'Users', value: '1,024', change: '+5')),
      );

      // No glyph rendered when changeType is null (change row is gated on
      // both `change` and `changeType` being non-null).
      expect(find.text('\u{2191}'), findsNothing);
      expect(find.text('\u{2193}'), findsNothing);
      expect(find.text('\u{2192}'), findsNothing);
    });

    testWidgets('selects per-change-type colour (positive ≠ negative)', (
      tester,
    ) async {
      // The resolver pre-composes three change text styles
      // (positive/negative/neutral); the widget selects via a switch. Two
      // Stats with different change types must paint different colours
      // on the change text.
      await tester.pumpWidget(
        _buildApp(
          const Column(
            children: [
              Stat(
                label: 'Up',
                value: '1',
                change: '+1',
                changeType: .positive,
              ),
              Stat(
                label: 'Down',
                value: '2',
                change: '-1',
                changeType: .negative,
              ),
            ],
          ),
        ),
      );

      final positiveText = tester.widget<Text>(find.text('+1'));
      final negativeText = tester.widget<Text>(find.text('-1'));

      expect(positiveText.style, isNotNull);
      expect(negativeText.style, isNotNull);
      expect(
        positiveText.style!.color,
        isNot(equals(negativeText.style!.color)),
      );
    });

    testWidgets('label / value carry resolved typography colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const Stat(label: 'Metric', value: '42')),
      );

      final labelText = tester.widget<Text>(find.text('Metric'));
      final valueText = tester.widget<Text>(find.text('42'));

      // Token-backed roles materialise to real text styles with colours.
      expect(labelText.style?.color, isNotNull);
      expect(valueText.style?.color, isNotNull);
      // Distinct typography roles → distinct font sizes (labelLarge label vs
      // headlineLarge value).
      expect(
        labelText.style?.fontSize,
        isNot(equals(valueText.style?.fontSize)),
      );
    });

    testWidgets('per-instance statStyle override reaches the card', (
      tester,
    ) async {
      const overrideRadius = CoreBorderRadius.all(CoreRadius.radius4);
      await tester.pumpWidget(
        _buildApp(
          const Stat(
            label: 'Styled',
            value: '7',
            statStyle: CoreStatStyle(borderRadius: overrideRadius),
          ),
        ),
      );

      // The override flows through resolveStat → ResolvedStat →
      // OutlinedContainer's `containerStyle` (no widget-side merge). The
      // card box is composed via `OutlinedContainer`, so the assertion
      // reads that composed widget's contract input rather than reaching
      // into its own internal `Container`/`BoxDecoration` — that is
      // `OutlinedContainer`'s own test's responsibility.
      final outlinedContainer = tester.widget<OutlinedContainer>(
        find.descendant(
          of: find.byType(Stat),
          matching: find.byType(OutlinedContainer),
        ),
      );
      expect(
        outlinedContainer.containerStyle?.borderRadius,
        equals(overrideRadius),
      );
    });
  });
}
