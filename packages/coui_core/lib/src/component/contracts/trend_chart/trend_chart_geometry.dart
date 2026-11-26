/// Platform-neutral geometry for `TrendChart`.
///
/// Both platforms draw the same chart from these numbers: Flutter maps
/// the fractions to canvas pixels, Web maps them to CSS percentages. The
/// axis rounding, the baseline and the label choice live here once, so
/// the two renderers cannot disagree about where a point sits.
library;

import 'dart:math' as math;

import 'package:coui_core/src/component/contracts/trend_chart/trend_chart_variant.dart';
import 'package:meta/meta.dart';

/// Value-axis domain, ticks and per-point vertical fractions for one
/// `TrendChart` series.
///
/// Fractions run from `0` (bottom of the plot) to `1` (top). Horizontal
/// positions are slot-based — every point owns an equal-width slot and
/// sits at its centre ([slotCenter]) — so a line and a bar chart of the
/// same data put each point at the same x.
@immutable
class CoreTrendChartGeometry {
  const CoreTrendChartGeometry._({
    required this.domainMin,
    required this.domainMax,
    required this.ticks,
    required this.pointFractions,
    required this.baselineFraction,
    required this.referenceFraction,
    required this.tickDecimals,
  });

  /// Computes the geometry for [values].
  ///
  /// The domain spans every value and [referenceValue], rounded outward
  /// to a "nice" step (1 · 2 · 5 × 10ⁿ) chosen so the axis has about
  /// [tickCount] intervals. A [CoreTrendChartVariant.bar] domain always
  /// contains zero — a bar's length is its value, so a bar chart whose
  /// axis does not start at zero misstates every bar. A line keeps a
  /// tight domain so small movements stay visible.
  factory CoreTrendChartGeometry.compute({
    required List<double> values,
    required CoreTrendChartVariant variant,
    required int tickCount,
    double? referenceValue,
  }) {
    final all = [...values, ?referenceValue];
    var low = all.isEmpty ? 0.0 : all.reduce(math.min);
    var high = all.isEmpty ? 0.0 : all.reduce(math.max);
    if (variant == CoreTrendChartVariant.bar) {
      low = math.min(low, 0);
      high = math.max(high, 0);
    }
    if (low == high) {
      // A flat series (or a single point) has no extent to round. Give
      // it one so the line sits mid-plot instead of on an edge.
      final pad = low == 0 ? 1.0 : low.abs() * _kFlatSeriesPadFraction;
      low -= variant == CoreTrendChartVariant.bar && low >= 0 ? 0 : pad;
      high += variant == CoreTrendChartVariant.bar && high <= 0 ? 0 : pad;
    }

    final intervals = math.max(1, tickCount);
    final step = _niceStep((high - low) / intervals);
    final decimals = math.max(0, -(math.log(step) / math.ln10).floor());
    final domainMin = _round((low / step).floor() * step, decimals);
    final domainMax = _round((high / step).ceil() * step, decimals);
    final count = ((domainMax - domainMin) / step).round();
    final ticks = [
      for (var i = 0; i <= count; i++) _round(domainMin + i * step, decimals),
    ];

    double fraction(double v) => (v - domainMin) / (domainMax - domainMin);

    return CoreTrendChartGeometry._(
      domainMin: domainMin,
      domainMax: domainMax,
      ticks: ticks,
      pointFractions: [for (final v in values) fraction(v)],
      baselineFraction: fraction(0).clamp(0.0, 1.0),
      referenceFraction: referenceValue == null
          ? null
          : fraction(referenceValue),
      tickDecimals: decimals,
    );
  }

  /// Lower bound of the value axis (the bottom tick).
  final double domainMin;

  /// Upper bound of the value axis (the top tick).
  final double domainMax;

  /// Axis tick values, ascending from [domainMin] to [domainMax], at an
  /// even step — so the ticks are evenly spaced on the plot too.
  final List<double> ticks;

  /// Vertical fraction of each value, indexed 1:1 with the input.
  final List<double> pointFractions;

  /// Vertical fraction of zero, clamped into the plot — where bars grow
  /// from.
  final double baselineFraction;

  /// Vertical fraction of the reference value, or `null` when unset.
  final double? referenceFraction;

  /// Decimal places the tick step needs (`0` for a step of 1 or more).
  final int tickDecimals;

  /// Vertical fraction of tick [index] in [ticks].
  double tickFraction(int index) => ticks.length < 2
      ? 0
      : (ticks[index] - domainMin) / (domainMax - domainMin);

  /// Locale-neutral tick label: Latin digits, [tickDecimals] places,
  /// no grouping. Callers that need grouping or units pass their own
  /// formatter to the chart.
  String formatTick(double value) => formatNumber(value, tickDecimals);

  /// Horizontal fraction (`0` = start edge, `1` = end edge) of the centre
  /// of slot [index] among [count] equal slots.
  static double slotCenter(int index, int count) => (index + 0.5) / count;

  /// Indices of the points whose date labels the axis shows — the first,
  /// the middle and the last, de-duplicated. Three labels keep the axis
  /// readable at any width and text scale; the rest stay reachable
  /// through the per-point tooltip and assistive technology.
  static List<int> dateLabelIndices(int count) => switch (count) {
    0 => const [],
    1 => const [0],
    2 => const [0, 1],
    _ => [0, (count - 1) ~/ 2, count - 1],
  };

  /// Locale-neutral number: Latin digits, [decimals] places, trailing
  /// zeros kept so a column of ticks stays aligned.
  static String formatNumber(double value, int decimals) {
    final text = value.toStringAsFixed(decimals);
    // `-0` and `-0.0` read as a sign error on an axis.
    return double.parse(text) == 0 ? 0.0.toStringAsFixed(decimals) : text;
  }

  /// Locale-neutral date: ISO `yyyy-MM-dd`. Used only when the caller
  /// supplied no label of its own.
  static String formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-'
        '${two(date.day)}';
  }

  static double _niceStep(double raw) {
    if (raw <= 0 || raw.isNaN || raw.isInfinite) return 1;
    final exponent = (math.log(raw) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final normalized = raw / magnitude;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;
    return nice * magnitude;
  }

  static double _round(double value, int decimals) =>
      double.parse(value.toStringAsFixed(decimals));
}

/// Padding added around a flat series, as a fraction of its value.
/// Not a design token: it only gives a zero-extent domain some extent.
const double _kFlatSeriesPadFraction = 0.1;
