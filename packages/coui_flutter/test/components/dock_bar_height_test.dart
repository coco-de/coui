// How tall the Dock bar is: `CoreDockStyle.height` is its *minimum*.
//
// At text scale 1 and for any content that fits, the bar is exactly the Core
// height. When the item row needs more room — the label grown by the OS text
// size, a taller icon — the bar grows with it, so neither the label, the icon
// nor the active pill is clipped by (or hangs out of) the bar.
//
// Every number is a rect the widget tree painted, never the resolved style: a
// style that carries the right minimum into a widget that sizes the bar with it
// as a fixed height reads fine from the numbers and clips on screen. The table
// of the first group is the vector table coui_core shares with the Chrome probe
// of the Web markup (`dock_bar_height_vectors.json`), so a change on one
// platform fails the other.
//
// The second group renders real Pretendard glyphs: with the test font every
// glyph is a full em wide, and a label at 200% would overflow a 288px bar
// sideways for a reason that has nothing to do with its height.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../parity/parity_fonts.dart';

/// The vector table shared with the Core reference test and the Chrome probe
/// (cwd is `packages/coui_flutter` under `flutter test`).
const String _kVectorsPath =
    '../coui_core/test/fixtures/dock_bar_height_vectors.json';

/// The line the bar draws around itself, on each edge, in logical px.
const double _kBorder = 1;

/// The room the bar keeps above (and below) its row at [size]: its padding,
/// never less than the plate's reach — the one rule Core states — bent by
/// [density].
double _rowInset(CoreDockSize size, {CoreDensity? density}) {
  final row = CoreDockStyle.defaultsBySize[size]!;
  final inset = CoreDockStyle.rowInsetFor(
    row.padding!.top,
    row.indicatorPadding!,
  );

  return density == null ? inset : density.space(inset);
}

/// Slack for float arithmetic in a rect that comes out of layout.
const double _kEpsilon = 0.01;

const _kLabels = ['Home', 'Search', 'Profile'];

/// An app that hands the dock the loose height a bottom bar slot gives it, at
/// the given text scale and width.
Widget _app(
  Widget child, {
  double scale = 1,
  double width = 320,
  CoreDensity? density,
  CoreSurfaceStyleId? surfaceStyle,
}) {
  final theme = ThemeData.fromCore(CoreThemePresets.light);
  final home = Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );

  return CoUIApp(
    theme: theme,
    density: density ?? CoreDensity.defaultDensity,
    surfaceStyle: surfaceStyle ?? CoreSurfaceStyleId.defaultStyle,
    home: home,
  );
}

CoreEdgeInsets _floating() => const CoreEdgeInsets.all(CoreSpace.space8);

/// A dock whose items carry labels, so the row is as tall as the text.
Dock _labelled(
  CoreDockSize size, {
  bool floating = false,
  int active = 0,
  CoreDockStyle? style,
}) => Dock(
  size: size,
  dockStyle: CoreDockStyle(
    barMargin: floating ? _floating() : null,
  ).merge(style),
  items: [
    for (final (i, label) in _kLabels.indexed)
      CoreDockItemData<Widget>(
        icon: const Icon(LucideIcons.house),
        label: label,
        isActive: i == active,
        onPressed: () {},
      ),
  ],
);

/// The resolved chrome of the dock in the tree, at its own size and style.
ResolvedDock _resolvedOf(WidgetTester tester) {
  final dock = tester.widget<Dock>(find.byType(Dock));

  return resolveDock(
    tester.element(find.byType(Dock)),
    size: dock.size,
    dockStyle: dock.dockStyle,
  );
}

/// The bar's own box: the decorated box drawn in the bar's background.
Finder _barFinder(WidgetTester tester) {
  final resolved = _resolvedOf(tester);
  final bar = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(Dock),
          matching: find.byType(DecoratedBox),
        ),
      )
      .firstWhere((box) {
        final decoration = box.decoration;

        return decoration is BoxDecoration &&
            decoration.color == resolved.backgroundColor;
      });

  return find.byWidget(bar);
}

/// The plate boxes in the tree, settled under the active item's icon.
Iterable<Finder> _pillFinders(WidgetTester tester) {
  final resolved = _resolvedOf(tester);

  return tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(Dock),
          matching: find.byType(DecoratedBox),
        ),
      )
      .where((box) {
        final decoration = box.decoration;

        return decoration is BoxDecoration &&
            decoration.color == resolved.indicatorColor &&
            decoration.borderRadius == resolved.indicatorRadius;
      })
      .map(find.byWidget);
}

/// The items' own boxes: one column each, icon over label.
List<Rect> _itemRects(WidgetTester tester) {
  final columns = find.descendant(
    of: find.byType(Row),
    matching: find.byType(Column),
  );
  expect(columns, findsNWidgets(_kLabels.length));

  return [
    for (var i = 0; i < _kLabels.length; i++) tester.getRect(columns.at(i)),
  ];
}

