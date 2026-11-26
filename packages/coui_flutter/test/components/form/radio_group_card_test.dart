// The radio item's description line and the `card` variant's tile, read off
// what the widget actually builds — text styles, the tile's container and
// padding, the state layer's extent, and where the focus ring sits.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child, {double scaling = 1}) => material.MaterialApp(
  home: Theme(
    data: ThemeData(scaling: scaling),
    child: child,
  ),
);

Color _token(WidgetTester tester, CoreColor color) => Theme.of(
  tester.element(find.byType(RadioGroup<String>)),
).colorScheme.resolve(color).toValue();

/// The card tiles — the composed containers clipped to their corner. The
/// indicator rings are composed too, but never clipped.
Finder _tiles() => find.byWidgetPredicate(
  (w) =>
      w is OutlinedContainer &&
      w.containerStyle?.clipBehavior == CoreClipBehavior.antiAlias,
);

List<CoreOutlinedContainerStyle> _tileStyles(WidgetTester tester) => [
  for (final tile in tester.widgetList<OutlinedContainer>(_tiles()))
    tile.containerStyle!,
];

/// The tile's state layer — the one `AnimatedContainer` laid edge to edge
/// inside a `Position` (the focus ring's own layers sit at negative
/// offsets, outside the child).
Finder _tileLayer() => find.descendant(
  of: find.byWidgetPredicate(
    (w) =>
        w is Position &&
        w.top == 0 &&
        w.right == 0 &&
        w.bottom == 0 &&
        w.left == 0,
  ),
  matching: find.byType(AnimatedContainer),
);

Color _layerColor(WidgetTester tester, {int index = 0}) {
  final layer = tester
      .widgetList<AnimatedContainer>(_tileLayer())
      .elementAt(
        index,
      );
  return (layer.decoration! as BoxDecoration).color!;
}

