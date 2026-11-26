/// Clock-digit formatting shared by every CoUI locale on both platforms.
///
/// **Not** design tokens — calendrical logic of the 12/24-hour clock.
/// Each locale owns only its words (the period marker and where it sits
/// relative to the digits); the arithmetic that decides which half of
/// the day an hour belongs to, which number a 12-hour clock shows, and
/// how many digits each field takes lives here once so Flutter and Web
/// cannot answer differently.
library;

import 'package:coui_core/src/util/iso_time.dart';

/// 12/24-hour clock arithmetic + `HH:MM[:SS]` digit rendering.
///
/// The period split is `hour >= 12`, not `hour > 12`: noon (`12:05`) is
/// the first minute of PM, and midnight (`0:05`) shows as `12` on a
/// 12-hour clock. Deciding the split with `>` puts noon in AM and
/// renders midnight as `0` — the shape this class exists to prevent.
abstract final class CoreClockFormat {
  const CoreClockFormat._();

  /// Hours in one half of the day (`12`) — the AM/PM boundary and the
  /// value a 12-hour clock shows for hour `0` and hour `12`.
  static const int hoursPerPeriod = IsoTime.maxHour12;

  /// Whether [hour] (0-23) falls in the afternoon half of the day.
  static bool isPm(int hour) => hour >= hoursPerPeriod;

  /// The number a 12-hour clock shows for [hour] (0-23): `1`–`12`.
  static int hourOfPeriod(int hour) {
    final hourInPeriod = hour % hoursPerPeriod;

    return hourInPeriod == 0 ? hoursPerPeriod : hourInPeriod;
  }

  /// Zero-padded clock digits without any period marker —
  /// `HH:MM` or `HH:MM:SS`.
  ///
  /// With [use24HourFormat] off the hour field is [hourOfPeriod], so the
  /// caller only has to place its locale's AM/PM word around the result.
  static String digits({
    required int hour,
    required int minute,
    int second = 0,
    bool showSeconds = false,
    bool use24HourFormat = true,
  }) {
    final shownHour = use24HourFormat ? hour : hourOfPeriod(hour);
    final hourMinute = '${IsoTime.padTwo(shownHour)}:${IsoTime.padTwo(minute)}';

    return showSeconds ? '$hourMinute:${IsoTime.padTwo(second)}' : hourMinute;
  }
}
