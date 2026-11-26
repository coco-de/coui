import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/overlay/positioning/collision.dart';
import 'package:coui_web/src/overlay/positioning/rect.dart';
import 'package:test/test.dart';

void main() {
  const viewport = OverlayViewport.all(
    width: 1024,
    height: 768,
    padding: 8,
  );
  const popover = OverlaySize(width: 240, height: 320);
  const gap = 4.0;

  OverlayPositionResolution resolve({
    required OverlayRect trigger,
    required CorePopoverPlacement placement,
    Set<CorePopoverCollision> policy = CorePopoverStyle.defaultCollision,
  }) {
    return resolveOverlayCollision(
      trigger: trigger,
      popover: popover,
      placement: placement,
      viewport: viewport,
      gap: gap,
      policy: policy,
    );
  }

  group('no overflow — passthrough', () {
    test('popover fits below → placement preserved, no flip/shift', () {
      const trigger = OverlayRect(left: 300, top: 100, width: 100, height: 40);
      final r = resolve(
        trigger: trigger,
        placement: .bottomStart,
      );
      expect(r.placement, CorePopoverPlacement.bottomStart);
      expect(r.flipped, isFalse);
      expect(r.shifted, isFalse);
      expect(r.position.left, 300);
      expect(r.position.top, 144);
    });
  });

  group('flip — vertical', () {
    test('bottom overflows → flips to top', () {
      // Trigger near the bottom edge: 768 - 40 - 10 = 718 → bottom = 758.
      // Popover height 320 + gap 4 = 324 below → 1082, overflow 314.
      // Above: trigger.top 718 - popover.height 320 - gap 4 = 394, fits.
      const trigger = OverlayRect(left: 300, top: 718, width: 100, height: 40);
      final r = resolve(
        trigger: trigger,
        placement: .bottomStart,
      );
      expect(r.flipped, isTrue);
      expect(r.placement, CorePopoverPlacement.topStart);
      expect(r.position.top, 394);
    });

    test('top overflows → flips to bottom', () {
      const trigger = OverlayRect(left: 300, top: 10, width: 100, height: 40);
      final r = resolve(
        trigger: trigger,
        placement: .topStart,
      );
      expect(r.flipped, isTrue);
      expect(r.placement, CorePopoverPlacement.bottomStart);
      expect(r.position.top, 54);
    });

    test('both sides overflow → keep original if flipped side no better', () {
      // Trigger filling most of viewport vertically: popover won't fit either way.
      const trigger = OverlayRect(left: 300, top: 200, width: 100, height: 20);
      // Viewport height deliberately short.
      final r = resolveOverlayCollision(
        trigger: trigger,
        popover: const OverlaySize(width: 240, height: 500),
        placement: .bottomStart,
        viewport: const OverlayViewport.all(
          width: 1024,
          height: 400,
          padding: 8,
        ),
        gap: gap,
      );
      // bottom overflow = (220 + 4 + 500) - 400 = 324
      // flipped top overflow = -(200 - 500 - 4) = 304
      // 304 < 324 → flip applied
      expect(r.flipped, isTrue);
      expect(r.placement, CorePopoverPlacement.topStart);
    });
  });

  group('flip — horizontal', () {
    test('right overflows → flips to left', () {
      // Trigger near right edge: 1024 - 100 - 5 = 919 → right = 1019.
      // Right placement: left = 1023, popover goes to 1263, overflow 239.
      // Left placement: x = 919 - 240 - 4 = 675, fits.
      const trigger = OverlayRect(left: 919, top: 300, width: 100, height: 40);
      final r = resolve(
        trigger: trigger,
        placement: .rightStart,
      );
      expect(r.flipped, isTrue);
      expect(r.placement, CorePopoverPlacement.leftStart);
      expect(r.position.left, 675);
    });
  });

  group('shift — secondary axis', () {
    test('bottomStart near left edge: shifted into viewport padding', () {
      // trigger.left = 2 → popover.left starts at 2, viewport.padding = 8.
      const trigger = OverlayRect(left: 2, top: 100, width: 100, height: 40);
      final r = resolve(
        trigger: trigger,
        placement: .bottomStart,
      );
      expect(r.shifted, isTrue);
      expect(r.position.left, 8);
    });

    test('bottomEnd near right edge: shifted left to fit', () {
      // trigger.right near viewport end; popover would overflow right.
      const trigger = OverlayRect(left: 1000, top: 100, width: 30, height: 40);
      // bottomEnd: left = 1030 - 240 = 790; overflow? trigger.right=1030 which is > viewport(1024).
      // popover.right = 790 + 240 = 1030 > 1024 - 8 = 1016. So shift to max = 1016-240 = 776.
      final r = resolve(
        trigger: trigger,
        placement: .bottomEnd,
      );
      expect(r.shifted, isTrue);
      expect(r.position.left, 776);
    });

    test('leftStart near top edge: shifted down to padding', () {
      const trigger = OverlayRect(left: 500, top: 2, width: 100, height: 40);
      final r = resolve(
        trigger: trigger,
        placement: .leftStart,
      );
      expect(r.shifted, isTrue);
      expect(r.position.top, 8);
    });
  });

  group('policy disabling', () {
    test('empty policy keeps origin even when overflowing', () {
      const trigger = OverlayRect(left: 2, top: 100, width: 100, height: 40);
      final r = resolve(
        trigger: trigger,
        placement: .bottomStart,
        policy: const {},
      );
      expect(r.shifted, isFalse);
      expect(r.flipped, isFalse);
      expect(r.position.left, 2);
    });

    test('shift-only policy does not flip', () {
      const trigger = OverlayRect(left: 300, top: 718, width: 100, height: 40);
      final r = resolve(
        trigger: trigger,
        placement: .bottomStart,
        policy: const {.shift},
      );
      expect(r.flipped, isFalse);
      expect(r.placement, CorePopoverPlacement.bottomStart);
    });
  });

  group('default policy = {flip, shift}', () {
    test('matches CorePopoverStyle.defaultCollision', () {
      const trigger = OverlayRect(left: 300, top: 100, width: 100, height: 40);
      final explicit = resolve(
        trigger: trigger,
        placement: .bottomStart,
      );
      final defaulted = resolveOverlayCollision(
        trigger: trigger,
        popover: popover,
        placement: .bottomStart,
        viewport: viewport,
        gap: gap,
      );
      expect(explicit.position.left, defaulted.position.left);
      expect(explicit.position.top, defaulted.position.top);
      expect(explicit.placement, defaulted.placement);
    });
  });
}