/// The halo a plain row draws around its ring — a circle with no box of its
/// own.
Finder _halo() => find.byWidgetPredicate(
  (w) =>
      w is AnimatedContainer &&
      w.decoration is BoxDecoration &&
      (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
      w.constraints == null,
);

Widget _cardGroup({
  CoreComponentSize size = CoreComponentSize.md,
  bool enabled = true,
  CoreRadioGroupOrientation orientation = CoreRadioGroupOrientation.vertical,
}) => RadioGroup<String>(
  onChanged: (_) {},
  value: 'a',
  enabled: enabled,
  size: size,
  orientation: orientation,
  variant: CoreRadioGroupVariant.card,
  child: const Column(
    crossAxisAlignment: .stretch,
    children: [
      Radio(value: 'a', label: 'Alpha', description: 'First choice'),
      Radio(value: 'b', label: 'Beta'),
    ],
  ),
);

void main() {
  for (final enabled in [true, false]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'explicit selected padding controls card layout $enabled $scale',
        (tester) async {
          Future<Rect> selectedAt(String value) async {
            await tester.pumpWidget(
              _buildApp(
                Center(
                  child: SizedBox(
                    width: 320,
                    child: MediaQuery(
                      data: MediaQueryData(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: RadioGroup<String>(
                        enabled: enabled,
                        value: value,
                        onChanged: (_) {},
                        variant: CoreRadioGroupVariant.card,
                        radioGroupStyle: const CoreRadioGroupStyle(
                          tilePadding: CoreEdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          tileSelectedPadding: CoreEdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          tileSelectedBorderWidth: 1.5,
                        ),
                        options: const [
                          (
                            value: 'a',
                            label: 'A longer choice that wraps safely',
                          ),
                          (value: 'b', label: 'Other'),
                        ],
                      ),
                    ),
                  ),
                ),
                scaling: scale,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            return tester.getRect(_tiles().first);
          }

          final selected = await selectedAt('a');
          final resting = await selectedAt('b');
          expect(selected.height, closeTo(resting.height + scale, .01));
          expect(selected.width, resting.width);
        },
      );
    }
  }
  testWidgets('selected padding preserves keyboard activation and traversal', (
    tester,
  ) async {
    final a = FocusNode();
    final b = FocusNode();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    String? picked;
    await tester.pumpWidget(
      _buildApp(
        RadioGroup<String>(
          value: 'a',
          onChanged: (value) => picked = value,
          variant: CoreRadioGroupVariant.card,
          radioGroupStyle: const CoreRadioGroupStyle(
            tileSelectedPadding: CoreEdgeInsets.all(14),
          ),
          child: Column(
            children: [
              Radio(value: 'a', label: 'Alpha', focusNode: a),
              Radio(value: 'b', label: 'Beta', focusNode: b),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(a.skipTraversal, isFalse);
    expect(b.skipTraversal, isTrue);
    b.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(picked, 'b');
    expect(tester.takeException(), isNull);
  });
  group('description', () {
    testWidgets('renders under the label, 2 px below it, in the quieter '
        "foreground at the size row's role", (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            child: const Radio(
              value: 'a',
              label: 'Alpha',
              description: 'Supporting line',
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // One column: label, gap, description — in that order.
      final column = tester.widget<Column>(
        find.ancestor(
          of: find.text('Supporting line'),
          matching: find.byType(Column),
        ),
      );
      expect(column.children, hasLength(3));
      expect(column.children[1], isA<Gap>());
      final gap = column.children[1] as Gap;
      expect(gap.gapStyle?.size, CoreSpace.space2);

      final label = tester.getRect(find.text('Alpha'));
      final description = tester.getRect(find.text('Supporting line'));
      expect(description.top, closeTo(label.bottom + CoreSpace.space2, 0.01));
      expect(description.left, closeTo(label.left, 0.01));

      final style = tester.widget<Text>(find.text('Supporting line')).style!;
      // `md` — body-small (13 / 400), one step under the 14 label.
      expect(style.fontSize, CoreFontSize.s13);
      expect(style.fontWeight, FontWeight.w400);
      expect(
        style.color,
        _token(tester, CoreRadioGroupStyle.defaultDescriptionStyle.color!),
      );
    });

    testWidgets('the description role follows the size ladder', (
      tester,
    ) async {
      Future<double?> sizeAt(CoreComponentSize size) async {
        await tester.pumpWidget(
          _buildApp(
            RadioGroup<String>(
              onChanged: (_) {},
              value: 'a',
              size: size,
              child: const Radio(value: 'a', label: 'A', description: 'D'),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        return tester.widget<Text>(find.text('D')).style?.fontSize;
      }

      expect(await sizeAt(.xs), CoreFontSize.s12);
      expect(await sizeAt(.sm), CoreFontSize.s12);
      expect(await sizeAt(.md), CoreFontSize.s13);
      expect(await sizeAt(.lg), CoreFontSize.s14);
      expect(await sizeAt(.xl), CoreFontSize.s14);
      expect(await sizeAt(.xl2), CoreFontSize.s14);
    });

    testWidgets('a disabled description dims with the label', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const RadioGroup<String>(
            value: 'a',
            enabled: false,
            child: Radio(value: 'a', label: 'A', description: 'D'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final disabled = _token(
        tester,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(tester.widget<Text>(find.text('D')).style?.color, disabled);
      expect(tester.widget<Text>(find.text('A')).style?.color, disabled);
    });

    testWidgets('a row without a description keeps its tree', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            child: const Radio(value: 'a', label: 'Alpha'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        find.ancestor(of: find.text('Alpha'), matching: find.byType(Column)),
        findsNothing,
      );
      final row = tester.widget<Row>(
        find.ancestor(of: find.text('Alpha'), matching: find.byType(Row)).first,
      );
      expect(row.crossAxisAlignment, CrossAxisAlignment.center);
      // Still a plain row: no tile, a halo around the ring, a circular ring.
      expect(_tiles(), findsNothing);
      expect(_halo(), findsOneWidget);
      final outline = tester.widget<FocusOutline>(find.byType(FocusOutline));
      expect(outline.shape, CoreFocusOutlineShape.circle);
    });
  });

  group('card', () {
    testWidgets('each option is a tile — padding, corner, the width, the '
        'face and border by state', (tester) async {
      await tester.pumpWidget(_buildApp(_cardGroup()));
      final _ = await tester.pumpAndSettle();

      expect(_tiles(), findsNWidgets(2));
      final [selected, unselected] = _tileStyles(tester);
      const corner = CoreBorderRadius.all(CoreRadius.radius10);
      for (final tile in [selected, unselected]) {
        expect(tile.borderRadius, corner);
      }
      expect(selected.borderWidth, CoreStrokeWidth.stroke2);
      expect(unselected.borderWidth, CoreStrokeWidth.stroke1);
      expect(
        selected.backgroundColor,
        CoreRadioGroupStyle.defaultTileSelectedBackgroundColor,
      );
      expect(
        selected.borderColor,
        CoreRadioGroupStyle.defaultTileSelectedBorderColor,
      );
      expect(
        unselected.backgroundColor,
        CoreRadioGroupStyle.defaultTileBackgroundColor,
      );
      expect(
        unselected.borderColor,
        CoreRadioGroupStyle.defaultTileBorderColor,
      );

      // The painted face — the container's own box.
      final faces = [
        for (final element in _tiles().evaluate())
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: find.byWidget(element.widget),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration,
      ];
      expect(
        faces[0].color,
        _token(tester, CoreRadioGroupStyle.defaultTileSelectedBackgroundColor),
      );
      expect(faces[0].border!.top.width, CoreStrokeWidth.stroke2);
      expect(faces[1].border!.top.width, CoreStrokeWidth.stroke1);
      expect(
        faces[0].border!.top.color,
        _token(tester, CoreRadioGroupStyle.defaultTileSelectedBorderColor),
      );
      expect(
        faces[1].color,
        _token(tester, CoreRadioGroupStyle.defaultTileBackgroundColor),
      );

      // Padding 10 · 12 inside the unselected tile; the selected one gives
      // its heavier stroke's extra pixel back.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Padding &&
              w.padding ==
                  const EdgeInsets.symmetric(
                    vertical: CoreSpace.space10,
                    horizontal: CoreSpace.space12,
                  ),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Padding &&
              w.padding ==
                  const EdgeInsets.symmetric(
                    vertical: CoreSpace.space10 - 1,
                    horizontal: CoreSpace.space12 - 1,
                  ),
        ),
        findsOneWidget,
      );
      // The tile's indicator is the 18 px ring with a 5 px selected stroke.
      final rings = tester
          .widgetList<OutlinedContainer>(find.byType(OutlinedContainer))
          .where((w) => w.containerStyle?.clipBehavior == null)
          .map((w) => w.containerStyle!)
          .toList();
      expect(rings.map((r) => r.width), everyElement(CoreSize.size18));
      expect(rings.first.borderWidth, CoreStrokeWidth.stroke5);
      expect(rings.last.borderWidth, CoreStrokeWidth.stroke1);
    });

    testWidgets('picking a tile moves neither its content nor its box — the '
        'heavier stroke is drawn inward', (tester) async {
      Future<(Rect, Rect)> geometryOf(String value) async {
        await tester.pumpWidget(
          _buildApp(
            RadioGroup<String>(
              onChanged: (_) {},
              value: value,
              variant: CoreRadioGroupVariant.card,
              size: CoreComponentSize.xl,
              options: const [
                (value: 'a', label: 'Alpha'),
                (value: 'b', label: 'Beta'),
              ],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        return (
          tester.getRect(_tiles().first),
          tester.getRect(find.text('Alpha')),
        );
      }

      final (selectedTile, selectedLabel) = await geometryOf('a');
      final (restingTile, restingLabel) = await geometryOf('b');
      expect(selectedTile, restingTile);
      expect(selectedLabel, restingLabel);
      // Content at padding 16 + the resting 1 px stroke.
      expect(restingLabel.left - restingTile.left, greaterThan(17));
    });

    testWidgets('the title is label-large at md, label-xl at 500 at lg, '
        'title-small at xl and title-medium at xl2 — the card role wins over '
        'the size row', (tester) async {
      Future<TextStyle> titleAt(CoreComponentSize size) async {
        await tester.pumpWidget(_buildApp(_cardGroup(size: size)));
        final _ = await tester.pumpAndSettle();
        return tester.widget<Text>(find.text('Alpha')).style!;
      }

      final md = await titleAt(.md);
      expect(md.fontSize, CoreFontSize.s14);
      expect(md.fontWeight, FontWeight.w500);
      // The plain `lg` row would draw 16 here.
      final lg = await titleAt(.lg);
      expect(lg.fontSize, CoreFontSize.s15);
      expect(lg.fontWeight, FontWeight.w500);
      final xs = await titleAt(.xs);
      expect(xs.fontSize, CoreFontSize.s14);
      final xl = await titleAt(.xl);
      expect(xl.fontSize, CoreFontSize.s16);
      expect(xl.fontWeight, FontWeight.w600);
      expect(
        tester.widget<Text>(find.text('First choice')).style?.fontSize,
        CoreFontSize.s13,
      );
      // The xl tile's 16 all round (15 on the selected tile, whose stroke is
      // a pixel heavier).
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Padding &&
              w.padding == const EdgeInsets.all(CoreSpace.space16),
        ),
        findsOneWidget,
      );
      final xl2 = await titleAt(.xl2);
      expect(xl2.fontSize, CoreFontSize.s18);
      expect(xl2.fontWeight, FontWeight.w600);
      // The description follows the card row too.
      expect(
        tester.widget<Text>(find.text('First choice')).style?.fontSize,
        CoreFontSize.s14,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Padding &&
              w.padding == const EdgeInsets.all(CoreSpace.space20),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a vertical group stretches its tiles to the group width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            variant: CoreRadioGroupVariant.card,
            options: const [
              (value: 'a', label: 'Alpha'),
              (value: 'b', label: 'Beta'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final groupWidth = tester.getSize(find.byType(RadioGroup<String>)).width;
      for (final element in _tiles().evaluate()) {
        expect(tester.getSize(find.byWidget(element.widget)).width, groupWidth);
      }
    });

    testWidgets('a vertical group under an unbounded width takes its '
        'widest tile instead of asserting', (tester) async {
      // A `Row` hands a non-flex child an unbounded width — a stretching
      // column there forces an infinite width.
      await tester.pumpWidget(
        _buildApp(
          Row(
            children: [
              RadioGroup<String>(
                onChanged: (_) {},
                value: 'a',
                variant: CoreRadioGroupVariant.card,
                options: const [
                  (value: 'a', label: 'Alpha'),
                  (value: 'b', label: 'A much longer option'),
                ],
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final groupWidth = tester.getSize(find.byType(RadioGroup<String>)).width;
      final widths = [
        for (final element in _tiles().evaluate())
          tester.getSize(find.byWidget(element.widget)).width,
      ];
      // Every tile takes the widest one's width, and the group hugs them.
      expect(widths, hasLength(2));
      expect(widths[0], widths[1]);
      expect(widths[0], groupWidth);
      expect(
        groupWidth,
        lessThan(tester.getSize(find.byType(Row).first).width),
      );
    });

    testWidgets('a vertical group answers intrinsic queries', (tester) async {
      // A popover panel sizes its content with `IntrinsicWidth`.
      await tester.pumpWidget(
        _buildApp(
          Center(
            child: IntrinsicWidth(
              child: RadioGroup<String>(
                onChanged: (_) {},
                value: 'a',
                variant: CoreRadioGroupVariant.card,
                options: const [
                  (value: 'a', label: 'Alpha'),
                  (value: 'b', label: 'A much longer option'),
                ],
              ),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final widths = [
        for (final element in _tiles().evaluate())
          tester.getSize(find.byWidget(element.widget)).width,
      ];
      expect(widths[0], widths[1]);
      expect(
        widths[0],
        tester.getSize(find.byType(RadioGroup<String>)).width,
      );
    });

    testWidgets('a horizontal group keeps each tile at its own width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            variant: CoreRadioGroupVariant.card,
            orientation: CoreRadioGroupOrientation.horizontal,
            options: const [
              (value: 'a', label: 'Alpha'),
              (value: 'b', label: 'A much longer option'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final widths = [
        for (final element in _tiles().evaluate())
          tester.getSize(find.byWidget(element.widget)).width,
      ];
      expect(widths[0], lessThan(widths[1]));
      expect(
        widths[1],
        lessThan(tester.getSize(find.byType(RadioGroup<String>)).width),
      );
    });

    testWidgets('the state layer covers the whole tile, not a halo around '
        'the ring', (tester) async {
      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pumpWidget(_buildApp(_cardGroup()));
      final _ = await tester.pumpAndSettle();

      expect(_halo(), findsNothing);
      expect(_tileLayer(), findsNWidgets(2));
      // Edge to edge inside the selected tile's 2 px border.
      final tile = tester.getRect(_tiles().first);
      final layer = tester.getRect(_tileLayer().first);
      expect(layer, tile.deflate(CoreStrokeWidth.stroke2));

      await gesture.moveTo(const Offset(790, 590));
      final _ = await tester.pumpAndSettle();
      expect(_layerColor(tester).a, 0);

      // Anywhere on the tile — here its padding, past the label's end.
      await gesture.moveTo(tile.centerRight - const Offset(4, 0));
      final _ = await tester.pumpAndSettle();
      expect(
        _layerColor(tester).a,
        closeTo(CoreRadioGroupStyle.defaultStateLayer.hover, 0.01),
      );
      expect(_layerColor(tester, index: 1).a, 0);
    });

    testWidgets('the whole tile is the hit target', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (value) => picked = value,
            value: 'a',
            variant: CoreRadioGroupVariant.card,
            options: const [
              (value: 'a', label: 'Alpha'),
              (value: 'b', label: 'Beta'),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final tile = tester.getRect(_tiles().last);
      await tester.tapAt(tile.centerRight - const Offset(4, 0));
      final _ = await tester.pumpAndSettle();
      expect(picked, 'b');
    });

    testWidgets('the focus ring goes around the tile, on its corner', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_cardGroup()));
      final _ = await tester.pumpAndSettle();

      final outlines = tester
          .widgetList<FocusOutline>(find.byType(FocusOutline))
          .toList();
      // One ring per option — none around the indicator.
      expect(outlines, hasLength(2));
      for (final outline in outlines) {
        expect(outline.shape, CoreFocusOutlineShape.rectangle);
        expect(
          outline.focusOutlineStyle?.borderRadius,
          const CoreBorderRadius.all(CoreRadius.radius10),
        );
      }
      expect(
        tester.getRect(find.byType(FocusOutline).first),
        tester.getRect(_tiles().first),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      final _ = await tester.pumpAndSettle();
      final focused = tester
          .widgetList<FocusOutline>(find.byType(FocusOutline))
          .map((o) => o.focused)
          .toList();
      expect(focused, [true, false]);
    });

    testWidgets('a disabled tile keeps its face and width and takes the '
        'disabled outline', (tester) async {
      await tester.pumpWidget(_buildApp(_cardGroup(enabled: false)));
      final _ = await tester.pumpAndSettle();

      final [selected, unselected] = _tileStyles(tester);
      expect(
        selected.backgroundColor,
        CoreRadioGroupStyle.defaultTileSelectedBackgroundColor,
      );
      expect(selected.borderWidth, CoreStrokeWidth.stroke2);
      expect(
        unselected.backgroundColor,
        CoreRadioGroupStyle.defaultTileBackgroundColor,
      );
      expect(unselected.borderWidth, CoreStrokeWidth.stroke1);
      for (final tile in [selected, unselected]) {
        expect(
          tile.borderColor,
          const CoreColor.token(CoreColors.disabledOutline),
        );
        expect(tile.surfaceBlur, 0);
      }
      final disabled = _token(
        tester,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(tester.widget<Text>(find.text('Alpha')).style?.color, disabled);
      expect(
        tester.widget<Text>(find.text('First choice')).style?.color,
        disabled,
      );
    });

    testWidgets('tile overrides reach the tile', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          RadioGroup<String>(
            onChanged: (_) {},
            value: 'a',
            variant: CoreRadioGroupVariant.card,
            radioGroupStyle: const CoreRadioGroupStyle(
              tilePadding: CoreEdgeInsets.all(CoreSpace.space4),
              tileBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
              tileBorderWidth: CoreStrokeWidth.stroke2,
              tileSelectedBorderColor: CoreColor.token(CoreColors.error),
            ),
            options: const [(value: 'a', label: 'Alpha')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final tile = _tileStyles(tester).single;
      expect(tile.borderRadius, const CoreBorderRadius.all(CoreRadius.radius4));
      expect(tile.borderWidth, CoreStrokeWidth.stroke2);
      expect(tile.borderColor, const CoreColor.token(CoreColors.error));
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Padding &&
              w.padding == const EdgeInsets.all(CoreSpace.space4),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FocusOutline>(find.byType(FocusOutline))
            .focusOutlineStyle
            ?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
    });
  });
}
