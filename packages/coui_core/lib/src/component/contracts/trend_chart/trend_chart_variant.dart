/// Visual variant of the unified `TrendChart` component.
library;

/// How a `TrendChart` draws its series.
enum CoreTrendChartVariant {
  /// A polyline through every point, with the last point marked.
  line,

  /// One bar per point, growing from the zero baseline.
  bar;

  /// Default variant — a line, the shape most trend screens use.
  static const CoreTrendChartVariant defaultVariant = line;
}
