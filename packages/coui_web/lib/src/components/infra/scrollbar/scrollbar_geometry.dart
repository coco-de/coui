/// Turns one scrollable element's raw DOM scroll geometry into the two
/// percents the phantom `role="scrollbar"` nodes report as
/// `aria-valuenow`, and into where each axis's thumb is drawn.
///
/// Separate from `scrollbar.dart` because the only part of that update
/// path a test can reach is this one: reading six properties off a live
/// `Element` needs a browser, but deciding what those six numbers mean
/// does not. Keeping the decision here is what makes "vertical is at
/// 50%" a statement a VM test can falsify.
library;

import 'package:coui_core/coui_core.dart';

/// One scrollable element's scroll geometry, both axes, as read off the
/// DOM — named after the properties they come from so the mapping at the
/// read site is a rename and nothing else.
typedef ScrollbarViewportGeometry = ({
  double scrollTop,
  double scrollHeight,
  double clientHeight,
  double scrollLeft,
  double scrollWidth,
  double clientWidth,
});

/// Both axes' scroll positions as whole percents of their own scrollable
/// ranges.
///
/// Each axis is derived from its own triple — vertical from the height
/// triple, horizontal from the width triple. That pairing is the thing
/// worth stating out loud: an element is routinely scrollable on one
/// axis and not the other, so a bar reading the wrong triple reports a
/// flat `0` (or a frozen `100`) that looks exactly like a bar which
/// simply has not been scrolled yet.
///
/// **Reach of the horizontal axis: left-to-right only.** `scrollLeft` is
/// read as a distance from the left edge, which is what it is in a
/// left-to-right box. In a right-to-left one it starts at `0` on the
/// right and runs *negative* leftward, so every position lands below the
/// range and clamps to the start — a right-to-left horizontal bar reports
/// `0` wherever it is scrolled to. That is the behaviour this file has
/// always had, and it is written down rather than left to be discovered:
/// the tests beside it pin the left-to-right answers, and a green suite
/// should not be read as saying the other direction works.
/// (`readScrollBounds` in `web_dom_utils_web.dart` shows the signed range
/// a fix would have to thread through here.)
({int vertical, int horizontal}) scrollbarPercentsOf(
  ScrollbarViewportGeometry geometry,
) => (
  vertical: scrollbarPercentOfAxis(
    offset: geometry.scrollTop,
    scrollableExtent: geometry.scrollHeight - geometry.clientHeight,
  ),
  horizontal: scrollbarPercentOfAxis(
    offset: geometry.scrollLeft,
    scrollableExtent: geometry.scrollWidth - geometry.clientWidth,
  ),
);

/// The thumb of each axis the bar draws, from one reading of the scroller.
///
/// Both go through [CoreScrollbarThumbLayout] — the arithmetic Flutter's
/// painter is held to — so the thumb stands where the Flutter one would for
/// the same sizes. An axis the bar does not report on, or one with nothing
/// to scroll, is `null`.
///
/// [margin] is the gap the thumb keeps from both ends of its track and
/// [minLength] the shortest it may be, both in the CSS pixels the geometry
/// was measured in.
///
/// The horizontal offset is read as a distance from the *inline start*
/// edge, so a right-to-left box — whose `scrollLeft` runs negative from
/// `0` at its right edge — places its thumb the same way a left-to-right one
/// does. (The percent above does not do this yet; see its note.)
({CoreScrollbarThumbLayout? vertical, CoreScrollbarThumbLayout? horizontal})
scrollbarThumbsOf(
  ScrollbarViewportGeometry geometry, {
  required CoreScrollbarAxis axis,
  required double margin,
  required double minLength,
}) {
  final draws = (
    vertical: axis == .vertical || axis == .both,
    horizontal: axis == .horizontal || axis == .both,
  );

  return (
    vertical: draws.vertical
        ? CoreScrollbarThumbLayout.of(
            viewportExtent: geometry.clientHeight,
            contentExtent: geometry.scrollHeight,
            scrollOffset: geometry.scrollTop,
            margin: margin,
            minLength: minLength,
          )
        : null,
    horizontal: draws.horizontal
        ? CoreScrollbarThumbLayout.of(
            viewportExtent: geometry.clientWidth,
            contentExtent: geometry.scrollWidth,
            scrollOffset: geometry.scrollLeft.abs(),
            margin: margin,
            minLength: minLength,
          )
        : null,
  );
}
