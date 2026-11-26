// The Dock redesign (#6463), row by row, as the widget tree paints it.
//
// Every expectation reads a rendered rect or a painted decoration, never the
// resolved style alone: a value the resolver carries and the widget drops
// would pass a test of the resolver. The Web twin
// (`coui_web/test/components/dock_redesign_test.dart`) reads the emitted
// chrome against the same rows.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../parity/parity_fonts.dart';

const double _kEpsilon = 0.01;

const List<String> _kLabels = ['홈', '검색', '받은편지함'];

Widget _app(
  Widget child, {
  CoreSurfaceStyleId? surfaceStyle,
  bool dark = false,
}) => CoUIApp(
  theme: ThemeData.fromCore(
    dark ? CoreThemePresets.dark : CoreThemePresets.light,
  ),
  surfaceStyle: surfaceStyle ?? CoreSurfaceStyleId.defaultStyle,
  home: Align(
    alignment: Alignment.bottomCenter,
    child: SizedBox(width: 360, child: child),
  ),
);

Dock _dock(CoreDockSize size) => Dock(
  size: size,
  items: [
    for (final (i, label) in _kLabels.indexed)
      CoreDockItemData<Widget>(
        icon: const Icon(LucideIcons.house),
        label: label,
        isActive: i == 0,
        onPressed: () {},
      ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  CoreDockSize size, {
  CoreSurfaceStyleId? surfaceStyle,
  bool dark = false,
}) async {
  await tester.pumpWidget(
    _app(_dock(size), surfaceStyle: surfaceStyle, dark: dark),
  );
  await tester.pump(const Duration(milliseconds: 100));
  expect(tester.takeException(), isNull);
}

ThemeData _theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Dock)));

Color _resolve(WidgetTester tester, CoreColorToken token) =>
    _theme(tester).colorScheme.resolve(CoreColor.token(token)).toValue();

/// The bar's own decorated box — the one with a border.
BoxDecoration _barDecoration(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(Dock),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((d) => d.border != null);

Rect _barRect(WidgetTester tester) {
  final bar = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(Dock),
          matching: find.byType(DecoratedBox),
        ),
      )
      .firstWhere((box) {
        final d = box.decoration;
        return d is BoxDecoration && d.border != null;
      });

  return tester.getRect(find.byWidget(bar));
}

/// The settled plate: the decorated box in the plate's fill.
Finder _plate(WidgetTester tester) {
  final fill = _resolve(tester, CoreColors.surfaceContainerHigh);
  final plates = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(Dock),
          matching: find.byType(DecoratedBox),
        ),
      )
      .where((box) {
        final d = box.decoration;
        return d is BoxDecoration && d.color == fill;
      })
      .toList();
  expect(plates, hasLength(1));

  return find.byWidget(plates.single);
}

/// Each item's cell — its column, icon over label.
List<Rect> _cells(WidgetTester tester) {
  final columns = find.descendant(
    of: find.byType(Row),
    matching: find.byType(Column),
  );
  expect(columns, findsNWidgets(_kLabels.length));

  return [
    for (var i = 0; i < _kLabels.length; i++) tester.getRect(columns.at(i)),
  ];
}

const List<CoreDockSize> _compact = [CoreDockSize.xs, CoreDockSize.sm];

