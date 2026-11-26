import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Room around the outline so the ring paints inside the captured
/// boundary rather than being clipped off its edge.
const double _kPad = 20;

/// Bytes per pixel in the captured `rawRgba` buffer.
const int _kStride = 4;

const Size _kChild = Size(100, 40);

/// An opaque band colour no theme token produces, so a pixel of it can
/// only have come from the band layer.
const CoreColor _kBand = CoreColor(0xFFFF0000);

final GlobalKey _boundaryKey = GlobalKey(debugLabel: 'boundary');
final GlobalKey _childKey = GlobalKey(debugLabel: 'child');

/// One rendered frame, read back as pixels.
///
/// "Where does the band paint" is only answerable in painted output: a
/// band drawn as a filled box behind the child and a band drawn as a
/// stroke around it produce the same widget tree shape and the same
/// colour value, and differ only in which pixels they cover.
class _Shot {
  const _Shot(this.bytes, this.width, this.child);

  final ByteData bytes;
  final int width;

  /// The child's rect in boundary-local coordinates.
  final Rect child;

  int _offset(int x, int y) => ((y * width) + x) * _kStride;

  /// The pixel at ([x], [y]) as `0xRRGGBBAA`.
  int rgbaAt(int x, int y) => bytes.getUint32(_offset(x, y));

  int alphaAt(int x, int y) => bytes.getUint8(_offset(x, y) + 3);
}

Future<_Shot> _shoot(
  WidgetTester tester, {
  required CoreFocusOutlineShape shape,
  CoreFocusOutlineStyle? style,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: .ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Theme(
          data: const ThemeData(),
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: _boundaryKey,
              child: Padding(
                padding: const .all(_kPad),
                child: FocusOutline(
                  focused: true,
                  shape: shape,
                  focusOutlineStyle: style,
                  // Paints nothing — a stand-in for a control whose body
                  // is transparent (a ghost or plain button).
                  child: SizedBox(
                    key: _childKey,
                    width: _kChild.width,
                    height: _kChild.height,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final _ = await tester.pumpAndSettle();

  final boundaryRect = tester.getRect(find.byKey(_boundaryKey));
  final childRect = tester.getRect(find.byKey(_childKey));
  final render =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  late ByteData bytes;
  late int width;
  await tester.runAsync(() async {
    final image = await render.toImage();
    width = image.width;
    bytes = (await image.toByteData())!;
    image.dispose();
  });

  return _Shot(bytes, width, childRect.shift(-boundaryRect.topLeft));
}

/// Every pixel inside the child's own rounded shape (corner [radius])
/// that something painted. The shape is pulled in by one pixel so the
/// anti-aliased seam the band shares with the child does not count.
int _paintedInsideChild(_Shot shot, double radius) {
  final shape = RRect.fromRectAndRadius(
    shot.child,
    Radius.circular(radius),
  ).deflate(1);
  var count = 0;
  for (var y = shot.child.top.ceil(); y < shot.child.bottom.floor(); y++) {
    for (var x = shot.child.left.ceil(); x < shot.child.right.floor(); x++) {
      if (!shape.contains(Offset(x + 0.5, y + 0.5))) continue;
      if (shot.alphaAt(x, y) > 0) count++;
    }
  }

  return count;
}

void main() {
  for (final shape in CoreFocusOutlineShape.values) {
    testWidgets('zero-width ring paints nothing for ${shape.name}', (
      tester,
    ) async {
      final shot = await _shoot(
        tester,
        shape: shape,
        style: const CoreFocusOutlineStyle(
          align: 0,
          borderWidth: 0,
          borderColor: CoreColor(0xFFFF0000),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        ),
      );
      var painted = 0;
      for (
        var offset = 3;
        offset < shot.bytes.lengthInBytes;
        offset += _kStride
      ) {
        if (shot.bytes.getUint8(offset) != 0) painted++;
      }
      expect(
        painted,
        0,
        reason: 'zero width must not draw a device-pixel hairline',
      );
      expect(shot.child.size, _kChild);
    });
  }
  testWidgets('zero-width ring preserves an explicitly painted gap band', (
    tester,
  ) async {
    final shot = await _shoot(
      tester,
      shape: .rectangle,
      style: const CoreFocusOutlineStyle(
        align: 4,
        borderWidth: 0,
        offsetColor: _kBand,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      ),
    );
    expect(
      shot.rgbaAt(shot.child.left.floor() - 1, shot.child.center.dy.floor()),
      0xFF0000FF,
    );
    expect(_paintedInsideChild(shot, CoreRadius.radius8), 0);
    expect(shot.child.size, _kChild);
  });
  group('FocusOutline gap band', () {
    for (final shape in CoreFocusOutlineShape.values) {
      testWidgets(
        'never paints inside the child — ${shape.name}',
        (tester) async {
          // Rounded so the child's own corner region is in play: the
          // band's inner edge must land on the child's corner, not on
          // its bounding box.
          final shot = await _shoot(
            tester,
            shape: shape,
            style: const CoreFocusOutlineStyle(
              offsetColor: _kBand,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
            ),
          );

          // The corner the child itself is drawn with: the stated
          // radius for a rectangle, half the short side for a circle.
          final childRadius = shape == .circle
              ? _kChild.shortestSide / 2
              : CoreRadius.radius8;
          expect(
            _paintedInsideChild(shot, childRadius),
            0,
            reason:
                'the band is a stroke knocked out of the child — a filled '
                'box behind the child shows through any child that is '
                'not opaque, and only on Flutter, since CSS paints an '
                'outer box-shadow outside the border box only',
          );

          // And it does paint the gap: one pixel outside the child's
          // straight left edge, vertically centred.
          final y = shot.child.center.dy.floor();
          expect(
            shot.rgbaAt(shot.child.left.floor() - 1, y),
            0xFF0000FF,
            reason: 'the stated band colour fills the gap',
          );
        },
      );
    }

    testWidgets('the transparent default leaves the gap empty', (
      tester,
    ) async {
      final shot = await _shoot(
        tester,
        shape: .rectangle,
        style: const CoreFocusOutlineStyle(
          offsetColor: CoreFocusOutlineStyle.defaultOffsetColor,
        ),
      );
      final y = shot.child.center.dy.floor();

      expect(CoreFocusOutlineStyle.defaultOffsetColor, CoreColor.transparent);
      expect(
        shot.alphaAt(shot.child.left.floor() - 1, y),
        0,
        reason: 'the background behind the control shows through the gap',
      );
      // The ring itself still paints, one gap further out.
      expect(shot.alphaAt(shot.child.left.floor() - 3, y), greaterThan(0));
    });
  });
}
