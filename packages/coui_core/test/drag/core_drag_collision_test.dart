import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _active = CoreDragId('active');
const _left = CoreDragId('left');
const _right = CoreDragId('right');

/// Two 100x100 zones side by side, with the dragged item measured inside the
/// left one.
CoreDragCollisionInput _input({
  CoreDragPoint pointer = const CoreDragPoint(50, 50),
  CoreDragRect? activeRect = const CoreDragRect(
    left: 20,
    top: 20,
    width: 60,
    height: 60,
  ),
}) => CoreDragCollisionInput(
  activeId: _active,
  pointer: pointer,
  activeRect: activeRect,
  dropZoneRects: {
    _left: const CoreDragRect(left: 0, top: 0, width: 100, height: 100),
    _right: const CoreDragRect(left: 100, top: 0, width: 100, height: 100),
  },
);

void main() {
  group('CoreDragCollisions.pointerWithin', () {
    test('names the zone containing the pointer', () {
      expect(
        CoreDragCollisions.pointerWithin(_input()),
        _left,
      );
      expect(
        CoreDragCollisions.pointerWithin(
          _input(pointer: const CoreDragPoint(150, 50)),
        ),
        _right,
      );
    });

    test('abstains when the pointer is outside every zone', () {
      expect(
        CoreDragCollisions.pointerWithin(
          _input(pointer: const CoreDragPoint(250, 250)),
        ),
        isNull,
      );
    });
  });

  group('CoreDragCollisions.closestCenter', () {
    test('names the nearest zone even from outside all of them', () {
      expect(
        CoreDragCollisions.closestCenter(
          _input(pointer: const CoreDragPoint(250, 250)),
        ),
        _right,
      );
    });

    test('abstains when no zone is measured', () {
      final input = CoreDragCollisionInput(
        activeId: _active,
        pointer: CoreDragPoint(10, 10),
        dropZoneRects: const {},
      );

      expect(CoreDragCollisions.closestCenter(input), isNull);
    });
  });

  group('CoreDragCollisions.rectIntersection', () {
    test('names the zone the dragged rect overlaps most', () {
      // The item straddles the seam: 40x60 on the left, 20x60 on the right.
      expect(
        CoreDragCollisions.rectIntersection(
          _input(
            activeRect: const CoreDragRect(
              left: 60,
              top: 20,
              width: 60,
              height: 60,
            ),
          ),
        ),
        _left,
      );
      expect(
        CoreDragCollisions.rectIntersection(
          _input(
            activeRect: const CoreDragRect(
              left: 90,
              top: 20,
              width: 60,
              height: 60,
            ),
          ),
        ),
        _right,
      );
    });

    test('abstains when the dragged rect is unmeasured', () {
      expect(
        CoreDragCollisions.rectIntersection(_input(activeRect: null)),
        isNull,
      );
    });

    test('abstains when nothing overlaps', () {
      expect(
        CoreDragCollisions.rectIntersection(
          _input(
            activeRect: const CoreDragRect(
              left: 400,
              top: 400,
              width: 20,
              height: 20,
            ),
          ),
        ),
        isNull,
      );
    });
  });

  group('CoreDragCollisions.compose', () {
    test('the first detector that commits wins', () {
      final detector = CoreDragCollisions.compose([
        CoreDragCollisions.pointerWithin,
        CoreDragCollisions.closestCenter,
      ]);

      expect(detector(_input(pointer: const CoreDragPoint(50, 50))), _left);
      expect(detector(_input(pointer: const CoreDragPoint(250, 250))), _right);
    });

    test('an abstaining detector falls through to the next', () {
      // pointerWithin abstains for a pointer outside every zone, so the
      // chain's fallback answers — this is the whole point of composing.
      final detector = CoreDragCollisions.compose([
        CoreDragCollisions.pointerWithin,
        CoreDragCollisions.closestCenter,
      ]);

      expect(
        detector(_input(pointer: const CoreDragPoint(250, 250))),
        _right,
      );
    });

    test('abstains when every detector does', () {
      final detector = CoreDragCollisions.compose([
        // Both abstain: the dragged rect is unmeasured and the pointer is
        // outside every zone.
        CoreDragCollisions.rectIntersection,
        CoreDragCollisions.pointerWithin,
      ]);

      expect(
        detector(
          _input(pointer: const CoreDragPoint(250, 250), activeRect: null),
        ),
        isNull,
      );
      expect(CoreDragCollisions.compose(const [])(_input()), isNull);
    });
  });
}
