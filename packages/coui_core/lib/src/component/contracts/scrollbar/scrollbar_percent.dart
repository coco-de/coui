/// The scrollbar affordance's reported position, as arithmetic both
/// platforms run rather than each deriving it from its own geometry.
///
/// Flutter reports it as a slider-shaped `Semantics.value` and Web as
/// `aria-valuenow` on a phantom `role="scrollbar"` node — two mechanisms
/// for one capability, so the number behind them belongs in one place.
/// Two copies of a rounding-and-clamping expression drift silently: the
/// value keeps rendering on both sides while one of them is wrong, and
/// nothing about the markup says which.
library;

/// Lower bound of the percent range the scrollbar affordance reports —
/// Web's `aria-valuemin`, and the floor of Flutter's `value` string.
const int kScrollbarPercentMin = 0;

/// Upper bound of the percent range the scrollbar affordance reports —
/// Web's `aria-valuemax`, and the ceiling of Flutter's `value` string.
const int kScrollbarPercentMax = 100;

/// Position along one axis as a whole percent of that axis's scrollable
/// range.
///
/// [offset] is how far that axis has been scrolled from its start, and
/// [scrollableExtent] is how far it *can* be scrolled — content extent
/// minus viewport extent on Web (`scrollHeight - clientHeight`), and
/// `maxScrollExtent - minScrollExtent` on Flutter. Both platforms
/// already hold the pair in that shape, so neither has to translate.
///
/// A non-positive [scrollableExtent] means the axis does not scroll at
/// all, and the only honest thing to report there is the start:
/// dividing by it would produce infinity or NaN, and announcing "100%"
/// for content that fits would tell a screen-reader user they are at the
/// bottom of something they never moved.
///
/// The result is clamped because callers hand over live browser
/// geometry, and both platforms overscroll past their own bounds —
/// rubber-band scrolling reports a negative [offset], and a momentum
/// fling reports one past [scrollableExtent].
int scrollbarPercentOfAxis({
  required double offset,
  required double scrollableExtent,
}) {
  if (!scrollableExtent.isFinite || scrollableExtent <= 0 || !offset.isFinite) {
    return kScrollbarPercentMin;
  }
  // Clamped as a fraction rather than as a percent: bounding the ratio
  // first keeps the multiplication inside 0–100, so no arithmetic on a
  // wildly out-of-range offset can reach `round()` as an infinity, which
  // throws rather than saturating.
  final fraction = (offset / scrollableExtent).clamp(0.0, 1.0);
  return (fraction * kScrollbarPercentMax).round();
}
