/// What a frame is allowed to cost, and how the two platforms measure it.
///
/// A frame has a budget — the time between two refreshes of the display — and
/// every threshold of the quality governor is a multiple of it, so one
/// statement holds on a 60 Hz panel, a 120 Hz one and a 30 fps embed alike.
/// Nothing in the governor says "16 milliseconds".
library;

/// The budget of one frame, from the display's refresh rate.
abstract final class CoreFrameBudget {
  /// The refresh rate assumed when the platform reports none.
  ///
  /// **Designer-judgement value (디자이너 판단 값):** 60 Hz is the panel most
  /// screens still are. A 120 Hz display read as 60 Hz is judged against twice
  /// the budget it has, so it degrades later than it should; the other way
  /// round degrades earlier. The first error is the safer one for a feature
  /// whose cost is a plainer look.
  static const double defaultRefreshRate = 60;

  /// The highest refresh rate read as real. Anything above is a unit mistake
  /// (a period read as a rate) and is clamped, so a budget is never a few
  /// microseconds.
  static const double highestRefreshRate = 480;

  /// The refresh rates displays commonly run at. An estimate close to one of
  /// them is read as that rate, so a page measured at 59.94 or 60.4 frames per
  /// second has the budget of a 60 Hz panel and not one a hair off it.
  static const List<double> standardRefreshRates = [
    48,
    50,
    60,
    72,
    75,
    90,
    100,
    120,
    144,
    165,
    240,
  ];

  /// How far an estimate may be from a standard rate and still be read as it,
  /// as a fraction of that rate.
  ///
  /// **Designer-judgement value (디자이너 판단 값):** wide enough to take the
  /// 59.94 Hz of NTSC-derived panels and the jitter of a sampled estimate, and
  /// narrow enough that the nearer of two neighbouring rates still wins (72 and
  /// 75 Hz are 4 % apart, so an estimate between them is read as the closer).
  static const double snapTolerance = 0.05;

  /// The fewest intervals an estimate is made from; fewer returns null.
  static const int minimumEstimateIntervals = 30;

  /// How many intervals a page collects before it reads its display's rate off
  /// them — a second of a 60 Hz display.
  ///
  /// **Designer-judgement value (디자이너 판단 값):** twice the minimum, so the
  /// shortest quarter of the sample is still a few dozen frames and one stall
  /// cannot be most of it.
  static const int estimateIntervals = 60;

  /// Which interval of the sorted sample the refresh interval is read from.
  ///
  /// **Designer-judgement value (디자이너 판단 값):** a frame can arrive late
  /// but never early, so the shortest intervals are the display's. The 25th
  /// percentile is the shortest ones with the odd bunched-up frame left out;
  /// the median would read a page that drops every other frame as a 30 Hz
  /// display.
  static const int estimatePercentile = 25;

  /// The budget, in microseconds, of one frame on a display refreshing at
  /// [refreshRate] Hz. A missing, non-finite or non-positive rate is the
  /// [defaultRefreshRate]'s.
  static int microsFor(double? refreshRate) {
    final rate =
        refreshRate == null || !refreshRate.isFinite || refreshRate <= 0
        ? defaultRefreshRate
        : refreshRate > highestRefreshRate
        ? highestRefreshRate
        : refreshRate;

    return (Duration.microsecondsPerSecond / rate).round();
  }

  /// The refresh rate, in Hz, the intervals between consecutive frames
  /// (microseconds) were produced at, or null when there are too few of them
  /// to say.
  ///
  /// The page is not asked what its display does — the browser does not say —
  /// so the rate is read off the frames it already draws: the shortest
  /// intervals are the display's, and the result is snapped to a standard
  /// rate. An estimate below the lowest standard rate is the default's:
  /// either the display really is that slow, which is rare, or the page was
  /// already dropping frames while it was measured, and reading that as the
  /// display would excuse the very jank the governor exists to answer.
  static double? estimateRefreshRate(List<int> intervals) {
    if (intervals.length < minimumEstimateIntervals) return null;

    final interval = CoreFrameStats.percentile(intervals, estimatePercentile);
    if (interval <= 0) return null;

    final rate = Duration.microsecondsPerSecond / interval;
    double? nearest;
    for (final standard in standardRefreshRates) {
      final off = (rate - standard).abs() / standard;
      if (off <= snapTolerance &&
          (nearest == null || off < (rate - nearest).abs() / nearest)) {
        nearest = standard;
      }
    }
    if (nearest != null) return nearest;
    if (rate < standardRefreshRates.first) return defaultRefreshRate;

    return rate > highestRefreshRate ? highestRefreshRate : rate;
  }
}

/// Order statistics over frame times, defined once so the governor and the
/// harness that calibrates it read the same number.
abstract final class CoreFrameStats {
  /// The [percentile]-th (0–100) of [values] by the nearest-rank definition:
  /// the smallest value that at least that share of the values is not above.
  ///
  /// Nearest-rank rather than interpolated because the values are frames that
  /// happened: the 95th percentile of a window is a frame somebody saw, not a
  /// time between two of them. [values] is not modified. Throws on an empty
  /// list.
  static int percentile(List<int> values, int percentile) {
    if (values.isEmpty) throw ArgumentError('no values');
    final sorted = List<int>.of(values)..sort();
    final rank = (percentile.clamp(0, 100) / 100 * sorted.length).ceil();

    return sorted[(rank - 1).clamp(0, sorted.length - 1)];
  }
}
