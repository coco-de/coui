import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

// What a pagination cell's box paints (#5638).
//
// Web draws a resting cell as bare text and so does the Figma set; the
// fill is the only thing a cell states, and only when it is the current
// page or hovered. Flutter composes `OutlinedContainer` for the box, which
// fills in whatever a box leaves unsaid — a default stroke colour, and the
// style's own cast — so a cell that states only `borderWidth: 0` still paints
// a hairline (Flutter reads a zero-width solid side as one device pixel) and,
// under a style with a cast, a shadow the Web twin never draws.
//
// Reading the box's `BoxDecoration` is the same thing the screen shows: the
// decoration is what the engine paints, so a resolved value that looks right
// but is not what reaches it cannot pass here.

// Wide enough that the first step of the compaction ladder (the full row)
// is the one shown — the claim is about each cell, not about fitting.
const _kViewSize = Size(1600, 400);

// Page 3 of 10 at the default window of 3 shows every kind of cell:
// ‹ … 2 [3] 4 … 10 ›.
Future<void> _pump(
  WidgetTester tester,
  CoreSurfaceStyleId style, {
  bool showLabel = false,
}) async {
  tester.view
    ..physicalSize = _kViewSize
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: Center(
        child: Pagination(
          page: 3,
          totalPages: 10,
          showLabel: showLabel,
          onPageChanged: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The decoration the cell holding [content] paints.
///
/// `OutlinedContainer`'s outermost `AnimatedContainer` carries the border,
/// radius, fill and cast. Its `decoration` is the target value, so it needs
/// no settling to be read.
BoxDecoration _paint(WidgetTester tester, Finder content) {
  final face = find
      .ancestor(of: content, matching: find.byType(OutlinedContainer))
      .first;
  final box = find
      .descendant(of: face, matching: find.byType(AnimatedContainer))
      .first;
  return tester.widget<AnimatedContainer>(box).decoration! as BoxDecoration;
}

/// A solid side with any alpha is painted — and a zero *width* does not
/// make it vanish: Flutter draws it as a hairline.
bool _strokeVisible(BoxDecoration decoration) {
  final border = decoration.border;
  if (border is! Border) return false;
  return [border.top, border.right, border.bottom, border.left].any(
    (side) => side.style == BorderStyle.solid && side.color.a > 0,
  );
}

void _expectBare(BoxDecoration decoration, String cell) {
  expect(
    _strokeVisible(decoration),
    isFalse,
    reason: '$cell paints a stroke: ${decoration.border}',
  );
  expect(
    decoration.boxShadow ?? const <BoxShadow>[],
    isEmpty,
    reason: "$cell paints the style's cast",
  );
}

void main() {
  for (final style in CoreSurfaceStyleId.values) {
    group('pagination cells under ${style.name}', () {
      testWidgets('a resting cell paints only its (absent) fill', (
        tester,
      ) async {
        await _pump(tester, style);

        final cells = {
          'page 2': find.text('2'),
          'page 4': find.text('4'),
          'edge page 10': find.text('10'),
          'leading ellipsis': find.text('…').first,
          'trailing ellipsis': find.text('…').last,
          'previous': find.byType(Icon).first,
          'next': find.byType(Icon).last,
        };
        for (final MapEntry(:key, :value) in cells.entries) {
          final decoration = _paint(tester, value);
          _expectBare(decoration, key);
          expect(
            decoration.color?.a ?? 0,
            0,
            reason: '$key states a fill it should not',
          );
        }
      });

      testWidgets('a labelled previous / next is as bare as the icon one', (
        tester,
      ) async {
        await _pump(tester, style, showLabel: true);

        _expectBare(_paint(tester, find.text('Previous')), 'labelled previous');
        _expectBare(_paint(tester, find.text('Next')), 'labelled next');
      });

      testWidgets('a hovered cell keeps its fill and gains nothing else', (
        tester,
      ) async {
        // The mouse has to be connected before the cell mounts:
        // `Clickable` reads the focus-highlight mode once, in its first
        // post-frame callback, and a pointer that arrives later never
        // switches it to mouse mode — the hover would silently not engage.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await _pump(tester, style);

        expect(
          _paint(tester, find.text('2')).color?.a ?? 0,
          0,
          reason: 'the cell is not resting before the pointer arrives',
        );
        await mouse.moveTo(tester.getCenter(find.text('2')));
        await tester.pumpAndSettle();

        final decoration = _paint(tester, find.text('2'));
        _expectBare(decoration, 'hovered page 2');
        // The control: if the hover never engaged, the cell would still be
        // bare and the line above would pass for the wrong reason.
        expect(
          decoration.color?.a ?? 0,
          greaterThan(0),
          reason: 'the hover did not engage — nothing was tested',
        );
      });

      testWidgets('the current page keeps its fill and nothing else', (
        tester,
      ) async {
        await _pump(tester, style);

        // Web's current page carries the surface marker (a material can
        // reach its fill) but no control-shadow marker, so it paints no
        // cast either — the fill is the only thing it states.
        final decoration = _paint(tester, find.text('3'));
        _expectBare(decoration, 'the current page');
        expect(decoration.color?.a ?? 0, greaterThan(0));
      });
    });
  }
}
