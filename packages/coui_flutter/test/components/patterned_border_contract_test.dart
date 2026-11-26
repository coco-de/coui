import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

enum _Target { outlinedDashed, outlinedDotted, fileInput, colorPicker }

Widget _subject(_Target target) => switch (target) {
  _Target.outlinedDashed || _Target.outlinedDotted => SizedBox(
    width: CoreSpace.space80,
    height: CoreSpace.space48,
    child: OutlinedContainer(
      containerStyle: CoreOutlinedContainerStyle(
        borderStyle: target == _Target.outlinedDotted ? .dotted : .dashed,
        borderColor: const CoreColor(0xffff0000),
        borderWidth: CoreStrokeWidth.stroke2,
        borderRadius: const CoreBorderRadius.all(CoreRadius.radius16),
      ),
      child: const SizedBox.shrink(),
    ),
  ),
  _Target.fileInput => const SizedBox(
    width: 600,
    child: FileInput(
      fileInputStyle: CoreFileInputStyle(
        borderColor: CoreColor(0xffff0000),
        borderWidth: CoreStrokeWidth.stroke2,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
      ),
    ),
  ),
  _Target.colorPicker => const ColorPicker(
    color: Color(0x00000000),
    enabled: false,
    showHexInput: false,
    showLabel: false,
    colorPickerStyle: CoreColorPickerStyle(
      borderColor: CoreColor(0xffff0000),
      disabledBorderColor: CoreColor(0xffff0000),
      borderWidth: CoreStrokeWidth.stroke2,
      swatchBorderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  ),
};

Future<CustomPainter> _painter(WidgetTester tester, _Target target) async {
  final key = GlobalKey();
  await pumpTestApp(tester, KeyedSubtree(key: key, child: _subject(target)));
  await tester.pumpAndSettle();
  final painters = tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((widget) => widget.foregroundPainter ?? widget.painter)
      .nonNulls;
  expect(painters, isNotEmpty);
  return painters.first;
}

void main() {
  testWidgets('FileInput drag-over keeps the same outer corner radius', (
    tester,
  ) async {
    await _painter(tester, _Target.fileInput);
    tester.widget<DropTarget>(find.byType(DropTarget)).onDragEntered!(
      DropEventDetails(localPosition: Offset.zero, globalPosition: Offset.zero),
    );
    await tester.pumpAndSettle();
    final widget = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(FileInput),
            matching: find.byType(CustomPaint),
          ),
        )
        .firstWhere((w) => w.painter != null);
    final canvas = _RecordedCanvas();
    widget.painter!.paint(
      canvas,
      const Size(CoreSpace.space80, CoreSpace.space48),
    );
    expect(canvas.solid, isNotNull);
    expect(canvas.solid!.outerRect, const Rect.fromLTRB(1, 1, 79, 47));
    expect(
      canvas.solid!.tlRadiusX,
      CoreRadius.radius16 - CoreStrokeWidth.stroke2 / 2,
    );
  });

  for (final target in _Target.values) {
    testWidgets('$target follows the outer radius and SVG contour origin', (
      tester,
    ) async {
      final painter = await _painter(tester, target);
      final canvas = _RecordedCanvas();
      painter.paint(canvas, const Size(CoreSpace.space80, CoreSpace.space48));
      if (target == _Target.outlinedDotted) {
        expect(
          canvas.dots,
          isNotEmpty,
          reason: 'Dotted strokes paint circles.',
        );
        expect(canvas.dots.first, const Offset(CoreRadius.radius16, 1));
        expect(canvas.dots[1] - canvas.dots.first, const Offset(4, 0));
      } else {
        final start = canvas.path.computeMetrics().first.getTangentForOffset(
          0,
        )!;
        expect(start.position, const Offset(CoreRadius.radius16, 1));
        expect(start.vector, const Offset(1, 0));
      }
    });

    testWidgets('$target keeps full stroke inside its allocated box', (
      tester,
    ) async {
      final painter = await _painter(tester, target);
      const scale = 4.0;
      const margin = CoreSpace.space16;
      const size = Size(CoreSpace.space80, CoreSpace.space48);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..scale(scale)
        ..drawColor(const Color(0xffffffff), .src)
        ..translate(margin, margin);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await tester.runAsync(
        () => picture.toImage(
          ((size.width + margin * 2) * scale).toInt(),
          ((size.height + margin * 2) * scale).toInt(),
        ),
      );
      final data = await tester.runAsync(() => image!.toByteData());
      final bytes = data!.buffer.asUint8List();
      final rect = Rect.fromLTWH(
        margin * scale,
        margin * scale,
        size.width * scale,
        size.height * scale,
      );
      var ink = 0;
      var outside = 0;
      final topRows = <int>{};
      final dotXs = <int>{};
      for (var y = 0; y < image!.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final i = (y * image.width + x) * 4;
          if (bytes[i] <= 192 || bytes[i + 1] >= 192 || bytes[i + 2] >= 192) {
            continue;
          }
          ink++;
          if (!rect.contains(Offset(x + 0.5, y + 0.5))) {
            outside++;
          }
          if (x >= rect.left + rect.width / 3 &&
              x < rect.left + rect.width * 2 / 3 &&
              y >= rect.top &&
              y < rect.top + CoreStrokeWidth.stroke2 * scale + 1) {
            topRows.add(y);
            if (y == rect.top.toInt()) dotXs.add(x);
          }
        }
      }
      expect(ink, greaterThan(0));
      expect(outside, 0);
      expect(topRows, hasLength((CoreStrokeWidth.stroke2 * scale).toInt()));
      if (target == _Target.outlinedDotted) {
        var longest = 0;
        var run = 0;
        int? previous;
        for (final x in dotXs.toList()..sort()) {
          run = previous == x - 1 ? run + 1 : 1;
          if (run > longest) longest = run;
          previous = x;
        }
        expect(dotXs, isNotEmpty);
        expect(longest, lessThanOrEqualTo(CoreStrokeWidth.stroke2 * scale));
      }
      image.dispose();
      picture.dispose();
    });
  }
}

class _RecordedCanvas extends Fake implements Canvas {
  final path = Path();
  final dots = <Offset>[];
  RRect? solid;

  @override
  void drawRRect(RRect value, Paint paint) => solid = value;

  @override
  void drawPath(Path value, Paint paint) => path.addPath(value, .zero);

  @override
  void drawLine(Offset from, Offset to, Paint paint) => path
    ..moveTo(from.dx, from.dy)
    ..lineTo(to.dx, to.dy);

  @override
  void drawCircle(Offset center, double radius, Paint paint) =>
      dots.add(center);
}
