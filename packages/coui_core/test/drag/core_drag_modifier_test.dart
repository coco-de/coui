import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _item = CoreDragId('item');

/// A 40x40 item resting at (30, 30) inside a 200x200 container at the origin.
CoreDragModifierInput _input(CoreDragOffset transform) => CoreDragModifierInput(
  transform: transform,
  itemRect: const CoreDragRect(left: 30, top: 30, width: 40, height: 40),
  containerRect: const CoreDragRect(left: 0, top: 0, width: 200, height: 200),
);

void main() {
  group('CoreDragModifiers axis locks', () {
    test('vertical drops horizontal movement', () {
      final result = CoreDragModifiers.restrictToVerticalAxis(
        _input(const CoreDragOffset(x: 80, y: 25)),
      );

      expect(result, const CoreDragOffset(y: 25));
    });

    test('horizontal drops vertical movement', () {
      final result = CoreDragModifiers.restrictToHorizontalAxis(
        _input(const CoreDragOffset(x: 80, y: 25)),
      );

      expect(result, const CoreDragOffset(x: 80));
    });
  });

  group('CoreDragModifiers.restrictToRect', () {
    test('leaves movement that stays inside untouched', () {
      final result = CoreDragModifiers.restrictToRect(
        _input(const CoreDragOffset(x: 20, y: 20)),
      );

      expect(result, const CoreDragOffset(x: 20, y: 20));
    });

    test('pins the item to the far edge rather than past it', () {
      // The item's right edge sits at 70, so it may travel 130 before the
      // container's right edge at 200.
      final result = CoreDragModifiers.restrictToRect(
        _input(const CoreDragOffset(x: 500, y: 500)),
      );

      expect(result, const CoreDragOffset(x: 130, y: 130));
    });

    test('pins the item to the near edge rather than past it', () {
      final result = CoreDragModifiers.restrictToRect(
        _input(const CoreDragOffset(x: -500, y: -500)),
      );

      expect(result, const CoreDragOffset(x: -30, y: -30));
    });

    test('an unmeasured rect constrains nothing', () {
      const transform = CoreDragOffset(x: 500, y: 500);

      expect(
        CoreDragModifiers.restrictToRect(
          const CoreDragModifierInput(transform: transform),
        ),
        transform,
        reason: 'a bound nobody supplied must not be invented',
      );
    });

    test('an item larger than its container pins to the near edge', () {
      final result = CoreDragModifiers.restrictToRect(
        const CoreDragModifierInput(
          transform: CoreDragOffset(x: 40, y: 40),
          itemRect: CoreDragRect(left: 0, top: 0, width: 300, height: 300),
          containerRect: CoreDragRect(left: 0, top: 0, width: 200, height: 200),
        ),
      );

      expect(result, const CoreDragOffset());
    });
  });

  group('CoreDragModifiers.snapToGrid', () {
    test('rounds to the nearest multiple on both axes', () {
      final snap = CoreDragModifiers.snapToGrid(x: 20, y: 20);

      expect(
        snap(_input(const CoreDragOffset(x: 29, y: 31))),
        const CoreDragOffset(x: 20, y: 40),
      );
    });

    test('a non-positive step leaves that axis alone', () {
      final snap = CoreDragModifiers.snapToGrid(x: 0, y: 20);

      expect(
        snap(_input(const CoreDragOffset(x: 29, y: 31))),
        const CoreDragOffset(x: 29, y: 40),
      );
    });
  });

  group('CoreDragModifiers.apply', () {
    test('an empty list is the identity', () {
      const transform = CoreDragOffset(x: 13, y: 77);

      expect(
        CoreDragModifiers.apply(
          const <CoreDragModifier>[],
          _input(transform),
        ),
        transform,
      );
    });

    test('each modifier sees the previous one\'s output', () {
      final result = CoreDragModifiers.apply(
        <CoreDragModifier>[
          CoreDragModifiers.snapToGrid(x: 20, y: 20),
          CoreDragModifiers.restrictToRect,
        ],
        _input(const CoreDragOffset(x: 132, y: 132)),
      );

      // Snapped 132 -> 140, then clamped back to the 130 bound.
      expect(result, const CoreDragOffset(x: 130, y: 130));
    });

    test('only the last modifier is guaranteed to hold', () {
      // Clamping to 130 and *then* snapping rounds up to 140, back across
      // the boundary — which is why a bound that must win goes last.
      final result = CoreDragModifiers.apply(
        <CoreDragModifier>[
          CoreDragModifiers.restrictToRect,
          CoreDragModifiers.snapToGrid(x: 20, y: 20),
        ],
        _input(const CoreDragOffset(x: 500, y: 500)),
      );

      expect(result, const CoreDragOffset(x: 140, y: 140));
    });
  });

  group('CoreDragRuntime with modifiers', () {
    test('constrains the session the whole pipeline reads', () {
      final runtime = CoreDragRuntime(
        modifiers: <CoreDragModifier>[
          CoreDragModifiers.restrictToVerticalAxis,
        ],
      );
      runtime.registry.registerItem(_item);

      runtime.pointerDown(_item, position: const CoreDragPoint(0, 0));
      runtime.pointerMove(const CoreDragPoint(120, 40));

      final session = runtime.session!;
      expect(session.transform, const CoreDragOffset(y: 40));
      expect(
        session.pointer.x,
        0,
        reason: 'collision must read the constrained position too',
      );
    });

    test('without modifiers the session is the raw pointer delta', () {
      final runtime = CoreDragRuntime();
      runtime.registry.registerItem(_item);

      runtime.pointerDown(_item, position: const CoreDragPoint(0, 0));
      runtime.pointerMove(const CoreDragPoint(120, 40));

      expect(
        runtime.session!.transform,
        const CoreDragOffset(x: 120, y: 40),
      );
    });

    test('constrains from the very first activated move', () {
      final runtime = CoreDragRuntime(
        modifiers: <CoreDragModifier>[
          CoreDragModifiers.restrictToHorizontalAxis,
        ],
      );
      runtime.registry.registerItem(_item);

      runtime.pointerDown(_item, position: const CoreDragPoint(0, 0));
      runtime.pointerMove(const CoreDragPoint(50, 90));

      expect(runtime.session!.transform, const CoreDragOffset(x: 50));
    });
  });
}
