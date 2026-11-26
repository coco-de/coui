// A selection that crosses the fade edge of a `FadeScroll`: the rows under
// the fade stay selectable, and their highlight fades exactly like every
// other pixel the mask covers — which is what the browser does to
// `::selection` under the Web twin's `mask-image`.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _kViewport = 200.0;
const _kRowHeight = 20.0;
const _kRowCount = 30;
const _kGlyphsPerRow = 10;

/// Opaque and saturated, so a fade reads as a plain drop in the green and
/// blue channels against the white page.
const _kHighlight = Color(0xFFFF0000);
const _kPage = Color(0xFFFFFFFF);

/// Glyphs are painted transparent — and without the fallback underline a
/// `DefaultTextStyle`-less test tree inherits — so the only thing a sampled
/// pixel can show is the selection highlight behind them.
const _kInvisibleGlyphs = TextStyle(
  color: Color(0x00000000),
  decoration: .none,
  fontSize: _kRowHeight,
  height: 1,
);

/// Allowed per-channel difference between two rasterisations of the same
/// mask — anti-aliasing at the ramp, nothing structural.
const _kChannelTolerance = 2;

Widget _scene({
  required GlobalKey boundary,
  required Widget content,
  ValueChanged<String?>? onSelectionChanged,
}) {
  return material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: Center(
        child: RepaintBoundary(
          key: boundary,
          child: ColoredBox(
            color: _kPage,
            child: SizedBox.square(
              dimension: _kViewport,
              child: DefaultSelectionStyle(
                selectionColor: _kHighlight,
                child: material.SelectionArea(
                  onSelectionChanged: (content) =>
                      onSelectionChanged?.call(content?.plainText),
                  child: FadeScroll(child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _rows() => Column(
  crossAxisAlignment: .stretch,
  children: [
    for (var i = 0; i < _kRowCount; i++)
      SizedBox(
        height: _kRowHeight,
        child: Text('X' * _kGlyphsPerRow, style: _kInvisibleGlyphs),
      ),
  ],
);

/// A solid block of the highlight colour the height of the rows: it goes
/// through the same mask and shows what the mask does to *any* content.
Widget _solidBlock() => const ColoredBox(
  color: _kHighlight,
  child: SizedBox(
    height: _kRowCount * _kRowHeight,
    width: double.infinity,
  ),
);

/// One column of RGBA pixels, top to bottom, through the middle of the
/// viewport.
Future<List<(int, int, int)>> _column(
  WidgetTester tester,
  GlobalKey boundary,
) async {
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final pixels = await tester.runAsync(() async {
    final image = await render.toImage();
    final data = (await image.toByteData())!;
    final x = image.width ~/ 2;

    return [
      for (var y = 0; y < image.height; y++)
        (
          data.getUint8((y * image.width + x) * 4),
          data.getUint8((y * image.width + x) * 4 + 1),
          data.getUint8((y * image.width + x) * 4 + 2),
        ),
    ];
  });

  return pixels!;
}

Future<void> _dragAcross(WidgetTester tester, GlobalKey boundary) async {
  final origin = tester.getTopLeft(find.byKey(boundary));
  final gesture = await tester.startGesture(
    origin + const Offset(1, 1),
    kind: .mouse,
  );
  await tester.pump();
  await gesture.moveTo(origin + const Offset(_kViewport - 1, _kViewport - 1));
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  group('FadeScroll under SelectionArea', () {
    testWidgets('a drag across the faded edge selects the rows beneath it', (
      tester,
    ) async {
      final boundary = GlobalKey();
      String? selected;
      await tester.pumpWidget(
        _scene(
          boundary: boundary,
          content: _rows(),
          onSelectionChanged: (text) => selected = text,
        ),
      );
      // The mask arrives on the frame after the scroll position attaches.
      await tester.pump();

      expect(find.byType(ShaderMask), findsOneWidget);

      await _dragAcross(tester, boundary);

      // Every row the drag passed over — including the last two, which sit
      // inside the default 40px end fade — is part of the selection.
      const visibleRows = _kViewport ~/ _kRowHeight;
      expect(
        'X'.allMatches(selected ?? '').length,
        visibleRows * _kGlyphsPerRow,
      );
    });

    testWidgets(
      'the highlight fades exactly as the mask fades any other content',
      (tester) async {
        final boundary = GlobalKey();

        await tester.pumpWidget(
          _scene(boundary: boundary, content: _solidBlock()),
        );
        await tester.pump();
        final reference = await _column(tester, boundary);

        await tester.pumpWidget(
          _scene(boundary: boundary, content: _rows()),
        );
        await tester.pump();
        await _dragAcross(tester, boundary);
        final highlight = await _column(tester, boundary);

        // The sample has to span the ramp for the comparison below to mean
        // anything: solid at the top, partly faded near the end edge.
        expect(reference.first, (0xFF, 0, 0));
        expect(
          reference.any((p) => p.$2 > 0x20 && p.$2 < 0xE0),
          isTrue,
          reason: 'the end fade should be inside the sampled column',
        );

        // Row by row the highlight matches the masked block: fully present
        // where the mask is opaque, faded by the same amount inside the
        // ramp, and never darker — a dark seam is the failure the upstream
        // RenderParagraph fix (flutter/flutter#183628) removed on its own,
        // different, TextOverflow.fade path.
        for (var y = 0; y < reference.length; y++) {
          final (r, g, b) = highlight[y];
          final (er, eg, eb) = reference[y];
          expect(
            (r - er).abs() <= _kChannelTolerance &&
                (g - eg).abs() <= _kChannelTolerance &&
                (b - eb).abs() <= _kChannelTolerance,
            isTrue,
            reason:
                'row $y: highlight ($r, $g, $b) vs masked block '
                '($er, $eg, $eb)',
          );
        }
      },
    );
  });
}
