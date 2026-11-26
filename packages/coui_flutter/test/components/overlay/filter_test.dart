import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kItems = <CoreFilterItem<String, material.Widget>>[
  CoreFilterItem(value: 'svelte', label: 'Svelte'),
  CoreFilterItem(value: 'vue', label: 'Vue'),
  CoreFilterItem(value: 'react', label: 'React'),
];

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: material.Center(child: child)),
  ),
);

/// Finds the *visible* label `Text` — each item also renders an
/// invisible selected-typography twin (width reservation) above it in
/// the stack, so `find.text(label)` matches two widgets; the visible
/// one is the last stack child.
Finder _visibleLabel(String label) => find.text(label).last;

TextStyle _labelStyleOf(WidgetTester tester, String label) {
  final text = tester.widget<material.Text>(_visibleLabel(label));
  return text.style!;
}

/// The segment box (`AnimatedContainer`) that paints the item's fill,
/// located from its visible label.
Finder _segmentOf(String label) => find
    .ancestor(
      of: _visibleLabel(label),
      matching: find.byType(material.AnimatedContainer),
    )
    .first;

const _kGridIconKey = material.ValueKey<String>('filter-icon-grid');
const _kListIconKey = material.ValueKey<String>('filter-icon-list');

void main() {
  group('Filter', () {
    testWidgets('renders one button per item', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
          ),
        ),
      );

      // Two `Text`s per label — the visible one plus the invisible
      // selected-typography twin that reserves the semibold width.
      expect(find.text('Svelte'), findsNWidgets(2));
      expect(find.text('Vue'), findsNWidgets(2));
      expect(find.text('React'), findsNWidgets(2));
    });

    testWidgets('selected item uses the selected label text style', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'vue',
            items: _kItems,
            onValueChanged: (_) {},
          ),
        ),
      );

      final selected = _labelStyleOf(tester, 'Vue');
      final unselected = _labelStyleOf(tester, 'Svelte');

      // Resolver folds the per-state typography: selected gets the
      // semibold weight, unselected stays at the typography base weight.
      expect(selected.fontWeight, material.FontWeight.w600);
      expect(selected.color, isNot(unselected.color));
    });

    testWidgets('invokes onValueChanged with the tapped value', (tester) async {
      String? changed;
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (value) => changed = value,
          ),
        ),
      );

      await tester.tap(_visibleLabel('React'));
      final _ = await tester.pumpAndSettle();

      expect(changed, 'react');
    });

    testWidgets('item widths stay constant when selection moves', (
      tester,
    ) async {
      Size itemSize(String label) => tester.getSize(
        find
            .ancestor(
              of: _visibleLabel(label),
              matching: find.byType(material.AnimatedContainer),
            )
            .first,
      );

      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
          ),
        ),
      );
      final before = _kItems.map((i) => itemSize(i.label)).toList();

      // Move the selection — the invisible selected-typography twin
      // reserves the semibold width, so no item may resize.
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'react',
            items: _kItems,
            onValueChanged: (_) {},
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      final after = _kItems.map((i) => itemSize(i.label)).toList();

      expect(after, before);
    });

    testWidgets('the reset button sits after the last segment', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
            onReset: () {},
            showResetButton: true,
          ),
        ),
      );
      final reset = tester.getRect(find.bySemanticsLabel('Reset filter'));
      final last = tester.getRect(_segmentOf('React'));
      expect(reset.left, greaterThanOrEqualTo(last.right));
    });

    testWidgets(
      'the hairline sits 6 from the last segment and 2 from the reset button',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            Filter<String>(
              groupValue: 'svelte',
              items: _kItems,
              onValueChanged: (_) {},
              onReset: () {},
              showResetButton: true,
            ),
          ),
        );
        final last = tester.getRect(_segmentOf('React'));
        final hairline = tester.getRect(find.byType(Divider));
        final reset = tester.getRect(find.bySemanticsLabel('Reset filter'));

        expect(
          hairline.left - last.right,
          CoreFilterStyle.defaultDividerLeadingSpacing,
        );
        expect(
          reset.left - hairline.right,
          CoreFilterStyle.defaultTrailingSpacing,
        );
      },
    );

    testWidgets('the leading distance is its own field, not the item gap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
            onReset: () {},
            showResetButton: true,
            filterStyle: const CoreFilterStyle(
              dividerLeadingSpacing: CoreSpace.space12,
              trailingSpacing: CoreSpace.space4,
            ),
          ),
        ),
      );
      final last = tester.getRect(_segmentOf('React'));
      final hairline = tester.getRect(find.byType(Divider));
      final reset = tester.getRect(find.bySemanticsLabel('Reset filter'));
      expect(hairline.left - last.right, 12);
      expect(reset.left - hairline.right, 4);
    });

    testWidgets('a disabled filter draws the reset glyph in disabledContent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            enabled: false,
            onValueChanged: (_) {},
            onReset: () {},
            showResetButton: true,
          ),
        ),
      );
      final glyph = find.descendant(
        of: find.bySemanticsLabel('Reset filter'),
        matching: find.byType(Icon),
      );
      final context = tester.element(glyph);
      final expected = Theme.of(context).colorScheme
          .resolve(const CoreColor.token(CoreColors.disabledContent))
          .toValue();
      expect(IconTheme.of(context).color, expected);
    });

    testWidgets('an enabled filter draws the reset glyph in onSurfaceVariant', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
            onReset: () {},
            showResetButton: true,
          ),
        ),
      );
      final glyph = find.descendant(
        of: find.bySemanticsLabel('Reset filter'),
        matching: find.byType(Icon),
      );
      final context = tester.element(glyph);
      final expected = Theme.of(context).colorScheme
          .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
          .toValue();
      expect(IconTheme.of(context).color, expected);
    });

    testWidgets('the hairline is outlineVariant enabled, disabledOutline '
        'disabled', (tester) async {
      Future<CoreColor?> hairline({required bool enabled}) async {
        await tester.pumpWidget(
          _buildApp(
            Filter<String>(
              groupValue: 'svelte',
              items: _kItems,
              enabled: enabled,
              onValueChanged: (_) {},
              onReset: () {},
              showResetButton: true,
            ),
          ),
        );
        return tester.widget<Divider>(find.byType(Divider)).dividerStyle!.color;
      }

      expect(
        await hairline(enabled: true),
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        await hairline(enabled: false),
        const CoreColor.token(CoreColors.disabledOutline),
      );
    });

    testWidgets('disabledDividerColor overrides the disabled hairline', (
      tester,
    ) async {
      const custom = CoreColor.token(CoreColors.primary);
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            enabled: false,
            onValueChanged: (_) {},
            onReset: () {},
            showResetButton: true,
            filterStyle: const CoreFilterStyle(disabledDividerColor: custom),
          ),
        ),
      );
      expect(
        tester.widget<Divider>(find.byType(Divider)).dividerStyle!.color,
        custom,
      );
    });

    testWidgets('reset button is shown only when enabled with a handler', (
      tester,
    ) async {
      var didReset = false;
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
            onReset: () => didReset = true,
            showResetButton: true,
          ),
        ),
      );

      // The reset button renders a `Icon(LucideIcons.x)` (SVG) rather
      // than a Material `Icon`, so it is located by its semantics label.
      final resetFinder = find.bySemanticsLabel('Reset filter');
      expect(resetFinder, findsOneWidget);

      await tester.tap(resetFinder);
      final _ = await tester.pumpAndSettle();

      expect(didReset, isTrue);
    });

    testWidgets('hides reset button when showResetButton is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
            onReset: () {},
          ),
        ),
      );

      expect(find.bySemanticsLabel('Reset filter'), findsNothing);
    });

    testWidgets('filterStyle label override flows through the resolver', (
      tester,
    ) async {
      const overrideColor = CoreColor.fromRGB(255, 0, 0);
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
            filterStyle: const CoreFilterStyle(
              // The deprecated flat field is what this test pins to still
              // reach both states of the composed group.
              // ignore: deprecated_member_use, the fold of the old field is under test.
              labelTextStyle: CoreTextStyle(color: overrideColor),
            ),
          ),
        ),
      );

      // The per-instance label colour override wins on both states and is
      // resolved to a concrete Flutter Color by the resolver.
      final selected = _labelStyleOf(tester, 'Svelte');
      final unselected = _labelStyleOf(tester, 'Vue');
      expect(selected.color, const material.Color(0xFFFF0000));
      expect(unselected.color, const material.Color(0xFFFF0000));
    });

    testWidgets(
      'label-only segment is text width + 20 (2 + 8 · text · 8 + 2)',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            Filter<String>(
              groupValue: 'svelte',
              items: _kItems,
              onValueChanged: (_) {},
            ),
          ),
        );

        // Both label twins share the advance width in the test font; take
        // the wider one so a weight-dependent advance cannot skew the sum.
        final textWidth = find
            .text('Vue')
            .evaluate()
            .map((e) => (e.renderObject! as material.RenderBox).size.width)
            .reduce((a, b) => a > b ? a : b);
        final segment = tester.getSize(_segmentOf('Vue'));

        // itemPadding (2) + labelPadding (8) + text + labelPadding (8)
        // + itemPadding (2) at the default `md` size.
        expect(segment.width, moreOrLessEquals(textWidth + 20));
        expect(segment.height, CoreToggleGroupStyle.defaultItemHeight);
      },
    );

    testWidgets('icon-only segment renders as a 32×32 square', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: const [
              CoreFilterItem(value: 'svelte', label: 'Svelte'),
              CoreFilterItem(
                value: 'grid',
                label: 'Grid',
                icon: Icon(LucideIcons.layoutGrid, key: _kGridIconKey),
                showLabel: false,
              ),
            ],
            onValueChanged: (_) {},
          ),
        ),
      );

      // No painted label — the accessible name still comes from
      // `Semantics(label:)`.
      expect(find.text('Grid'), findsNothing);
      expect(find.bySemanticsLabel('Grid'), findsOneWidget);

      // The ambient icon size is the 16-px slot default, so the segment
      // is itemPadding (8) + 16 + itemPadding (8) on both axes.
      expect(tester.getSize(find.byKey(_kGridIconKey)), const Size(16, 16));
      final segment = tester.getSize(
        find
            .ancestor(
              of: find.byKey(_kGridIconKey),
              matching: find.byType(material.AnimatedContainer),
            )
            .first,
      );
      expect(segment, const Size(32, 32));
    });

    testWidgets('icon colour follows the selection state', (tester) async {
      const items = [
        CoreFilterItem(
          value: 'list',
          label: 'List',
          icon: Icon(LucideIcons.list, key: _kListIconKey),
        ),
        CoreFilterItem(
          value: 'grid',
          label: 'Grid',
          icon: Icon(LucideIcons.layoutGrid, key: _kGridIconKey),
        ),
      ];
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'grid',
            items: items,
            onValueChanged: (_) {},
          ),
        ),
      );

      final gridContext = tester.element(find.byKey(_kGridIconKey));
      final scheme = Theme.of(gridContext).colorScheme;
      final selectedIconColor = scheme
          .resolve(CoreToggleGroupStyle.defaultSelectedIconStyle.color!)
          .toValue();
      final unselectedIconColor = scheme
          .resolve(CoreToggleGroupStyle.defaultIconStyle.color!)
          .toValue();

      // The per-state `CoreIconStyle` reaches the caller-supplied icon
      // through the ambient `IconTheme` the segment merges above it.
      expect(IconTheme.of(gridContext).color, selectedIconColor);
      expect(
        IconTheme.of(tester.element(find.byKey(_kListIconKey))).color,
        unselectedIconColor,
      );
      expect(selectedIconColor, isNot(unselectedIconColor));

      // Move the selection — the colours swap with it.
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'list',
            items: items,
            onValueChanged: (_) {},
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(
        IconTheme.of(tester.element(find.byKey(_kGridIconKey))).color,
        unselectedIconColor,
      );
      expect(
        IconTheme.of(tester.element(find.byKey(_kListIconKey))).color,
        selectedIconColor,
      );
    });

    testWidgets('reset affordance is a ghost · sm · square Button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
            onReset: () {},
            showResetButton: true,
          ),
        ),
      );

      final button = tester.widget<Button>(find.byType(Button));
      expect(button.variant, CoreButtonVariant.ghost);
      expect(button.size, CoreComponentSize.sm);
      expect(button.shape, CoreButtonShape.square);
      expect(tester.getSize(find.byType(Button)), const Size(32, 32));
    });

    testWidgets(
      'the segments are a composed ToggleGroup 40 tall (4 + 32 + 4)',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            Filter<String>(
              groupValue: 'svelte',
              items: _kItems,
              onValueChanged: (_) {},
            ),
          ),
        );

        expect(find.byType(ToggleGroup<String>), findsOneWidget);
        expect(tester.getSize(find.byType(Filter<String>)).height, 40);
      },
    );

    testWidgets('size hands the group its size and sizes the reset row', (
      tester,
    ) async {
      for (final (size, bar, resetSide, glyph, hairline) in [
        (CoreComponentSize.md, 40.0, 32.0, 16.0, 16.0),
        (CoreComponentSize.sm, 32.0, 26.0, 14.0, 14.0),
      ]) {
        await tester.pumpWidget(
          _buildApp(
            Filter<String>(
              groupValue: 'svelte',
              items: _kItems,
              onValueChanged: (_) {},
              size: size,
              onReset: () {},
              showResetButton: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ToggleGroup<String>>(find.byType(ToggleGroup<String>))
              .size,
          size,
        );
        expect(
          tester.getSize(find.byType(Filter<String>)).height,
          bar,
          reason: '$size',
        );
        final reset = tester.getSize(find.byType(Button));
        expect(reset.width, resetSide, reason: '$size');
        expect(reset.height, resetSide, reason: '$size');
        expect(
          tester
              .getSize(
                find.descendant(
                  of: find.byType(Button),
                  matching: find.byType(Icon),
                ),
              )
              .width,
          glyph,
          reason: '$size',
        );
        expect(
          tester.getSize(find.byType(Divider)).height,
          hairline,
          reason: '$size',
        );
      }
    });

    testWidgets('size defaults to md', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.widget<Filter<String>>(find.byType(Filter<String>)).size,
        CoreComponentSize.md,
      );
    });

    testWidgets('the hairline shows only while the reset button does', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(Divider), findsNothing);

      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
            onReset: () {},
            showResetButton: true,
          ),
        ),
      );
      // 1 px wide, 16 px long, between the last segment and the reset button.
      final divider = tester.getRect(find.byType(Divider));
      expect(divider.width, 1);
      expect(divider.height, 16);
      final last = tester.getRect(_segmentOf('React'));
      final reset = tester.getRect(find.byType(Button));
      expect(divider.left, greaterThanOrEqualTo(last.right));
      expect(divider.right, lessThanOrEqualTo(reset.left));
    });

    testWidgets('the chosen segment carries the shared toggle shadow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (_) {},
          ),
        ),
      );

      BoxDecoration decorationOf(String label) =>
          tester
                  .widget<material.AnimatedContainer>(_segmentOf(label))
                  .decoration!
              as BoxDecoration;
      expect(decorationOf('Svelte').boxShadow, isNotEmpty);
      expect(decorationOf('Vue').boxShadow, isEmpty);
    });

    testWidgets('a disabled filter ignores taps and flattens the chosen face', (
      tester,
    ) async {
      String? tapped;
      var resets = 0;
      await tester.pumpWidget(
        _buildApp(
          Filter<String>(
            groupValue: 'svelte',
            items: _kItems,
            onValueChanged: (v) => tapped = v,
            onReset: () => resets++,
            showResetButton: true,
            enabled: false,
          ),
        ),
      );

      await tester.tap(_visibleLabel('Vue'));
      await tester.tap(find.byType(Button));
      expect(tapped, isNull);
      expect(resets, 0);
      final decoration =
          tester
                  .widget<material.AnimatedContainer>(_segmentOf('Svelte'))
                  .decoration!
              as BoxDecoration;
      expect(decoration.boxShadow, isEmpty);
    });
  });

  group('Filter fillWidth', () {
    testWidgets('the track takes the parent width and the segments split it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.SizedBox(
            width: 350,
            child: Filter<String>(
              groupValue: 'svelte',
              items: _kItems,
              onValueChanged: (_) {},
              fillWidth: true,
            ),
          ),
        ),
      );

      expect(
        tester
            .widget<ToggleGroup<String>>(find.byType(ToggleGroup<String>))
            .fillWidth,
        isTrue,
      );
      final track = tester.getRect(find.byType(Filter<String>));
      expect(track.width, 350);
      final segments = [
        for (final item in _kItems) tester.getRect(_segmentOf(item.label)),
      ];
      // Equal shares, whatever each label's own width.
      for (final segment in segments) {
        expect(segment.width, closeTo(segments.first.width, 0.01));
      }
      // Edge to edge inside the same inset on both sides — a hugging row
      // would leave the slack after the last segment.
      expect(
        track.right - segments.last.right,
        closeTo(segments.first.left - track.left, 0.01),
      );
      // Each label stays centred in its share.
      final label = tester.getRect(_visibleLabel('Vue'));
      expect(label.center.dx, closeTo(segments[1].center.dx, 0.5));
    });

    testWidgets(
      'with the reset button the segments split what the trailing row leaves',
      (tester) async {
        // Wide enough that an equal share still holds the widest label —
        // the test font draws every glyph a full em wide.
        await tester.pumpWidget(
          _buildApp(
            material.SizedBox(
              width: 420,
              child: Filter<String>(
                groupValue: 'svelte',
                items: _kItems,
                onValueChanged: (_) {},
                onReset: () {},
                showResetButton: true,
                fillWidth: true,
              ),
            ),
          ),
        );

        final track = tester.getRect(find.byType(Filter<String>));
        expect(track.width, 420);
        final segments = [
          for (final item in _kItems) tester.getRect(_segmentOf(item.label)),
        ];
        for (final segment in segments) {
          expect(segment.width, closeTo(segments.first.width, 0.01));
        }
        // The trailing row keeps its own size and spacing and closes the
        // track inside the same inset the first segment opens it with.
        final hairline = tester.getRect(find.byType(Divider));
        final reset = tester.getRect(find.byType(Button));
        expect(reset.width, 32);
        expect(reset.height, 32);
        expect(
          hairline.left - segments.last.right,
          closeTo(CoreFilterStyle.defaultDividerLeadingSpacing, 0.01),
        );
        expect(
          reset.left - hairline.right,
          closeTo(CoreFilterStyle.defaultTrailingSpacing, 0.01),
        );
        expect(
          track.right - reset.right,
          closeTo(segments.first.left - track.left, 0.01),
        );
      },
    );

    testWidgets('defaults to false: the track hugs its segments', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.SizedBox(
            width: 350,
            child: material.Align(
              alignment: material.Alignment.centerLeft,
              child: Filter<String>(
                groupValue: 'svelte',
                items: _kItems,
                onValueChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        tester.widget<Filter<String>>(find.byType(Filter<String>)).fillWidth,
        isFalse,
      );
      expect(
        tester
            .widget<ToggleGroup<String>>(find.byType(ToggleGroup<String>))
            .fillWidth,
        isFalse,
      );
      // Offered 350, it takes only what its segments need.
      expect(tester.getSize(find.byType(Filter<String>)).width, lessThan(350));
    });

    test('copyWith and the style chain keep fillWidth', () {
      final filter = Filter<String>(
        groupValue: 'svelte',
        items: _kItems,
        onValueChanged: (_) {},
        fillWidth: true,
      );
      expect(filter.copyWith().fillWidth, isTrue);
      expect(filter.radius16.primary.fillWidth, isTrue);
      expect(filter.copyWith(fillWidth: false).fillWidth, isFalse);
    });
  });
}
