// The number behind `aria-valuenow` (Web) and `Semantics.value`
// (Flutter). Both platforms render it either way, so a wrong answer
// here is invisible in markup and in a screenshot — only an assertion on
// the number itself can see it.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('scrollbarPercentOfAxis', () {
    test('reports the start of the range as 0', () {
      expect(
        scrollbarPercentOfAxis(offset: 0, scrollableExtent: 400),
        kScrollbarPercentMin,
      );
    });

    test('reports the middle of the range as 50', () {
      expect(scrollbarPercentOfAxis(offset: 200, scrollableExtent: 400), 50);
    });

    test('reports the end of the range as 100', () {
      expect(
        scrollbarPercentOfAxis(offset: 400, scrollableExtent: 400),
        kScrollbarPercentMax,
      );
    });

    test('scales with the range, not with the raw offset', () {
      // The same offset means something different in a longer document;
      // a function that leaked pixels into its answer would return the
      // same number for both.
      expect(scrollbarPercentOfAxis(offset: 100, scrollableExtent: 400), 25);
      expect(scrollbarPercentOfAxis(offset: 100, scrollableExtent: 200), 50);
    });

    test('rounds to the nearer whole percent', () {
      // 2/3 of the range is 66.67%.
      expect(scrollbarPercentOfAxis(offset: 2, scrollableExtent: 3), 67);
      // 1/3 is 33.33%.
      expect(scrollbarPercentOfAxis(offset: 1, scrollableExtent: 3), 33);
    });

    group('overscroll stays inside the announced bounds', () {
      test('a rubber-band pull past the start clamps to the minimum', () {
        expect(
          scrollbarPercentOfAxis(offset: -80, scrollableExtent: 400),
          kScrollbarPercentMin,
        );
      });

      test('a fling past the end clamps to the maximum', () {
        expect(
          scrollbarPercentOfAxis(offset: 520, scrollableExtent: 400),
          kScrollbarPercentMax,
        );
      });
    });

    group('an axis that cannot scroll reports the start, not the end', () {
      test('content exactly fills the viewport', () {
        expect(
          scrollbarPercentOfAxis(offset: 0, scrollableExtent: 0),
          kScrollbarPercentMin,
        );
      });

      test('content is smaller than the viewport (negative extent)', () {
        expect(
          scrollbarPercentOfAxis(offset: 0, scrollableExtent: -120),
          kScrollbarPercentMin,
        );
      });

      test('a non-zero offset on a non-scrolling axis is still the start', () {
        // Division would hand back infinity here, and `.round()` on that
        // throws rather than clamping — the guard has to come first.
        expect(
          scrollbarPercentOfAxis(offset: 30, scrollableExtent: 0),
          kScrollbarPercentMin,
        );
      });
    });

    group('non-finite geometry does not escape as a crash', () {
      test('a non-finite extent reports the start', () {
        // An infinite extent would divide down to 0 with or without the
        // finiteness guard, so it documents the answer rather than
        // falsifying the guard — the NaN case below is the one that goes
        // red if the guard is dropped.
        expect(
          scrollbarPercentOfAxis(
            offset: 100,
            scrollableExtent: double.infinity,
          ),
          kScrollbarPercentMin,
        );
        expect(
          scrollbarPercentOfAxis(offset: 100, scrollableExtent: double.nan),
          kScrollbarPercentMin,
        );
      });

      test('a non-finite offset reports the start', () {
        expect(
          scrollbarPercentOfAxis(
            offset: double.infinity,
            scrollableExtent: 400,
          ),
          kScrollbarPercentMin,
        );
        expect(
          scrollbarPercentOfAxis(offset: double.nan, scrollableExtent: 400),
          kScrollbarPercentMin,
        );
      });
    });

    test('the announced bounds are the ones the arithmetic produces', () {
      // `aria-valuemin` / `aria-valuemax` are rendered from these two
      // constants, so a range that disagreed with the clamp would
      // announce bounds the value can leave.
      expect(kScrollbarPercentMin, 0);
      expect(kScrollbarPercentMax, 100);
    });
  });
}
