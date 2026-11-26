import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/display/chip/chip.dart';
import 'package:coui_web/src/components/display/trend_chart/trend_chart_style.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform trend chart for CoUI Web — a time series drawn
/// as a line or bars, with optional period chips, a summary slot and a
/// dashed reference line.
///
/// Data and every display string come from the caller; the chart only
/// positions them. Uses [CoreTrendChartContract] from `coui_core`, so the
/// Flutter `TrendChart` takes the same named properties. Rendering is
/// plain DOM + inline SVG — no chart library.
///
/// Example:
/// ```dart
/// TrendChart(
///   semanticLabel: '월별 구독자 추이',
///   periods: const ['7일', '30일', '12개월'],
///   selectedPeriodIndex: 1,
///   points: [
///     CoreTrendPoint(date: DateTime(2026, 9), value: 11200, label: '9월'),
///     CoreTrendPoint(date: DateTime(2026, 10), value: 12480, label: '10월'),
///   ],
/// )
/// ```
class TrendChart extends UiComponent
    implements CoreTrendChartContract<Component> {
  /// Creates a [TrendChart].
  const TrendChart({
    required this.points,
    this.variant = CoreTrendChartVariant.defaultVariant,
    this.referenceValue,
    this.referenceLabel,
    this.valueFormatter,
    this.periods = const [],
    this.selectedPeriodIndex,
    this.onPeriodChanged,
    this.summary,
    this.empty,
    this.semanticLabel,
    this.trendChartStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.tag = 'div',
  });

  @override
  final CoreTrendChartVariant variant;

  @override
  final List<CoreTrendPoint> points;

  @override
  final double? referenceValue;

  @override
  final String? referenceLabel;

  @override
  final String Function(double value)? valueFormatter;

  @override
  final List<String> periods;

  @override
  final int? selectedPeriodIndex;

  @override
  final void Function(int index)? onPeriodChanged;

  @override
  final Component? summary;

  @override
  final Component? empty;

  @override
  final String? semanticLabel;

  @override
  final CoreTrendChartStyle? trendChartStyle;

  @override
  Component build(BuildContext context) {
    final resolved = resolveTrendChart(
      context,
      variant: variant,
      points: points,
      referenceValue: referenceValue,
      valueFormatter: valueFormatter,
      trendChartStyle: trendChartStyle,
    );
    final currentReferenceLabel = referenceLabel;
    final onPeriod = onPeriodChanged;

    return div(
      [
        ?summary,
        if (periods.isNotEmpty)
          div(
            [
              for (var i = 0; i < periods.length; i++)
                Chip(
                  label: periods[i],
                  selected: i == selectedPeriodIndex,
                  onTap: onPeriod == null ? null : () => onPeriod(i),
                  chipStyle: resolved.periodChipStyle,
                ),
            ],
            classes: resolved.periodRow.className,
            styles: resolved.periodRow.inlineStyles,
          ),
        if (points.isEmpty) ?empty else _buildPlot(resolved),
        if (points.isNotEmpty &&
            referenceValue != null &&
            currentReferenceLabel != null)
          div(
            [
              _dashSvg(resolved.legendSwatch, resolved.referenceStroke),
              span(
                [Text(currentReferenceLabel)],
                classes: resolved.legendLabel.className,
                styles: resolved.legendLabel.inlineStyles,
              ),
            ],
            classes: resolved.legend.className,
            styles: resolved.legend.inlineStyles,
          ),
      ],
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: componentAttributes,
      events: this.events,
    );
  }

  Component _buildPlot(ResolvedTrendChart resolved) {
    final series = resolved.series;
    final reference = resolved.reference;
    final isLine = variant == CoreTrendChartVariant.line;

    return div(
      [
        div(
          [
            div(
              [
                for (final label in series.tickLabels)
                  _label(resolved.axisLabel, label),
              ],
              classes: resolved.tickLabels.className,
              styles: resolved.tickLabels.inlineStyles,
            ),
            // Holds the date row's height so the value axis ends where
            // the plot ends — same spacer as the Flutter twin.
            _label(resolved.axisSpacer, ' '),
          ],
          classes: resolved.tickColumn.className,
          styles: resolved.tickColumn.inlineStyles,
          attributes: const {'aria-hidden': 'true'},
        ),
        div(
          [
            div(
              [
                for (final grid in resolved.gridLines) _decor(grid),
                if (reference != null)
                  _dashSvg(reference, resolved.referenceStroke),
                for (final bar in resolved.bars) _decor(bar),
                if (isLine && points.length > 1)
                  Component.element(
                    tag: 'svg',
                    classes: resolved.line.className,
                    styles: resolved.line.inlineStyles,
                    attributes: const {
                      'viewBox': '0 0 100 100',
                      'preserveAspectRatio': 'none',
                      'aria-hidden': 'true',
                    },
                    children: [
                      Component.element(
                        tag: 'polyline',
                        styles: resolved.lineStroke.inlineStyles,
                        attributes: {
                          'points': series.linePoints,
                          'fill': 'none',
                          'stroke': 'currentColor',
                          'stroke-linejoin': 'round',
                          'stroke-linecap': 'round',
                          'vector-effect': 'non-scaling-stroke',
                        },
                      ),
                    ],
                  ),
                if (isLine) _decor(resolved.marker),
                div(
                  [
                    for (final label in series.pointLabels)
                      Tooltip(
                        classes: resolved.hitSlot.className,
                        css: resolved.hitSlot.inlineStyles,
                        message: label,
                        child: div(
                          const [],
                          classes: resolved.hitTarget.className,
                          styles: resolved.hitTarget.inlineStyles,
                          attributes: {'role': 'listitem', 'aria-label': label},
                        ),
                      ),
                  ],
                  classes: resolved.hitRow.className,
                  styles: resolved.hitRow.inlineStyles,
                  attributes: const {'role': 'list'},
                ),
              ],
              classes: resolved.plot.className,
              styles: resolved.plot.inlineStyles,
              attributes: {
                'role': 'group',
                'aria-label': ?semanticLabel,
              },
            ),
            div(
              [
                for (var i = 0; i < series.dateLabels.length; i++)
                  _label(resolved.dateLabels[i], series.dateLabels[i]),
              ],
              classes: resolved.dateRow.className,
              styles: resolved.dateRow.inlineStyles,
              attributes: const {'aria-hidden': 'true'},
            ),
          ],
          classes: resolved.plotColumn.className,
          styles: resolved.plotColumn.inlineStyles,
        ),
      ],
      classes: resolved.plotRow.className,
      styles: resolved.plotRow.inlineStyles,
    );
  }

  Component _label(WebElementChrome chrome, String text) => span(
    [Text(text)],
    classes: chrome.className,
    styles: chrome.inlineStyles,
  );

  Component _decor(WebElementChrome chrome) => div(
    const [],
    classes: chrome.className,
    styles: chrome.inlineStyles,
    attributes: const {'aria-hidden': 'true'},
  );

  /// A horizontal dashed line filling [svgChrome] — the reference line
  /// and its legend swatch share the same stroke.
  Component _dashSvg(WebElementChrome svgChrome, WebElementChrome stroke) =>
      Component.element(
        tag: 'svg',
        classes: svgChrome.className,
        styles: svgChrome.inlineStyles,
        attributes: const {'aria-hidden': 'true'},
        children: [
          Component.element(
            tag: 'line',
            styles: stroke.inlineStyles,
            attributes: const {
              'x1': '0',
              'y1': '50%',
              'x2': '100%',
              'y2': '50%',
              'stroke': 'currentColor',
            },
          ),
        ],
      );

  @override
  TrendChart copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? tag,
    CoreTrendChartVariant? variant,
    List<CoreTrendPoint>? points,
    double? referenceValue,
    String? referenceLabel,
    String Function(double value)? valueFormatter,
    List<String>? periods,
    int? selectedPeriodIndex,
    void Function(int index)? onPeriodChanged,
    Component? summary,
    Component? empty,
    String? semanticLabel,
    CoreTrendChartStyle? trendChartStyle,
  }) {
    return TrendChart(
      key: key ?? this.key,
      variant: variant ?? this.variant,
      points: points ?? this.points,
      referenceValue: referenceValue ?? this.referenceValue,
      referenceLabel: referenceLabel ?? this.referenceLabel,
      valueFormatter: valueFormatter ?? this.valueFormatter,
      periods: periods ?? this.periods,
      selectedPeriodIndex: selectedPeriodIndex ?? this.selectedPeriodIndex,
      onPeriodChanged: onPeriodChanged ?? this.onPeriodChanged,
      summary: summary ?? this.summary,
      empty: empty ?? this.empty,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      trendChartStyle: trendChartStyle ?? this.trendChartStyle,
      attributes: attributes ?? componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }
}

/// Chain sugar mirroring the Flutter `TrendChart.withStyle` extension.
extension TrendChartStyleChain on TrendChart {
  /// Returns a copy of this [TrendChart] with [patch] merged into
  /// [trendChartStyle] (patch fields win on conflict).
  TrendChart withStyle(CoreTrendChartStyle patch) => copyWith(
    trendChartStyle: (trendChartStyle ?? const CoreTrendChartStyle()).merge(
      patch,
    ),
  );
}
