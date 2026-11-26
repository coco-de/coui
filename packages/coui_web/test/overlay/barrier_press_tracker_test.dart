import 'package:coui_web/src/overlay/barrier_press_tracker.dart';
import 'package:test/test.dart';

void main() {
  group('BarrierPressTracker', () {
    late BarrierPressTracker tracker;
    late int dismissCount;

    void handleDismiss() => dismissCount++;

    setUp(() {
      tracker = BarrierPressTracker();
      dismissCount = 0;
    });

    test('press started and ended on barrier dismisses', () {
      tracker.handleBarrierPointerDown();
      tracker.handleBarrierClick(handleDismiss);

      expect(dismissCount, 1);
    });

    test('press started on panel, click surfacing on barrier does not '
        'dismiss (drag released outside the panel)', () {
      tracker.handlePanelPointerDown();
      tracker.handleBarrierClick(handleDismiss);

      expect(dismissCount, 0);
    });

    test('click without any prior pointerdown does not dismiss', () {
      tracker.handleBarrierClick(handleDismiss);

      expect(dismissCount, 0);
    });

    test('stale barrier-started flag is cleared by the next panel press '
        '(barrier→panel release, then panel→barrier release)', () {
      // Gesture 1: down on barrier, released over the panel — no click
      // reaches the barrier, so the flag would go stale without the
      // panel hook.
      tracker.handleBarrierPointerDown();
      // Gesture 2: down on panel, released over the barrier.
      tracker.handlePanelPointerDown();
      tracker.handleBarrierClick(handleDismiss);

      expect(dismissCount, 0);
    });

    test('barrier click consumes the flag — a second click without a new '
        'barrier press does not dismiss again', () {
      tracker.handleBarrierPointerDown();
      tracker.handleBarrierClick(handleDismiss);
      tracker.handleBarrierClick(handleDismiss);

      expect(dismissCount, 1);
    });

    test('fresh barrier press after a panel press dismisses again', () {
      tracker.handlePanelPointerDown();
      tracker.handleBarrierClick(handleDismiss);
      tracker.handleBarrierPointerDown();
      tracker.handleBarrierClick(handleDismiss);

      expect(dismissCount, 1);
    });
  });
}
