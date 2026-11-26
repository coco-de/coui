import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
// `Table` is a CoUI component and a Flutter widget both — the barrel
// hides the framework one, so it is the only widgets import here.
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

/// The two platforms disagree about where a cast is painted, and the
/// disagreement is invisible until the fill over it is not opaque.
///
/// CSS clips an outer `box-shadow` to outside the border box. Flutter's
/// `BoxDecoration.boxShadow` draws a *filled* rounded rect behind the box
/// and lets the background paint over it. A surface that states no fill —
/// a table reads on whatever it lands on, an outline badge is its border —
/// has nothing painting over it, so under a style whose cast is opaque
/// and hard-edged the whole box came out solid black. Only on Flutter.
///
/// Two tests, because they fail for different reasons and neither
/// substitutes for the other: one reads the pixels of the reported case,
/// the other states the invariant over every surface that takes a cast so
/// a component added later cannot repeat it quietly.

// ── The reported case, in painted output ───────────────────────────

/// Named once so the pixel probe and the rect it samples cannot drift
/// onto different widgets.
final Finder _table = find.byType(Table);

/// A table with one header row and one body row, as in the report.
List<CoreTableRowData<Widget>> _rows() => [
  CoreTableRowData.header(
    cells: [CoreTableCellData(child: const SizedBox(width: 120, height: 24))],
  ),
  CoreTableRowData(
    cells: [CoreTableCellData(child: const SizedBox(width: 120, height: 24))],
  ),
];

