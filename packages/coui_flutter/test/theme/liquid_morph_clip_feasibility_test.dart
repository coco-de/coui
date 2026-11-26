// Can a glass surface be carved into an arbitrary shape without losing the
// glass? Measured in pixels, because the Web half of this question already
// answered "not the obvious way".
//
// The morph this gates wants a metaball silhouette — two rounded rects
// merged by a smooth union, with a neck between them. On Web the naive
// route (a gooey `filter` on an ancestor) was measured and it **kills**
// `backdrop-filter`: the ancestor filter establishes a new backdrop root,
// so the panel samples the already-filtered ancestor instead of the page
// and renders opaque. Carving the shape instead — `clip-path` or `mask` —
// left the glass intact.
//
// Flutter's shipped surface already paints its blur inside a `ClipRRect`,
// so clipping and blurring compose there for *rounded rects*. That is not
// the same statement as "an arbitrary path composes": rounded rects have
// their own fast path in the compositor, and a path clip is a different
// layer. If a path clip dropped the backdrop the way an ancestor filter
// does on Web, the whole shared-outline design would be unbuildable on the
// platform that is supposed to be the easy one.
//
// This measures the difference between a blurred capture and an unblurred
// one through the same clip. It does not measure the silhouette — that is
// the outline math's job, and it does not exist yet.
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A deliberately non-rectangular clip — two overlapping circles, which is
/// the shape family the morph produces before its neck is smoothed.
class _TwoCirclesClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final r = size.height / 2;

    return Path()
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r))
      ..addOval(
        Rect.fromCircle(center: Offset(size.width - r, r), radius: r),
      );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// The backdrop: hard stripes, so a blur is decidable without pinning a
/// colour. A blur of a smooth gradient is very nearly the gradient again.
class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var x = 0.0; x < size.width; x += 24) {
      paint.color = const Color(0xFF000000);
      canvas.drawRect(Rect.fromLTWH(x, 0, 12, size.height), paint);
      paint.color = const Color(0xFFFFFFFF);
      canvas.drawRect(Rect.fromLTWH(x + 12, 0, 12, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _kCaptureKey = ValueKey<String>('capture');
const _kSize = Size(240, 120);

/// How many coarse luminance buckets the capture occupies.
///
/// Sharp stripes land in two; the same stripes under a blur land in many.
/// The same ruler the Web probes use, for the same reason — it decides
/// "is this blurred" without hardcoding a colour.
Future<int> _luminanceBuckets(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_kCaptureKey),
  );
  // Inside `runAsync`, deliberately. Rasterising is real async work, and a
  // widget test's fake-async zone never advances it — awaiting `toImage`
  // outside this hangs the test rather than failing it, which is a much
  // worse thing to leave for someone else to debug.
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    return data!.buffer.asUint8List();
  });

  final seen = <int>{};
  for (var i = 0; i < bytes!.length; i += 4) {
    final luminance =
        (bytes[i] * 0.213 + bytes[i + 1] * 0.715 + bytes[i + 2] * 0.072)
            .round();
    seen.add(luminance >> 3);
  }

  return seen.length;
}

Future<void> _pump(WidgetTester tester, {required bool blurred}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: _kCaptureKey,
          child: SizedBox(
            width: _kSize.width,
            height: _kSize.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _StripesPainter()),
                ClipPath(
                  clipper: _TwoCirclesClipper(),
                  child: blurred
                      ? BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: const SizedBox.expand(),
                        )
                      : const SizedBox.expand(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a path-clipped surface keeps its backdrop', () {
    testWidgets('control — the same clip without a blur stays sharp', (
      tester,
    ) async {
      // The floor. If the harness could not render the stripes at all,
      // the comparison below would be between two blank captures and
      // would report a blur that never happened.
      await _pump(tester, blurred: false);

      expect(await _luminanceBuckets(tester), lessThan(8));
    });

    testWidgets('and with one, the backdrop is actually blurred', (
      tester,
    ) async {
      // The gate for the whole shared-outline design: if an arbitrary path
      // clip dropped the backdrop the way an ancestor `filter` does on Web,
      // Flutter could not carve a morph silhouette out of a glass surface
      // and the two platforms would need different mechanisms.
      await _pump(tester, blurred: true);

      expect(
        await _luminanceBuckets(tester),
        greaterThan(12),
        reason: 'a path clip dropped the backdrop the blur was sampling',
      );
    });
  });
}
