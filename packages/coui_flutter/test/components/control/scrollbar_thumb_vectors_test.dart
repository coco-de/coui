// Flutter is the reference for where a Scrollbar thumb sits. Web draws its
// thumb itself and computes the position with CoreScrollbarThumbLayout, so
// that arithmetic is only right if it agrees with what Flutter's
// ScrollbarPainter does — and this is the test that asks the painter.
//
// It reads the same vector table the Core and Web tests read: the table is the
// one statement of the arithmetic, and each platform is held to it.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const String _kVectorsPath =
    '../coui_core/test/fixtures/scrollbar_thumb_vectors.json';

/// Records the thumb a [ScrollbarPainter] draws.
class _RecordingCanvas implements ui.Canvas {
  final List<ui.RRect> thumbs = [];

  @override
  void drawRRect(ui.RRect rrect, ui.Paint paint) => thumbs.add(rrect);

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

/// The thumb Flutter's painter draws for one vector, or null when it draws
/// none.
ui.RRect? _paintedThumb(Map<String, Object?> c) {
  final viewport = (c['viewport']! as num).toDouble();
  final content = (c['content']! as num).toDouble();
  final painter =
      ScrollbarPainter(
        color: const ui.Color(0xFF000000),
        fadeoutOpacityAnimation: const AlwaysStoppedAnimation<double>(1),
        textDirection: TextDirection.ltr,
        // A radius makes the painter draw the thumb as an rrect, which is what
        // the recording canvas picks up.
        radius: const ui.Radius.circular(3),
        mainAxisMargin: (c['margin']! as num).toDouble(),
        crossAxisMargin: 2,
        minLength: (c['minLength']! as num).toDouble(),
      )..update(
        FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: content - viewport,
          pixels: (c['scrollOffset']! as num).toDouble(),
          viewportDimension: viewport,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1,
        ),
        AxisDirection.down,
      );
  final canvas = _RecordingCanvas();
  painter.paint(canvas, ui.Size(20, viewport));

  return canvas.thumbs.isEmpty ? null : canvas.thumbs.single;
}

void main() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  final tolerance = (doc['tolerance']! as num).toDouble();
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  group('Flutter ScrollbarPainter against the shared thumb vectors', () {
    for (final c in cases) {
      test(c['name']! as String, () {
        final thumb = _paintedThumb(c);
        final expected = c['expected'] as Map<String, Object?>?;
        if (expected == null) {
          expect(thumb, isNull);

          return;
        }
        expect(thumb, isNotNull);
        expect(
          thumb!.height,
          closeTo((expected['extent']! as num).toDouble(), tolerance),
        );
        expect(
          thumb.top,
          closeTo((expected['offset']! as num).toDouble(), tolerance),
        );
      });
    }
  });

  group('tapping the track pages by the shared fraction', () {
    // The distance is a contract constant so Web pages the same amount; this
    // pins it to what RawScrollbar really does.
    testWidgets('a mouse tap beyond the thumb moves the content one page', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 300,
            height: 300,
            child: Scrollbar(
              controller: controller,
              visibility: CoreScrollbarVisibility.always,
              child: ListView.builder(
                controller: controller,
                itemBuilder: (_, i) =>
                    SizedBox(height: 40, child: Text('Item $i')),
                itemCount: 50,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final origin = tester.getTopLeft(find.byType(Scrollbar));
      // Inside the bar, below the thumb that rests at the top.
      await tester.tapAt(
        origin + const Offset(300 - 5, 280),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(
        controller.offset,
        300 * CoreScrollbarContract.trackTapPageFraction,
      );
    });
  });
}