bool _inside(Rect inner, Rect outer) =>
    inner.left >= outer.left - _kEpsilon &&
    inner.right <= outer.right + _kEpsilon &&
    inner.top >= outer.top - _kEpsilon &&
    inner.bottom <= outer.bottom + _kEpsilon;

/// A row of the vector table.
class _Case {
  _Case(this.json);

  final Map<String, Object?> json;

  String get name => json['name']! as String;
  CoreDockSize get size => CoreDockSize.values.byName(json['size']! as String);
  double get iconSize => (json['iconSize']! as num).toDouble();
  double get bar => (json['bar']! as num).toDouble();

  CoreEdgeInsets? _vertical(String key) {
    final padding = json[key] as Map<String, Object?>?;
    if (padding == null) return null;

    return CoreEdgeInsets.only(
      top: (padding['top']! as num).toDouble(),
      bottom: (padding['bottom']! as num).toDouble(),
    );
  }

  CoreEdgeInsets? get indicatorPadding => _vertical('indicatorPadding');

  /// The bar padding the row states — its sides kept at the size's own.
  CoreEdgeInsets? get padding {
    final vertical = _vertical('padding');
    if (vertical == null) return null;
    final own = CoreDockStyle.defaultsBySize[size]!.padding!;

    return CoreEdgeInsets.fromLTRB(
      own.left,
      vertical.top,
      own.right,
      vertical.bottom,
    );
  }
}