/// Renders the table under [style] and reads its pixels back, with the
/// rect it landed in.
///
/// The question — is the inside of the box the cast's colour — is only
/// answerable in painted output. Every structural assertion available
/// here passed while the bug was on screen.
///
/// Painted over an opaque page on purpose. The body row states no fill,
/// so on a transparent ground "nothing painted" and "painted black" are
/// the same zero in the colour channels, and the probe could not tell the
/// bug from a table that failed to render. The rect comes back with the
/// image because the row to sample is a fraction of the box, not a fixed
/// coordinate.
Future<({ui.Image image, Rect rect})> _render(
  WidgetTester tester,
  CoreSurfaceStyleId style,
) async {
  final key = GlobalKey();

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: Align(
        alignment: Alignment.topLeft,
        // The boundary sits at the origin, so image coordinates and
        // global ones are the same number at this device pixel ratio.
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Table(rows: _rows()),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  return (image: await boundary.toImage(), rect: tester.getRect(_table));
}

/// The red channel at ([x], [y]) — a stand-in for luminance, since every
/// colour in play here is neutral.
Future<int> _luminanceAt(ui.Image image, int x, int y) async {
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;

  return data.getUint8((y * image.width + x) * 4);
}

// ── The invariant, over every surface that takes a cast ────────────

typedef _Surface = ({String name, Widget child});

/// One entry per surface whose fill can be non-opaque under some state.
///
/// The list is the ones that were wrong, plus the filled neighbours they
/// share a widget with — a per-variant branch is how this went wrong the
/// first time, so the filled branch is held to the same rule rather than
/// left to a different one.
final _surfaces = <_Surface>[
  (name: 'Table', child: const Table(rows: [])),
  (
    name: 'ResizableTable',
    child: ResizableTable(
      rows: const [],
      controller: ResizableTableController(
        defaultColumnWidth: 100,
        defaultRowHeight: 40,
      ),
    ),
  ),
  // `EmptyState` no longer belongs here — the 2026-09-14 redesign drops
  // its box entirely (no border / radius / background), so it casts
  // nothing at all any more, not even via `InjectedCast`.
  // `filled` (the default) is opaque in every state, so its cast stays in
  // the composed container's decoration and there is nothing to inject;
  // `outlined` is the variant whose fill is the transparent sentinel.
  (
    name: 'Fieldset/outlined',
    child: const Fieldset(variant: .outlined, children: [Text('f')]),
  ),
  (name: 'Chip', child: const Chip(label: 'c')),
  (
    name: 'Badge/outlined',
    child: const Badge(variant: .outlined, child: Text('b')),
  ),
  (
    name: 'Badge/tonal',
    child: const Badge(child: Text('b')),
  ),
  (
    name: 'Badge/filled',
    child: const Badge(variant: .filled, child: Text('b')),
  ),
  (
    name: 'Tabs/underline',
    child: const Tabs(
      tabs: [CoreTabItem<Widget>(label: 'a')],
      selectedIndex: 0,
      variant: .underline,
    ),
  ),
  (
    name: 'Tabs/pill',
    child: const Tabs(
      tabs: [CoreTabItem<Widget>(label: 'a')],
      selectedIndex: 0,
    ),
  ),
];

/// Every decoration under [of] that draws a shadow behind a fill which is
/// not opaque.
///
/// This is the defect itself, stated as a query: a shadow in a
/// `BoxDecoration` is drawn behind the box, so a fill that does not cover
/// it lets it through. Returns the offending fills so a failure names
/// what it found.
List<Color?> _castsBehindNonOpaqueFill(WidgetTester tester, Finder of) => tester
    .widgetList<Widget>(
      find.descendant(of: of, matching: find.byWidgetPredicate((_) => true)),
    )
    .map(
      (w) => switch (w) {
        Container(:final decoration) => decoration,
        AnimatedContainer(:final decoration) => decoration,
        DecoratedBox(:final decoration) => decoration,
        _ => null,
      },
    )
    .whereType<BoxDecoration>()
    .where((d) => (d.boxShadow ?? const <BoxShadow>[]).isNotEmpty)
    .where((d) => d.color == null || d.color!.a < 1)
    .map((d) => d.color)
    .toList();

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('an unfilled surface does not show its own cast', () {
    testWidgets('a table body stays light under a hard opaque cast', (
      tester,
    ) async {
      late int body;
      late int plain;

      // Three quarters down the box and centred: that is the body row,
      // below the header — which carries its own opaque fill and was
      // never affected, which is why the report shows a grey header over
      // a black body.
      Future<int> sampleBody(CoreSurfaceStyleId style) async {
        final shot = await _render(tester, style);

        return _luminanceAt(
          shot.image,
          shot.rect.center.dx.round(),
          (shot.rect.top + shot.rect.height * 0.75).round(),
        );
      }

      await tester.runAsync(() async {
        body = await sampleBody(.neoBrutalism);
        // The same point under a style that injects no cast at all. The
        // control matters: without it a test that passes because the body
        // is light reads the same as one that passes because the table
        // failed to render.
        plain = await sampleBody(.defaultStyle);
      });

      expect(
        plain,
        greaterThan(128),
        reason: 'the control must be a light body, or this proves nothing',
      );
      expect(
        body,
        plain,
        reason:
            'the body is the page colour under both styles — the cast '
            'belongs outside the box, and a bleed painted it near-black',
      );
    });

    for (final surface in _surfaces) {
      testWidgets('${surface.name} keeps its cast out of the decoration', (
        tester,
      ) async {
        await _pump(tester, surface.child);

        // A cast in a decoration is only safe where the fill over it is
        // opaque in every state. These surfaces are the ones where it is
        // not, so for them the cast belongs on `InjectedCast`, which
        // knocks the box out of the shadow the way CSS does.
        expect(
          _castsBehindNonOpaqueFill(tester, find.byWidget(surface.child)),
          isEmpty,
          reason:
              'a shadow behind a fill that does not cover it shows '
              'through the box',
        );

        // And it must still take the cast — moving where it is painted
        // must not drop it. Without this the test above is satisfied by a
        // component that casts nothing at all.
        expect(
          tester
              .widgetList<InjectedCast>(
                find.descendant(
                  of: find.byWidget(surface.child),
                  matching: find.byType(InjectedCast),
                ),
              )
              .expand((c) => c.shadows),
          isNotEmpty,
        );
      });
    }
  });
}
