/// Platform-neutral geometry for `CategoryBreakdown`.
///
/// Both platforms read the shares, the printed percentages and the donut
/// arcs from here, so a category cannot read 42% on one platform and 41%
/// on the other.
library;

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Shares, printed percentages and donut arcs for one set of values.
@immutable
class CoreCategoryBreakdownGeometry {
  const CoreCategoryBreakdownGeometry._({
    required this.total,
    required this.fractions,
    required this.percents,
    required this.arcStarts,
    required this.arcSweeps,
  });

  /// Computes the geometry for [values].
  ///
  /// Negative values count as zero. [arcGapTurns] is the empty space left
  /// between adjacent donut arcs, as a fraction of a full turn — see
  /// [arcGapTurnsFor].
  factory CoreCategoryBreakdownGeometry.compute(
    List<double> values, {
    double arcGapTurns = 0,
  }) {
    final clamped = [for (final v in values) math.max(v, 0).toDouble()];
    final total = clamped.fold<double>(0, (a, b) => a + b);
    final fractions = total > 0
        ? [for (final v in clamped) v / total]
        : List<double>.filled(clamped.length, 0);

    // Gaps only separate arcs that are actually drawn; a lone category
    // fills the whole ring.
    final drawn = fractions.where((f) => f > 0).length;
    final gap = drawn > 1 ? arcGapTurns : 0.0;
    final starts = <double>[];
    final sweeps = <double>[];
    var cursor = 0.0;
    for (final f in fractions) {
      starts.add(cursor + (f > 0 ? gap / 2 : 0));
      sweeps.add(f > 0 ? math.max(0, f - gap) : 0);
      cursor += f;
    }

    return CoreCategoryBreakdownGeometry._(
      total: total,
      fractions: fractions,
      percents: _largestRemainder(fractions),
      arcStarts: starts,
      arcSweeps: sweeps,
    );
  }

  /// Sum of the (non-negative) values. Zero means there is nothing to
  /// draw.
  final double total;

  /// Each category's share of [total], `0..1`, indexed 1:1 with the
  /// input.
  final List<double> fractions;

  /// Each category's share as a whole percentage. Rounded by largest
  /// remainder, so the printed numbers always add up to exactly 100 —
  /// three thirds read 34 · 33 · 33, never 33 · 33 · 33.
  final List<int> percents;

  /// Start of each donut arc, in turns from the top (`0..1`).
  final List<double> arcStarts;

  /// Length of each donut arc, in turns. Zero for an empty category.
  final List<double> arcSweeps;

  /// Whether there is anything to draw.
  bool get isEmpty => total <= 0;

  /// The printed share of category [index] (e.g. `'42%'`). Latin digits
  /// and a percent sign — the one number format a chart chrome owns.
  String percentLabel(int index) => '${percents[index]}%';

  /// Converts a gap length (logical px, measured along the ring's centre
  /// line) into turns for a ring of [diameter] and [thickness].
  static double arcGapTurnsFor({
    required double gap,
    required double diameter,
    required double thickness,
  }) {
    final circumference = math.pi * (diameter - thickness);
    return circumference <= 0 ? 0 : gap / circumference;
  }

  /// Locale-neutral value fallback: Latin digits, no grouping, a decimal
  /// only when the value has one.
  static String formatValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    final text = value.toStringAsFixed(2);
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static List<int> _largestRemainder(List<double> fractions) {
    if (fractions.every((f) => f == 0)) {
      return List.filled(fractions.length, 0);
    }
    final raw = [for (final f in fractions) f * _kPercentTotal];
    final floors = [for (final r in raw) r.floor()];
    var remaining = _kPercentTotal - floors.fold<int>(0, (a, b) => a + b);
    final order = List<int>.generate(raw.length, (i) => i)
      ..sort((a, b) {
        final byRemainder = (raw[b] - floors[b]).compareTo(raw[a] - floors[a]);
        // Ties go to the earlier category so the result is stable.
        return byRemainder != 0 ? byRemainder : a.compareTo(b);
      });
    for (final i in order) {
      if (remaining <= 0) break;
      if (raw[i] == 0) continue;
      floors[i]++;
      remaining--;
    }
    return floors;
  }
}

/// A whole, in percent. Not a design token: the unit of a percentage.
const int _kPercentTotal = 100;
