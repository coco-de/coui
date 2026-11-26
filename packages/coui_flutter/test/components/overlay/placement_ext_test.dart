import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CorePopoverPlacementFlutterExt.toPopoverAlignment', () {
    test('top family maps to bottom-aligned popover edge', () {
      expect(
        CorePopoverPlacement.top.toPopoverAlignment(),
        Alignment.bottomCenter,
      );
      expect(
        CorePopoverPlacement.topStart.toPopoverAlignment(),
        Alignment.bottomLeft,
      );
      expect(
        CorePopoverPlacement.topEnd.toPopoverAlignment(),
        Alignment.bottomRight,
      );
    });

    test('bottom family maps to top-aligned popover edge', () {
      expect(
        CorePopoverPlacement.bottom.toPopoverAlignment(),
        Alignment.topCenter,
      );
      expect(
        CorePopoverPlacement.bottomStart.toPopoverAlignment(),
        Alignment.topLeft,
      );
      expect(
        CorePopoverPlacement.bottomEnd.toPopoverAlignment(),
        Alignment.topRight,
      );
    });

    test('left family maps to right-aligned popover edge', () {
      expect(
        CorePopoverPlacement.left.toPopoverAlignment(),
        Alignment.centerRight,
      );
      expect(
        CorePopoverPlacement.leftStart.toPopoverAlignment(),
        Alignment.topRight,
      );
      expect(
        CorePopoverPlacement.leftEnd.toPopoverAlignment(),
        Alignment.bottomRight,
      );
    });

    test('right family maps to left-aligned popover edge', () {
      expect(
        CorePopoverPlacement.right.toPopoverAlignment(),
        Alignment.centerLeft,
      );
      expect(
        CorePopoverPlacement.rightStart.toPopoverAlignment(),
        Alignment.topLeft,
      );
      expect(
        CorePopoverPlacement.rightEnd.toPopoverAlignment(),
        Alignment.bottomLeft,
      );
    });

    test('returns a valid Alignment for every placement', () {
      for (final p in CorePopoverPlacement.values) {
        final a = p.toPopoverAlignment();
        expect(a.x, inInclusiveRange(-1.0, 1.0));
        expect(a.y, inInclusiveRange(-1.0, 1.0));
      }
    });
  });

  group('CorePopoverPlacementFlutterExt.toAnchorAlignment', () {
    test('top family anchors to trigger top edge', () {
      expect(CorePopoverPlacement.top.toAnchorAlignment(), Alignment.topCenter);
      expect(
        CorePopoverPlacement.topStart.toAnchorAlignment(),
        Alignment.topLeft,
      );
      expect(
        CorePopoverPlacement.topEnd.toAnchorAlignment(),
        Alignment.topRight,
      );
    });

    test('bottom family anchors to trigger bottom edge', () {
      expect(
        CorePopoverPlacement.bottom.toAnchorAlignment(),
        Alignment.bottomCenter,
      );
      expect(
        CorePopoverPlacement.bottomStart.toAnchorAlignment(),
        Alignment.bottomLeft,
      );
      expect(
        CorePopoverPlacement.bottomEnd.toAnchorAlignment(),
        Alignment.bottomRight,
      );
    });

    test('left family anchors to trigger left edge', () {
      expect(
        CorePopoverPlacement.left.toAnchorAlignment(),
        Alignment.centerLeft,
      );
      expect(
        CorePopoverPlacement.leftStart.toAnchorAlignment(),
        Alignment.topLeft,
      );
      expect(
        CorePopoverPlacement.leftEnd.toAnchorAlignment(),
        Alignment.bottomLeft,
      );
    });

    test('right family anchors to trigger right edge', () {
      expect(
        CorePopoverPlacement.right.toAnchorAlignment(),
        Alignment.centerRight,
      );
      expect(
        CorePopoverPlacement.rightStart.toAnchorAlignment(),
        Alignment.topRight,
      );
      expect(
        CorePopoverPlacement.rightEnd.toAnchorAlignment(),
        Alignment.bottomRight,
      );
    });
  });

  group('anchor ↔ popover alignment symmetry', () {
    test('the two alignments are reflections across the placement axis', () {
      for (final p in CorePopoverPlacement.values) {
        final anchor = p.toAnchorAlignment();
        final popover = p.toPopoverAlignment();

        if (p.isTop || p.isBottom) {
          // Vertical placement: secondary (x) axis unchanged, primary (y) flipped.
          expect(popover.x, anchor.x, reason: '$p secondary axis should match');
          expect(popover.y, -anchor.y, reason: '$p primary axis should flip');
        } else {
          // Horizontal placement: primary (x) flipped, secondary (y) unchanged.
          expect(popover.x, -anchor.x, reason: '$p primary axis should flip');
          expect(popover.y, anchor.y, reason: '$p secondary axis should match');
        }
      }
    });
  });

  group('CorePopoverPlacementFlutterExt.toPopoverOffset', () {
    const gap = 8.0;

    test('top family pushes up', () {
      expect(
        CorePopoverPlacement.top.toPopoverOffset(gap),
        const Offset(0, -gap),
      );
      expect(
        CorePopoverPlacement.topStart.toPopoverOffset(gap),
        const Offset(0, -gap),
      );
      expect(
        CorePopoverPlacement.topEnd.toPopoverOffset(gap),
        const Offset(0, -gap),
      );
    });

    test('bottom family pushes down', () {
      expect(
        CorePopoverPlacement.bottom.toPopoverOffset(gap),
        const Offset(0, gap),
      );
      expect(
        CorePopoverPlacement.bottomStart.toPopoverOffset(gap),
        const Offset(0, gap),
      );
      expect(
        CorePopoverPlacement.bottomEnd.toPopoverOffset(gap),
        const Offset(0, gap),
      );
    });

    test('left family pushes left', () {
      expect(
        CorePopoverPlacement.left.toPopoverOffset(gap),
        const Offset(-gap, 0),
      );
      expect(
        CorePopoverPlacement.leftStart.toPopoverOffset(gap),
        const Offset(-gap, 0),
      );
      expect(
        CorePopoverPlacement.leftEnd.toPopoverOffset(gap),
        const Offset(-gap, 0),
      );
    });

    test('right family pushes right', () {
      expect(
        CorePopoverPlacement.right.toPopoverOffset(gap),
        const Offset(gap, 0),
      );
      expect(
        CorePopoverPlacement.rightStart.toPopoverOffset(gap),
        const Offset(gap, 0),
      );
      expect(
        CorePopoverPlacement.rightEnd.toPopoverOffset(gap),
        const Offset(gap, 0),
      );
    });

    test('zero gap is identity', () {
      for (final p in CorePopoverPlacement.values) {
        expect(p.toPopoverOffset(0), Offset.zero);
      }
    });

    test('scales linearly with gap', () {
      for (final p in CorePopoverPlacement.values) {
        final o4 = p.toPopoverOffset(4);
        final o8 = p.toPopoverOffset(8);
        expect(o8.dx, o4.dx * 2);
        expect(o8.dy, o4.dy * 2);
      }
    });
  });
}
