/// Per-date marker data for `Calendar`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:meta/meta.dart';

/// What a `Calendar` draws under one date — a row of dots standing for
/// [count] things that fall on that day.
///
/// A marker is **data**, not chrome: it is what the caller knows about the
/// day (three vaccinations due, one meetup, a sold-out night). How a dot
/// looks — its size, spacing, shape, the default fill and the fill used on a
/// selected date — lives on `CoreCalendarStyle` (`marker*` fields) so a
/// project can restyle every calendar in one place.
///
/// The row is capped at `CoreCalendarStyle.markerMaxCount` dots, so a day
/// with more things than that looks the same as a day with exactly that many.
/// The exact [count] is still spoken: it reaches assistive technology as part
/// of the date's accessible name, which is why a marker must never rely on
/// its dot colour alone to say what it means.
@immutable
class CoreCalendarMarker {
  /// Creates a [CoreCalendarMarker].
  ///
  /// [count] must be at least 1 — a day with nothing on it has no marker
  /// (return `null` from the builder instead).
  const CoreCalendarMarker({
    this.count = defaultCount,
    this.color,
    this.semanticsLabel,
  }) : assert(count >= defaultCount, 'A marker stands for at least one item');

  /// The smallest — and default — number of items a marker stands for.
  static const int defaultCount = 1;

  /// How many items fall on the date. Drawn as `min(count, markerMaxCount)`
  /// dots and spoken in full.
  final int count;

  /// Fill for this date's dots on an unselected cell. `null` defers to
  /// `CoreCalendarStyle.markerColor`.
  ///
  /// A cell on a selection fill paints the fill's own dot colour instead —
  /// `CoreCalendarStyle.selectedMarkerColor` on a selected date or range
  /// endpoint, `CoreCalendarStyle.rangeMarkerColor` inside a range — so the
  /// dots stay legible whatever category colour the caller chose. Colour is
  /// a supplement — the [semanticsLabel] (or the localized count) carries
  /// the meaning.
  final CoreColor? color;

  /// What the marker means, read out after the date — for example
  /// `'2 vaccinations due'`. `null` falls back to the localized item count.
  final String? semanticsLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCalendarMarker &&
          runtimeType == other.runtimeType &&
          count == other.count &&
          color == other.color &&
          semanticsLabel == other.semanticsLabel;

  @override
  int get hashCode => Object.hash(count, color, semanticsLabel);
}

/// Callback that returns the marker for [date], or `null` when the date has
/// nothing to mark.
///
/// Called once per visible day cell on every build, so keep it a cheap
/// lookup (a `Map` keyed by date, not a query).
typedef CoreCalendarMarkerBuilder = CoreCalendarMarker? Function(DateTime date);
