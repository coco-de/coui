import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

// Both platforms paint the handle from these numbers, so the geometry is
// pinned once here rather than per platform.
const double _kViewWidth = 800;
const double _kHandle = 48;
const double _kOffset = 8;

double _resting(
  CoreDraggablePanelDockType type, {
  required double x,
  bool open = false,
}) => type.restingX(
  x: x,
  open: open,
  viewWidth: _kViewWidth,
  handleSize: _kHandle,
  dockOffset: _kOffset,
);

void main() {
  const inside = CoreDraggablePanelDockType.inside;
  const outside = CoreDraggablePanelDockType.outside;
  const leftSlot = _kOffset;
  const rightSlot = _kViewWidth - _kHandle - _kOffset;
  const hidden =
      _kHandle * (1 - CoreDraggablePanelDockType.outsideVisibleFraction);

  group('CoreDraggablePanelDockType geometry', () {
    test('inside rests dockOffset in from either edge', () {
      expect(_resting(inside, x: leftSlot), leftSlot);
      expect(_resting(inside, x: rightSlot), rightSlot);
    });

    test('outside rests past the edge, leaving the stated share visible', () {
      expect(_resting(outside, x: leftSlot), -hidden);
      expect(_resting(outside, x: rightSlot), _kViewWidth - _kHandle + hidden);
      // What is left on screen is exactly the visible share.
      expect(
        _resting(outside, x: leftSlot) + _kHandle,
        _kHandle * CoreDraggablePanelDockType.outsideVisibleFraction,
      );
    });

    test('an open panel pulls an outside handle back to its slot', () {
      expect(_resting(outside, x: leftSlot, open: true), leftSlot);
      expect(_resting(outside, x: rightSlot, open: true), rightSlot);
    });

    test('a handle left mid-viewport is painted where it is', () {
      expect(_resting(outside, x: 300), 300);
    });

    test('drag range extends past the edges only for outside', () {
      expect(inside.minX(handleSize: _kHandle, dockOffset: _kOffset), leftSlot);
      expect(
        inside.maxX(
          viewWidth: _kViewWidth,
          handleSize: _kHandle,
          dockOffset: _kOffset,
        ),
        rightSlot,
      );
      expect(outside.minX(handleSize: _kHandle, dockOffset: _kOffset), -hidden);
      expect(
        outside.maxX(
          viewWidth: _kViewWidth,
          handleSize: _kHandle,
          dockOffset: _kOffset,
        ),
        _kViewWidth - _kHandle + hidden,
      );
    });

    test('maxX never falls below minX in a viewport narrower than the '
        'handle', () {
      final max = inside.maxX(
        viewWidth: 20,
        handleSize: _kHandle,
        dockOffset: _kOffset,
      );
      expect(max, inside.minX(handleSize: _kHandle, dockOffset: _kOffset));
    });
  });
}
