/// ISO 8601 time formatter helpers + 24-hour clock domain bounds.
///
/// **Not** design tokens — these are domain-logic constants
/// (calendrical bounds of the 24-hour clock, ISO `HH:MM[:SS]`
/// formatter spec). Lives under `util/` so Flutter and Web pickers
/// share one source instead of duplicating the bounds per platform.
library;

/// 24-hour clock domain bounds + ISO `HH:MM[:SS]` formatter helpers.
///
/// `Duration.hoursPerDay` (24) / `Duration.minutesPerHour` (60) /
/// `Duration.secondsPerMinute` (60) come from the Dart stdlib; the
/// `Max*` constants are simply `…- 1` so the integer range fits
/// `int.clamp(0, max)`.
abstract final class IsoTime {
  const IsoTime._();

  /// Maximum hour in 24h mode (`23`).
  static const int maxHour24 = Duration.hoursPerDay - 1;

  /// Maximum hour in 12h mode (`12`).
  static const int maxHour12 = Duration.hoursPerDay ~/ 2;

  /// Maximum minute (`59`).
  static const int maxMinute = Duration.minutesPerHour - 1;

  /// Maximum second (`59`).
  static const int maxSecond = Duration.secondsPerMinute - 1;

  /// Left-pads [n] to two digits with `'0'` — used for ISO
  /// `HH:MM[:SS]` formatting.
  static String padTwo(int n) => n.toString().padLeft(2, '0');
}
