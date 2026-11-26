import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// A 400x400 container at the origin, with the default 48px edge band.
const _container = CoreDragRect(left: 0, top: 0, width: 400, height: 400);

CoreDragScrollIntent _at(double x, double y) => CoreDragAutoScroll.resolve(
  pointer: CoreDragPoint(x, y),
  containerRect: _container,
);

void main() {
  group('CoreDragAutoScroll', () {
    test('the middle of a container does not scroll', () {
      expect(_at(200, 200), CoreDragScrollIntent.none);
      expect(_at(200, 200).isActive, isFalse);
    });

    test('just outside the edge band does not scroll', () {
      expect(_at(200, 48).y, 0);
      expect(_at(200, 352).y, 0);
    });

    test('velocity grows the deeper into the band the pointer goes', () {
      final shallow = _at(200, 40).y.abs();
      final deep = _at(200, 8).y.abs();

      expect(shallow, greaterThan(0));
      expect(deep, greaterThan(shallow));
    });

    test('the sign points toward the edge being approached', () {
      expect(_at(200, 10).y, lessThan(0), reason: 'top pulls upward');
      expect(_at(200, 390).y, greaterThan(0), reason: 'bottom pulls down');
      expect(_at(10, 200).x, lessThan(0), reason: 'left pulls to the start');
      expect(_at(390, 200).x, greaterThan(0), reason: 'right pulls to the end');
    });

    test('reaching the edge is already the maximum', () {
      expect(
        _at(200, 0).y.abs(),
        CoreDragAutoScrollConfig.defaultMaxVelocity,
      );
    });

    test('past the edge stays at the maximum rather than accelerating', () {
      expect(
        _at(200, -500).y.abs(),
        CoreDragAutoScrollConfig.defaultMaxVelocity,
      );
    });

    test('both axes pull at once in a corner', () {
      final corner = _at(6, 6);

      expect(corner.x, lessThan(0));
      expect(corner.y, lessThan(0));
    });

    test('a container thinner than the band picks the nearer edge', () {
      // 20px tall: both bands cover everything, so the sign must still be
      // decided by which edge is closer rather than flickering.
      const thin = CoreDragRect(left: 0, top: 0, width: 400, height: 20);
      CoreDragScrollIntent at(double y) => CoreDragAutoScroll.resolve(
        pointer: CoreDragPoint(200, y),
        containerRect: thin,
      );

      expect(at(4).y, lessThan(0));
      expect(at(16).y, greaterThan(0));
    });

    test('a non-positive threshold or velocity disables scrolling', () {
      expect(
        CoreDragAutoScroll.resolve(
          pointer: const CoreDragPoint(200, 0),
          containerRect: _container,
          config: const CoreDragAutoScrollConfig(threshold: 0),
        ),
        CoreDragScrollIntent.none,
      );
      expect(
        CoreDragAutoScroll.resolve(
          pointer: const CoreDragPoint(200, 0),
          containerRect: _container,
          config: const CoreDragAutoScrollConfig(maxVelocity: 0),
        ),
        CoreDragScrollIntent.none,
      );
    });
  });

  group('CoreDragScrollIntent.distanceOver', () {
    test('integrates velocity over elapsed time', () {
      const intent = CoreDragScrollIntent(x: 100, y: -200);

      expect(
        intent.distanceOver(const Duration(milliseconds: 500)),
        const CoreDragOffset(x: 50, y: -100),
      );
    });

    test('no elapsed time covers no distance', () {
      const intent = CoreDragScrollIntent(x: 900, y: 900);

      expect(intent.distanceOver(Duration.zero), CoreDragOffset.zero);
    });
  });
}
