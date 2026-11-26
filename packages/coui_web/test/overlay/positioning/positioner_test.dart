import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/overlay/positioning/positioner.dart';
import 'package:coui_web/src/overlay/positioning/rect.dart';
import 'package:test/test.dart';

void main() {
  // A 100×40 trigger positioned at (200, 300). Viewport-coordinate space.
  const trigger = OverlayRect(left: 200, top: 300, width: 100, height: 40);
  const popover = OverlaySize(width: 80, height: 60);
  const gap = 4.0;

  OverlayPosition compute(CorePopoverPlacement placement) =>
      computeOverlayPosition(
        trigger: trigger,
        popover: popover,
        placement: placement,
        gap: gap,
      );

  group('computeOverlayPosition', () {
    group('top family (y = trigger.top - popover.height - gap = 236)', () {
      test('top centers horizontally', () {
        final p = compute(.top);
        // trigger.centerX = 250, popover half-width = 40 → left = 210.
        expect(p.left, 210);
        expect(p.top, 236);
      });

      test('topStart aligns to trigger left', () {
        final p = compute(.topStart);
        expect(p.left, 200);
        expect(p.top, 236);
      });

      test('topEnd aligns to trigger right', () {
        final p = compute(.topEnd);
        // trigger.right=300, popover width=80 → left=220.
        expect(p.left, 220);
        expect(p.top, 236);
      });
    });

    group('bottom family (y = trigger.bottom + gap = 344)', () {
      test('bottom centers horizontally', () {
        final p = compute(.bottom);
        expect(p.left, 210);
        expect(p.top, 344);
      });

      test('bottomStart aligns to trigger left', () {
        final p = compute(.bottomStart);
        expect(p.left, 200);
        expect(p.top, 344);
      });

      test('bottomEnd aligns to trigger right', () {
        final p = compute(.bottomEnd);
        expect(p.left, 220);
        expect(p.top, 344);
      });
    });

    group('left family (x = trigger.left - popover.width - gap = 116)', () {
      test('left centers vertically', () {
        final p = compute(.left);
        // trigger.centerY = 320, popover half-height = 30 → top = 290.
        expect(p.left, 116);
        expect(p.top, 290);
      });

      test('leftStart aligns to trigger top', () {
        final p = compute(.leftStart);
        expect(p.left, 116);
        expect(p.top, 300);
      });

      test('leftEnd aligns to trigger bottom', () {
        final p = compute(.leftEnd);
        // trigger.bottom=340, popover.height=60 → top=280.
        expect(p.left, 116);
        expect(p.top, 280);
      });
    });

    group('right family (x = trigger.right + gap = 304)', () {
      test('right centers vertically', () {
        final p = compute(.right);
        expect(p.left, 304);
        expect(p.top, 290);
      });

      test('rightStart aligns to trigger top', () {
        final p = compute(.rightStart);
        expect(p.left, 304);
        expect(p.top, 300);
      });

      test('rightEnd aligns to trigger bottom', () {
        final p = compute(.rightEnd);
        expect(p.left, 304);
        expect(p.top, 280);
      });
    });

    test('zero gap puts popover flush against the trigger edge', () {
      final p = computeOverlayPosition(
        trigger: trigger,
        popover: popover,
        placement: .bottom,
        gap: 0,
      );
      expect(p.top, trigger.bottom);
    });

    test('different gaps only shift along primary axis', () {
      final a = compute(.bottomStart);
      final b = computeOverlayPosition(
        trigger: trigger,
        popover: popover,
        placement: .bottomStart,
        gap: gap + 10,
      );
      expect(b.left, a.left);
      expect(b.top, a.top + 10);
    });
  });
}