void main() {
  setUpAll(loadParityFonts);

  group('the bar', () {
    testWidgets('draws an outline-variant line on every edge', (tester) async {
      await _pump(tester, .md);

      final border = _barDecoration(tester).border! as Border;
      expect(border.isUniform, isTrue);
      expect(border.top.color, _resolve(tester, CoreColors.outlineVariant));
      expect(border.top.width, CoreStrokeWidth.stroke1);
    });

    for (final size in CoreDockSize.values) {
      final compact = _compact.contains(size);
      final radius = compact ? 10.0 : 16.0;
      final side = compact ? 8.0 : 10.0;
      final rowInset = compact ? 6.0 : 10.0;
      final gap = compact ? 6.0 : 4.0;

      testWidgets('${size.name}: rounded $radius', (tester) async {
        await _pump(tester, size);

        expect(
          _barDecoration(tester).borderRadius,
          BorderRadius.circular(radius),
        );
      });

      testWidgets('${size.name}: padded $side beside and $rowInset above and '
          'below, apps $gap apart and centred', (tester) async {
        await _pump(tester, size);

        final bar = _barRect(tester);
        final cells = _cells(tester);
        // Packed with the gap between them…
        for (var i = 1; i < cells.length; i++) {
          expect(cells[i].left - cells[i - 1].right, closeTo(gap, _kEpsilon));
        }
        // …and centred in the bar.
        final row = cells.first.expandToInclude(cells.last);
        expect(row.center.dx, closeTo(bar.center.dx, _kEpsilon));
        // The room above the row, inside the line, where the bar is no taller
        // than its row asks.
        final asked = row.height + 2 * rowInset + 2;
        if (asked >= CoreDockStyle.defaultsBySize[size]!.height!) {
          expect(row.top - (bar.top + 1), closeTo(rowInset, _kEpsilon));
          expect(bar.bottom - 1 - row.bottom, closeTo(rowInset, _kEpsilon));
        }
        final resolved = resolveDock(
          tester.element(find.byType(Dock)),
          size: size,
        );
        expect(resolved.horizontalPadding, side);
        expect(resolved.rowPadding.top, rowInset);
        expect(resolved.rowPadding.bottom, rowInset);
      });
    }

    testWidgets('md: the bar is its row plus 10 and the line on each edge', (
      tester,
    ) async {
      await _pump(tester, .md);

      // 24 icon + 4 gap + the 15px line of the 11px label, 10 above and
      // below, 1 of line on each edge.
      expect(_barRect(tester).height, 65);
    });

    testWidgets('has no material by default', (tester) async {
      // Translucency and blur come from the surface style — never from a
      // Dock default.
      await _pump(tester, .md);

      expect(
        _barDecoration(tester).color,
        _resolve(tester, CoreColors.surface),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });

    /// The cast painted around the bar.
    List<BoxShadow> castOf(WidgetTester tester) => tester
        .widget<InjectedCast>(
          find.descendant(
            of: find.byType(Dock),
            matching: find.byType(InjectedCast),
          ),
        )
        .shadows;

    for (final dark in [false, true]) {
      testWidgets('casts the md shadow outside the bar '
          '(${dark ? 'dark, strengthened' : 'light'})', (tester) async {
        await _pump(tester, .md, dark: dark);

        final cast = castOf(tester);
        expect(cast, hasLength(CoreShadow.md.length));
        final layer = CoreShadow.md.single;
        expect(cast.single.offset, Offset(layer.offsetX, layer.offsetY));
        expect(cast.single.spreadRadius, layer.spreadRadius);
        expect(
          cast.single.color.a,
          closeTo(
            dark
                ? (layer.opacity * CoreShadow.darkStrength).clamp(0, 1)
                : layer.opacity,
            0.01,
          ),
        );
        expect(cast.single.color.withValues(alpha: 1), Colors.black);
        // Outside the bar only: the bar's own box paints no shadow, so a
        // translucent bar never shows its cast through itself.
        expect(_barDecoration(tester).boxShadow, isNull);
        // And the cast knocks out exactly the bar's own corners.
        final injected = tester.widget<InjectedCast>(
          find.descendant(
            of: find.byType(Dock),
            matching: find.byType(InjectedCast),
          ),
        );
        expect(injected.borderRadius, BorderRadius.circular(16));
      });
    }
  });

  group('the app cell', () {
    for (final (size, width) in [
      (CoreDockSize.md, 48.0),
      (CoreDockSize.lg, 56.0),
      (CoreDockSize.xl, 64.0),
    ]) {
      testWidgets('${size.name}: every cell is $width wide', (tester) async {
        await _pump(tester, size);

        for (final cell in _cells(tester)) {
          expect(cell.width, closeTo(width, _kEpsilon));
        }
      });
    }

    for (final size in _compact) {
      testWidgets('${size.name}: a cell is as wide as its icon', (
        tester,
      ) async {
        await _pump(tester, size);

        final icon = CoreDockStyle.defaultsBySize[size]!.iconStyle!.size!;
        for (final cell in _cells(tester)) {
          expect(cell.width, closeTo(icon, _kEpsilon));
        }
      });
    }
  });

  group('the active plate', () {
    for (final size in CoreDockSize.values) {
      final compact = _compact.contains(size);
      final radius = compact ? 8.0 : 10.0;
      final side = compact ? 3.0 : 0.0;
      final above = compact ? 3.0 : 5.0;

      testWidgets('${size.name}: radius $radius, $above past the icon above '
          'and below and $side beside the cell, inside the bar', (
        tester,
      ) async {
        await _pump(tester, size);

        final plate = _plate(tester);
        final decoration =
            tester.widget<DecoratedBox>(plate).decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(radius));

        final rect = tester.getRect(plate);
        final icon = tester.getRect(find.byType(Icon).first);
        final cell = _cells(tester).first;
        expect(rect.top, closeTo(icon.top - above, _kEpsilon));
        expect(rect.bottom, closeTo(icon.bottom + above, _kEpsilon));
        expect(rect.left, closeTo(cell.left - side, _kEpsilon));
        expect(rect.right, closeTo(cell.right + side, _kEpsilon));
        // Larger than the icon, and not clipped: wholly inside the bar.
        expect(rect.height, greaterThan(icon.height));
        final bar = _barRect(tester);
        expect(bar.contains(rect.topLeft), isTrue);
        expect(bar.contains(rect.bottomRight - const Offset(1, 1)), isTrue);
      });
    }
  });

  group('the labels', () {
    testWidgets('the 11px role, SemiBold on-surface when active and Medium '
        'on-surface-variant otherwise', (tester) async {
      await _pump(tester, .md);

      final active = tester.widget<Text>(find.text(_kLabels.first)).style!;
      final idle = tester.widget<Text>(find.text(_kLabels[1])).style!;
      expect(active.fontSize, 11);
      expect(idle.fontSize, 11);
      expect(active.fontWeight, FontWeight.w600);
      expect(idle.fontWeight, FontWeight.w500);
      expect(active.color, _resolve(tester, CoreColors.onSurface));
      expect(idle.color, _resolve(tester, CoreColors.onSurfaceVariant));
    });

    testWidgets('the active icon keeps the primary tint', (tester) async {
      await _pump(tester, .md);

      final icons = tester.widgetList<IconTheme>(
        find.descendant(
          of: find.byType(Dock),
          matching: find.byType(IconTheme),
        ),
      );
      expect(
        icons.map((t) => t.data.color),
        containsAll([
          _resolve(tester, CoreColors.primary),
          _resolve(tester, CoreColors.onSurfaceVariant),
        ]),
      );
    });
  });
}
