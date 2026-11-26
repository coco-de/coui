/// Minute-interval arithmetic for the time picker's minute segment.
library;

import 'package:coui_core/src/util/iso_time.dart';

/// Where a minute lands when a time picker's minute segment works in steps of
/// an interval — a typed minute (`snap`) and an arrow key (`stepUp` /
/// `stepDown`).
///
/// One definition for both platforms: the Flutter and Web pickers each call
/// this instead of keeping their own copy of the rounding, so a rule cannot
/// be changed on one and left behind on the other. The rules are pinned to a
/// vector table both pickers' tests read.
///
/// An interval is a divisor of an hour ([validIntervals]) — it has to be, or
/// the multiples would not repeat every hour and `:00` would not be one of
/// them. Every result is a minute in `0..59`: the top of the hour wraps to
/// `:00` and the hour is never touched, because this arithmetic has no hour
/// to carry into. A picker that wants `:53` at 15 minutes to mean the next
/// hour has to say so itself; this one does not.
abstract final class CoreMinuteInterval {
  const CoreMinuteInterval._();

  /// Every interval a minute segment can step by: the divisors of an hour.
  static const List<int> validIntervals = [
    1,
    2,
    3,
    4,
    5,
    6,
    10,
    12,
    15,
    20,
    30,
    60,
  ];

  /// Whether [interval] is one a minute segment can step by — a positive
  /// divisor of an hour.
  static bool isValid(int interval) =>
      interval > 0 && Duration.minutesPerHour % interval == 0;

  /// The multiple of [interval] nearest to [minute], a tie going to the later
  /// one (round half up), as a minute in `0..59`.
  ///
  /// `:60` is a candidate like any other multiple and wraps to `:00` — so at
  /// 15 minutes `:53` and later land on `:00`, not `:45`, and the hour stays.
  /// A minute past `:59` is clamped to `:59` first, as the segment has always
  /// clamped what is typed into it. A minute that is already a multiple stays
  /// where it is, so snapping twice changes nothing.
  static int snap(int minute, {required int interval}) {
    assert(isValid(interval), _invalid(interval));
    final clamped = minute.clamp(0, IsoTime.maxMinute);
    // Round half up in whole numbers: floor(clamped / interval + 1/2).
    final steps = (2 * clamped + interval) ~/ (2 * interval);

    return (steps * interval) % Duration.minutesPerHour;
  }

  /// The multiple of [interval] strictly after [minute], as a minute in
  /// `0..59` — from a multiple it is one interval on, from between two it is
  /// the next one.
  ///
  /// Past the last multiple it wraps to `:00` without carrying into the hour.
  static int stepUp(int minute, {required int interval}) {
    assert(isValid(interval), _invalid(interval));
    final clamped = minute.clamp(0, IsoTime.maxMinute);

    return ((clamped ~/ interval + 1) * interval) % Duration.minutesPerHour;
  }

  /// The multiple of [interval] strictly before [minute], as a minute in
  /// `0..59` — from a multiple it is one interval back, from between two it
  /// is the one just below.
  ///
  /// Below `:00` it wraps to the last multiple without borrowing from the
  /// hour.
  static int stepDown(int minute, {required int interval}) {
    assert(isValid(interval), _invalid(interval));
    final clamped = minute.clamp(0, IsoTime.maxMinute);
    final below = clamped % interval == 0
        ? clamped ~/ interval - 1
        : clamped ~/ interval;

    return (below * interval + Duration.minutesPerHour) %
        Duration.minutesPerHour;
  }

  static String _invalid(int interval) =>
      'minuteInterval must divide an hour '
      '(${validIntervals.join(', ')}), got $interval';
}