void main() {
  setUpAll(loadParityFonts);

  group('the bar against the shared vector table', () {
    final doc =
        jsonDecode(File(_kVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    final tolerance = ((doc['tolerance']! as Map)['flutter']! as num)
        .toDouble();
    final cases = [
      for (final c in (doc['cases']! as List).cast<Map<String, Object?>>())
        _Case(c),
    ];

    test('the vector table is not empty', () => expect(cases, isNotEmpty));

    for (final c in cases) {
      for (final tappable in [true, false]) {
        testWidgets('${c.name}${tappable ? '' : ' (items inert)'}', (
          tester,
        ) async {
          // No item carries a label, so an item is as tall as its icon and the
          // number does not depend on a font. A tappable item is wrapped in a
          // `Clickable` and an inert one is not: the bar is the same either
          // way.
          await tester.pumpWidget(
            _app(
              Dock(
                size: c.size,
                dockStyle: CoreDockStyle(
                  padding: c.padding,
                  indicatorPadding: c.indicatorPadding,
                  iconStyle: CoreIconStyle(size: c.iconSize),
                ),
                items: [
                  for (var i = 0; i < 3; i++)
                    CoreDockItemData<Widget>(
                      icon: const Icon(LucideIcons.house),
                      isActive: i == 0,
                      onPressed: tappable ? () {} : null,
                    ),
                ],
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(_barFinder(tester)).height,
            closeTo(c.bar, tolerance),
          );
        });
      }
    }
  });

  group('the bar at larger text', () {
    for (final size in CoreDockSize.values) {
      for (final floating in [false, true]) {
        for (final width in [320.0, 288.0]) {
          for (final scale in [1.0, 1.15, 1.5, 2.0]) {
            final name =
                '${size.name} ${floating ? 'floating' : 'docked'} '
                'at ${(scale * 100).round()}% in $width';
            testWidgets(name, (tester) async {
              await tester.pumpWidget(
                _app(
                  _labelled(size, floating: floating),
                  scale: scale,
                  width: width,
                ),
              );
              await tester.pump(const Duration(milliseconds: 100));

              // No RenderFlex overflow, in either direction.
              expect(tester.takeException(), isNull);

              final minimum = CoreDockStyle.defaultsBySize[size]!.height!;
              final bar = tester.getRect(_barFinder(tester));
              final items = _itemRects(tester);
              final asked =
                  items.map((r) => r.height).reduce(math.max) +
                  2 * _rowInset(size) +
                  2 * _kBorder;

              // As tall as the row asks — never shorter than the minimum.
              expect(bar.height, closeTo(math.max(minimum, asked), _kEpsilon));
              if (asked > minimum) {
                expect(bar.height, greaterThan(minimum));
              } else {
                // The Core height, untouched, wherever the content fits.
                expect(bar.height, minimum);
              }

              // Every icon and every label sits inside the bar, and so does
              // the active plate: nothing is clipped by the bar or hangs out
              // of it.
              for (var i = 0; i < _kLabels.length; i++) {
                expect(
                  _inside(tester.getRect(find.byType(Icon).at(i)), bar),
                  isTrue,
                  reason: 'icon $i leaves the bar $bar',
                );
                if (CoreDockStyle.labelVisibleFor(size)) {
                  expect(
                    _inside(tester.getRect(find.text(_kLabels[i])), bar),
                    isTrue,
                    reason: 'label ${_kLabels[i]} leaves the bar $bar',
                  );
                }
              }
              final pills = _pillFinders(tester).toList();
              expect(pills, hasLength(1));
              expect(_inside(tester.getRect(pills.single), bar), isTrue);

              // Centred in the bar, in the minimum state and once the bar has
              // grown — the line is on both edges.
              final centre = (bar.top + bar.bottom) / 2;
              for (final item in items) {
                expect(item.center.dy, closeTo(centre, _kEpsilon));
              }
            });
          }
        }
      }
    }

    testWidgets('a bar grows at 150% and 200% where the row needs it', (
      tester,
    ) async {
      // The measured cases, so the loop above cannot pass with a bar that
      // never grows: md's row is 43 tall at 100% (24 icon, 4 gap, a 15px
      // line of the 11px label), and with the 10 above and below and the line
      // on both edges asks for 65 against its 64.
      Future<double> barHeight(CoreDockSize size, double scale) async {
        await tester.pumpWidget(_app(_labelled(size), scale: scale));
        await tester.pump(const Duration(milliseconds: 100));

        return tester.getSize(_barFinder(tester)).height;
      }

      expect(await barHeight(.md, 1), 65);
      expect(await barHeight(.md, 1.5), greaterThan(65));
      expect(await barHeight(.md, 2), greaterThan(await barHeight(.md, 1.5)));
      expect(await barHeight(.lg, 2), greaterThan(72));
      expect(await barHeight(.xl, 2), greaterThan(80));
    });

    for (final size in [CoreDockSize.md, CoreDockSize.lg, CoreDockSize.xl]) {
      testWidgets('${size.name} at 300% with room to spare sideways', (
        tester,
      ) async {
        // Past what a 320px bar holds beside the labels: the width is wide so
        // the only thing that can overflow is the height.
        await tester.pumpWidget(_app(_labelled(size), scale: 3, width: 600));
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        final bar = tester.getRect(_barFinder(tester));
        final tallest = _itemRects(
          tester,
        ).map((r) => r.height).reduce(math.max);
        expect(
          bar.height,
          closeTo(tallest + 2 * _rowInset(size) + 2 * _kBorder, _kEpsilon),
        );
        expect(
          bar.height,
          greaterThan(CoreDockStyle.defaultsBySize[size]!.height!),
        );
        for (final label in _kLabels) {
          expect(_inside(tester.getRect(find.text(label)), bar), isTrue);
        }
        expect(
          _inside(tester.getRect(_pillFinders(tester).single), bar),
          isTrue,
        );
      });
    }
  });

  group('the line around the bar is a field of the style', () {
    /// The bar's own border — all four edges, which must agree.
    double hairlineOf(WidgetTester tester) {
      final bar = tester.widget<DecoratedBox>(_barFinder(tester));
      final border = (bar.decoration as BoxDecoration).border! as Border;
      expect(border.isUniform, isTrue, reason: 'the line is on every edge');

      return border.top.width;
    }

    testWidgets('the default is the one-pixel line on every edge', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_labelled(.md)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(hairlineOf(tester), CoreDockStyle.defaultBorderWidth);
      expect(hairlineOf(tester), _kBorder);
    });

    testWidgets('a floating bar keeps its line', (tester) async {
      await tester.pumpWidget(_app(_labelled(.md, floating: true)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(hairlineOf(tester), _kBorder);
    });

    testWidgets('a width the style states is the width the bar draws', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_labelled(.md, style: const CoreDockStyle(borderWidth: 3))),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(hairlineOf(tester), 3);
    });
  });

  group('the height a caller states is a minimum too', () {
    testWidgets('a bar taller than its row keeps the stated height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _labelled(.md, style: const CoreDockStyle(height: 120)),
          scale: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.getSize(_barFinder(tester)).height, 120);
    });

    testWidgets('a bar shorter than its row grows past the stated height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _labelled(.md, style: const CoreDockStyle(height: 40)),
          scale: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      final bar = tester.getRect(_barFinder(tester));
      expect(bar.height, greaterThan(40));
      for (final label in _kLabels) {
        expect(_inside(tester.getRect(find.text(label)), bar), isTrue);
      }
    });
  });

  group('the parent that holds the bar', () {
    testWidgets("a parent of unbounded height gets the row's height", (
      tester,
    ) async {
      // A stack that fills what it is offered cannot size a bar to its content
      // here: there is no height to fill.
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(child: _labelled(.md, floating: true)),
          scale: 2,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      final bar = tester.getRect(_barFinder(tester));
      expect(bar.height, greaterThan(64));
      expect(_inside(tester.getRect(find.text('Home')), bar), isTrue);
    });

    testWidgets('a parent that fixes the height is obeyed', (tester) async {
      await tester.pumpWidget(
        _app(SizedBox(height: 120, child: _labelled(.md))),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.getSize(_barFinder(tester)).height, 120);
    });
  });

  group('the plate and its flight on a taller bar', () {
    testWidgets("the flight fills the bar's track and the plates sit on the "
        'icon rows', (tester) async {
      await tester.pumpWidget(_app(_labelled(.md), scale: 2));
      await tester.pump(const Duration(milliseconds: 100));
      // The icon row of each item: the icon's height across the cell's width.
      final cells = _itemRects(tester);
      final before = [
        for (var i = 0; i < _kLabels.length; i++)
          Rect.fromCenter(
            center: Offset(
              cells[i].center.dx,
              tester.getRect(find.byType(Icon).at(i)).center.dy,
            ),
            width: cells[i].width,
            height: tester.getRect(find.byType(Icon).at(i)).height,
          ),
      ];
      final bar = tester.getRect(_barFinder(tester));
      expect(bar.height, greaterThan(64));

      await tester.pumpWidget(_app(_labelled(.md, active: 2), scale: 2));
      await tester.pump();

      final clipFinder = find.byType(LiquidMorphClip);
      expect(clipFinder, findsOneWidget);
      final clip = tester.widget<LiquidMorphClip>(clipFinder);
      // The flight's fill is the track: the bar inside its line and its
      // horizontal padding.
      final track = tester.getRect(clipFinder);
      expect(track.top, closeTo(bar.top + _kBorder, _kEpsilon));
      expect(track.bottom, closeTo(bar.bottom - _kBorder, _kEpsilon));
      expect(track.height, closeTo(bar.height - 2 * _kBorder, _kEpsilon));

      // Both plates are bodies in the track's coordinates, on the icon rows:
      // the departing one around item 0, the arriving one around item 2,
      // each the icon row widened by the plate's padding.
      final pad =
          CoreDockStyle.defaultsBySize[CoreDockSize.md]!.indicatorPadding!;
      for (final (blob, item) in [
        (clip.anchor, before[0]),
        (clip.panel, before[2]),
      ]) {
        expect(track.left + blob.centerX, closeTo(item.center.dx, 1));
        expect(track.top + blob.centerY, closeTo(item.center.dy, 1));
        expect(
          blob.halfWidth * 2,
          closeTo(item.width + pad.left + pad.right, 1),
        );
        expect(
          blob.halfHeight * 2,
          closeTo(item.height + pad.top + pad.bottom, 1),
        );
        // And inside the track: the carve cannot be cut by the fill.
        expect(
          blob.centerY - blob.halfHeight,
          greaterThanOrEqualTo(-_kEpsilon),
        );
        expect(
          blob.centerY + blob.halfHeight,
          lessThanOrEqualTo(track.height + _kEpsilon),
        );
      }
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('the bar under a surface material', () {
    testWidgets('grows the same way under glass', (tester) async {
      await tester.pumpWidget(
        _app(
          _labelled(.md),
          scale: 2,
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      final bar = tester.getRect(_barFinder(tester));
      expect(bar.height, greaterThan(64));
      for (final label in _kLabels) {
        expect(_inside(tester.getRect(find.text(label)), bar), isTrue);
      }
    });
  });

  group('the density axis', () {
    for (final density in CoreDensity.values) {
      testWidgets('${density.name}: the minimum is the Core height', (
        tester,
      ) async {
        // The minimum is a Core value the component never bends; a density
        // moves the spacing around the row, not the bar's floor. An icon-only
        // bar fits inside it at every density.
        await tester.pumpWidget(_app(_labelled(.xs), density: density));
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.getSize(_barFinder(tester)).height, 48);
      });

      testWidgets('${density.name}: the plate stays inside a grown bar', (
        tester,
      ) async {
        // The room above and below the row follows the density, so a density
        // that opens the padding makes the bar taller by as much, and the
        // plate never hangs out of it.
        await tester.pumpWidget(
          _app(_labelled(.md), scale: 2, density: density),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        final bar = tester.getRect(_barFinder(tester));
        expect(bar.height, greaterThan(64));
        expect(
          _inside(tester.getRect(_pillFinders(tester).single), bar),
          isTrue,
        );

        final tallest = _itemRects(
          tester,
        ).map((r) => r.height).reduce(math.max);
        expect(
          bar.height,
          closeTo(
            tallest + 2 * _rowInset(.md, density: density) + 2 * _kBorder,
            _kEpsilon,
          ),
        );
      });
    }
  });
}
