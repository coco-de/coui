// The live value axis of `Scrollbar`'s phantom `role="scrollbar"` nodes.
//
// The markup tests next door (`scrollbar_a11y_test.dart`) render through
// `testServer`, where no `scroll` event ever fires — so the only
// `aria-valuenow` they can observe is the start-of-range value the state
// is constructed with. Deleting the entire update path left them green.
// These assertions are the ones that go red for it: they feed geometry
// the component would have read off a scrolled element and check the
// number that comes back out.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/infra/scrollbar/scrollbar_geometry.dart';
import 'package:test/test.dart';

/// A box scrolled to [scrollTop] / [scrollLeft] whose content overflows
/// the viewport on both axes — 1000 long against a 200 viewport, so each
/// axis has 800 of travel and a percent is a plain eighth of it.
ScrollbarViewportGeometry _bothAxesScrollable({
  double scrollTop = 0,
  double scrollLeft = 0,
}) => (
  scrollTop: scrollTop,
  scrollHeight: 1000,
  clientHeight: 200,
  scrollLeft: scrollLeft,
  scrollWidth: 1000,
  clientWidth: 200,
);

void main() {
  group('scrollbarPercentsOf', () {
    test('an unscrolled box reports the start on both axes', () {
      final percents = scrollbarPercentsOf(_bothAxesScrollable());

      expect(percents.vertical, kScrollbarPercentMin);
      expect(percents.horizontal, kScrollbarPercentMin);
    });

    test('a box scrolled to its middle reports 50 on that axis', () {
      final percents = scrollbarPercentsOf(
        _bothAxesScrollable(scrollTop: 400),
      );

      expect(percents.vertical, 50);
    });

    test('a box scrolled to its end reports 100 on that axis', () {
      final percents = scrollbarPercentsOf(
        _bothAxesScrollable(scrollTop: 800),
      );

      expect(percents.vertical, kScrollbarPercentMax);
    });

    test('overscroll past either end stays inside the announced bounds', () {
      expect(
        scrollbarPercentsOf(_bothAxesScrollable(scrollTop: -150)).vertical,
        kScrollbarPercentMin,
      );
      expect(
        scrollbarPercentsOf(_bothAxesScrollable(scrollTop: 950)).vertical,
        kScrollbarPercentMax,
      );
    });

    group('each axis reads its own triple', () {
      // The mistake this group exists for: deriving the vertical percent
      // from the width triple (or the reverse). It is invisible on a
      // square, both-ways-scrollable box — every assertion above would
      // still pass — and shows up in the wild as a bar that never leaves
      // 0 because the axis it accidentally reads does not scroll.
      test('a vertical-only box reports movement on vertical alone', () {
        final percents = scrollbarPercentsOf((
          scrollTop: 400,
          scrollHeight: 1000,
          clientHeight: 200,
          // Content fits horizontally: nothing to scroll, nothing to
          // report.
          scrollLeft: 0,
          scrollWidth: 200,
          clientWidth: 200,
        ));

        expect(percents.vertical, 50);
        expect(percents.horizontal, kScrollbarPercentMin);
      });

      test('a horizontal-only box reports movement on horizontal alone', () {
        final percents = scrollbarPercentsOf((
          scrollTop: 0,
          scrollHeight: 200,
          clientHeight: 200,
          scrollLeft: 400,
          scrollWidth: 1000,
          clientWidth: 200,
        ));

        expect(percents.horizontal, 50);
        expect(percents.vertical, kScrollbarPercentMin);
      });

      test('the two axes report different positions independently', () {
        // Distinct values on both axes at once: swapping the triples
        // swaps these two numbers, which a single-axis case cannot see.
        final percents = scrollbarPercentsOf((
          scrollTop: 200,
          scrollHeight: 1000,
          clientHeight: 200,
          scrollLeft: 600,
          scrollWidth: 1000,
          clientWidth: 200,
        ));

        expect(percents.vertical, 25);
        expect(percents.horizontal, 75);
      });

      test('vertical follows the height triple when the widths differ', () {
        // Same scroll offsets, different *ranges* per axis — a bar
        // reading the wrong range reports the wrong fraction of the
        // right offset.
        final percents = scrollbarPercentsOf((
          scrollTop: 100,
          scrollHeight: 600,
          clientHeight: 200,
          scrollLeft: 100,
          scrollWidth: 1200,
          clientWidth: 200,
        ));

        // 100 of 400 vertical travel; 100 of 1000 horizontal travel.
        expect(percents.vertical, 25);
        expect(percents.horizontal, 10);
      });
    });

    test('a right-to-left box reports the start wherever it is scrolled', () {
      // Not an endorsement — a record of reach. `scrollLeft` runs
      // negative leftward in a right-to-left box, so every position
      // clamps to the start and the horizontal bar reads `0` throughout.
      // Pinned so the assertions above cannot be mistaken for a claim
      // that both directions work; see the note on `scrollbarPercentsOf`.
      final percents = scrollbarPercentsOf((
        scrollTop: 0,
        scrollHeight: 200,
        clientHeight: 200,
        // Halfway through a right-to-left range of 800.
        scrollLeft: -400,
        scrollWidth: 1000,
        clientWidth: 200,
      ));

      expect(percents.horizontal, kScrollbarPercentMin);
    });

    test('a box that cannot scroll at all reports the start on both', () {
      final percents = scrollbarPercentsOf((
        scrollTop: 0,
        scrollHeight: 200,
        clientHeight: 200,
        scrollLeft: 0,
        scrollWidth: 200,
        clientWidth: 200,
      ));

      expect(percents.vertical, kScrollbarPercentMin);
      expect(percents.horizontal, kScrollbarPercentMin);
    });
  });
}
