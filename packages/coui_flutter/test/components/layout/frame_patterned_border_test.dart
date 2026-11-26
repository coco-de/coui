import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  for (final style in [
    CoreFrameBorderStyle.dashed,
    CoreFrameBorderStyle.dotted,
  ]) {
    for (final width in [
      CoreStrokeWidth.stroke1,
      CoreStrokeWidth.stroke2,
      CoreStrokeWidth.stroke4,
    ]) {
      for (final rounded in [false, true]) {
        // 1x preserves the original bounds check; 4x resolves 1px circles
        // whose fractional centres alias into a line at a 1x sample rate.
        for (final pixelRatio in [1.0, 4.0]) {
          testWidgets(
            '$style $width rounded=$rounded scale=$pixelRatio '
            'stays inside its border box',
            (tester) async {
              final boundaryKey = GlobalKey();
              final frameKey = GlobalKey();
              await pumpTestApp(
                tester,
                Center(
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: ColoredBox(
                      color: const Color(0xffffffff),
                      child: Padding(
                        padding: const EdgeInsets.all(CoreSpace.space16),
                        child: Frame(
                          key: frameKey,
                          width: CoreSpace.space80,
                          height: CoreSpace.space48,
                          borderColor: const CoreColor(0xffff0000),
                          borderWidth: width,
                          borderStyle: style,
                          borderRadius: rounded
                              ? const CoreBorderRadius.all(CoreRadius.radius16)
                              : null,
                          duration: Duration.zero,
                          clipBehavior: .none,
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final origin = tester.getTopLeft(find.byKey(boundaryKey));
              final logical = tester
                  .getRect(find.byKey(frameKey))
                  .shift(-origin);
              expect(
                logical.size,
                const Size(CoreSpace.space80, CoreSpace.space48),
              );
              final rect = Rect.fromLTWH(
                logical.left * pixelRatio,
                logical.top * pixelRatio,
                logical.width * pixelRatio,
                logical.height * pixelRatio,
              );
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await tester.runAsync(
                () => boundary.toImage(pixelRatio: pixelRatio),
              );
              final data = await tester.runAsync(
                () => image!.toByteData(),
              );
              final bytes = data!.buffer.asUint8List();
              var outsideInk = 0;
              var painted = 0;
              final topRows = <int>{};
              final dotXs = <int>{};
              for (var y = 0; y < image!.height; y++) {
                for (var x = 0; x < image.width; x++) {
                  final i = (y * image.width + x) * 4;
                  if (bytes[i] <= 192 ||
                      bytes[i + 1] >= 192 ||
                      bytes[i + 2] >= 192) {
                    continue;
                  }
                  painted++;
                  if (!rect.contains(Offset(x + 0.5, y + 0.5))) {
                    outsideInk++;
                  }
                  if (x >= rect.left + rect.width / 3 &&
                      x < rect.left + rect.width * 2 / 3 &&
                      y >= rect.top &&
                      y < rect.top + width * pixelRatio + 1) {
                    topRows.add(y);
                    if (y == rect.top.floor()) dotXs.add(x);
                  }
                }
              }
              expect(
                painted,
                greaterThan(0),
                reason: 'The border must still paint.',
              );
              expect(
                outsideInk,
                0,
                reason: 'The stroke belongs inside its allocated border box.',
              );
              expect(
                topRows,
                hasLength((width * pixelRatio).ceil()),
                reason:
                    'Clipping an outward stroke must not reduce its '
                    'visible thickness.',
              );
              if (style == CoreFrameBorderStyle.dotted && pixelRatio > 1) {
                var longest = 0;
                var run = 0;
                int? previous;
                for (final x in dotXs.toList()..sort()) {
                  run = previous == x - 1 ? run + 1 : 1;
                  if (run > longest) longest = run;
                  previous = x;
                }
                expect(dotXs, isNotEmpty);
                expect(
                  longest,
                  lessThanOrEqualTo((width * pixelRatio).ceil()),
                  reason: 'Round dots must not stretch into capsules.',
                );
              }
              image.dispose();
            },
          );
        }
      }
    }
  }

  testWidgets('a dash crossing a corner keeps both border legs', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const Frame(
        width: CoreSpace.space80,
        height: CoreSpace.space48,
        borderColor: CoreColor(0xffff0000),
        borderWidth: CoreStrokeWidth.stroke4,
        borderStyle: CoreFrameBorderStyle.dashed,
        duration: Duration.zero,
        child: SizedBox.shrink(),
      ),
    );
    final painter = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(Frame),
            matching: find.byType(CustomPaint),
          ),
        )
        .firstWhere((w) => w.foregroundPainter != null)
        .foregroundPainter!;
    final canvas = _RecordedBorderCanvas();
    painter.paint(canvas, const Size(CoreSpace.space80, CoreSpace.space48));
    // The 3/2 pattern reaches the top-right corner one pixel into this dash.
    final corner = canvas.path!.computeMetrics().firstWhere(
      (m) => m.getTangentForOffset(0)!.position == const Offset(77, 2),
    );
    expect(corner.length, 3);
    expect(corner.getTangentForOffset(1)!.position, const Offset(78, 2));
    expect(corner.getTangentForOffset(3)!.position, const Offset(78, 4));
  });

  testWidgets('one dash longer than the perimeter keeps the whole contour', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const Frame(
        width: CoreSpace.space80,
        height: CoreSpace.space48,
        borderColor: CoreColor(0xffff0000),
        borderWidth: CoreStrokeWidth.stroke2,
        borderStyle: CoreFrameBorderStyle.dashed,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        frameStyle: CoreFrameStyle(dashLength: 1000),
        duration: Duration.zero,
        child: SizedBox.shrink(),
      ),
    );
    final painter = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(Frame),
            matching: find.byType(CustomPaint),
          ),
        )
        .firstWhere((w) => w.foregroundPainter != null)
        .foregroundPainter!;
    final canvas = _RecordedBorderCanvas();
    painter.paint(canvas, const Size(CoreSpace.space80, CoreSpace.space48));
    expect(canvas.path!.getBounds(), const Rect.fromLTRB(1, 1, 79, 47));
  });

  testWidgets('dash traversal starts at the SVG rect top-left tangent', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const Frame(
        width: CoreSpace.space80,
        height: CoreSpace.space48,
        borderColor: CoreColor(0xffff0000),
        borderWidth: CoreStrokeWidth.stroke2,
        borderStyle: CoreFrameBorderStyle.dashed,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        duration: Duration.zero,
        child: SizedBox.shrink(),
      ),
    );
    final paint = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(Frame),
            matching: find.byType(CustomPaint),
          ),
        )
        .firstWhere((w) => w.foregroundPainter != null)
        .foregroundPainter!;
    final canvas = _RecordedBorderCanvas();
    paint.paint(canvas, const Size(CoreSpace.space80, CoreSpace.space48));
    final start = canvas.path!.computeMetrics().first.getTangentForOffset(0)!;
    expect(
      start.position,
      const Offset(
        CoreRadius.radius16,
        CoreStrokeWidth.stroke2 / 2,
      ),
    );
    expect(start.vector, const Offset(1, 0));
  });
}

class _RecordedBorderCanvas extends Fake implements Canvas {
  Path? path;

  @override
  void drawPath(Path path, Paint paint) =>
      (this.path ??= Path()).addPath(path, .zero);

  @override
  void drawLine(Offset from, Offset to, Paint paint) {
    (path ??= Path())
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);
  }
}
