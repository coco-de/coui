import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `CategoryBreakdown`.
///
/// DOM shape:
///
/// ```text
/// bar variant
///   root (<div role=list>)                 // flex column, rowSpacing gap
///     └─ row (<div role=listitem>) × items // aria-label: rowLabels[i]
///          ├─ texts (<div aria-hidden>)
///          │    ├─ label (<span>)
///          │    └─ trailing (<span>) → value (<span>) · percent (<span>)
///          └─ track (<div aria-hidden>)
///               └─ fills[i] (<div>)        // width: share
///
/// donut variant
///   root (<div>)                           // flex-wrap, legendSpacing gap
///     ├─ donut (<div aria-hidden>)         // donutSize square
///     │    ├─ <svg viewBox 0 0 100 100>
///     │    │    └─ arcs[i] (<circle>)      // dash = arc, rotated to top
///     │    └─ donutCenter (<div>)          // caller `center`, optional
///     └─ legend (<div role=list>)          // flex-basis: donutSize
///          └─ legendRow (<div role=listitem>) × items
///               ├─ swatches[i] (<span>)
///               └─ legendTexts (<div aria-hidden>) → label · value · %
/// ```
///
/// The legend wraps under the donut once it would get less than one
/// donut width — the same threshold the Flutter twin computes.
class ResolvedCategoryBreakdown implements WebResolvedChrome {
  /// Creates a [ResolvedCategoryBreakdown].
  const ResolvedCategoryBreakdown({
    required this.root,
    required this.row,
    required this.texts,
    required this.label,
    required this.value,
    required this.percent,
    required this.trailing,
    required this.track,
    required this.fills,
    required this.donut,
    required this.donutSvg,
    required this.arcs,
    required this.donutCenter,
    required this.legend,
    required this.legendRow,
    required this.swatches,
    required this.legendTexts,
    required this.series,
  });

  /// Outer element.
  @override
  final WebElementChrome root;

  /// One bar row.
  final WebElementChrome row;

  /// A row's text line.
  final WebElementChrome texts;

  /// Category label.
  final WebElementChrome label;

  /// Category value.
  final WebElementChrome value;

  /// Category share.
  final WebElementChrome percent;

  /// Value + share group — wraps on its own when even it does not fit.
  final WebElementChrome trailing;

  /// Bar track.
  final WebElementChrome track;

  /// Bar fill per item.
  final List<WebElementChrome> fills;

  /// Donut box.
  final WebElementChrome donut;

  /// Donut `<svg>`.
  final WebElementChrome donutSvg;

  /// Donut arc `<circle>` per item.
  final List<WebElementChrome> arcs;

  /// Donut centre slot wrapper.
  final WebElementChrome donutCenter;

  /// Donut legend.
  final WebElementChrome legend;

  /// One legend row.
  final WebElementChrome legendRow;

  /// Legend swatch per item.
  final List<WebElementChrome> swatches;

  /// A legend row's text line.
  final WebElementChrome legendTexts;

  /// Text content and ring geometry the chrome above renders.
  final ResolvedCategoryBreakdownSeries series;
}

/// Text content and ring geometry for one `CategoryBreakdown` render —
/// not chrome, so it travels separately from the element chromes.
class ResolvedCategoryBreakdownSeries {
  /// Creates a [ResolvedCategoryBreakdownSeries].
  const ResolvedCategoryBreakdownSeries({
    required this.isEmpty,
    required this.valueLabels,
    required this.percentLabels,
    required this.rowLabels,
    required this.ringRadius,
  });

  /// Whether there is nothing to draw (no items or a zero total).
  final bool isEmpty;

  /// Per-category display value.
  final List<String> valueLabels;

  /// Per-category printed share (`'42%'`).
  final List<String> percentLabels;

  /// Per-category accessible sentence (`'<label>, <value>, <share>'`).
  final List<String> rowLabels;

  /// `r` of the arc circles in the `0 0 100 100` viewBox.
  final String ringRadius;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedCategoryBreakdown] for the given [context].
///
/// ```text
/// CoreCategoryBreakdownStyle.default*
///   → theme.coreComponentTheme.categoryBreakdown.style
///   → theme.coreComponentTheme.categoryBreakdown.variantStyles[variant]
///   → widget.categoryBreakdownStyle
/// ```
ResolvedCategoryBreakdown resolveCategoryBreakdown(
  BuildContext context, {
  required CoreCategoryBreakdownVariant variant,
  required List<CoreCategoryBreakdownItem> items,
  CoreCategoryBreakdownStyle? categoryBreakdownStyle,
}) {
  final breakdownTheme = context.theme.coreComponentTheme?.categoryBreakdown;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreCategoryBreakdownStyle(), [
    breakdownTheme?.style,
    breakdownTheme?.variantStyles?[variant],
    categoryBreakdownStyle,
  ]);

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final seriesColors =
      merged.seriesColors ?? CoreCategoryBreakdownStyle.defaultSeriesColors;
  final barHeight =
      merged.barHeight ?? CoreCategoryBreakdownStyle.defaultBarHeight;
  final barBorderRadius =
      merged.barBorderRadius ??
      CoreCategoryBreakdownStyle.defaultBarBorderRadius;
  final rowSpacing =
      merged.rowSpacing ?? CoreCategoryBreakdownStyle.defaultRowSpacing;
  final rowContentSpacing =
      merged.rowContentSpacing ??
      CoreCategoryBreakdownStyle.defaultRowContentSpacing;
  final labelSpacing =
      merged.labelSpacing ?? CoreCategoryBreakdownStyle.defaultLabelSpacing;
  final donutSize =
      merged.donutSize ?? CoreCategoryBreakdownStyle.defaultDonutSize;
  final donutThickness =
      merged.donutThickness ?? CoreCategoryBreakdownStyle.defaultDonutThickness;
  final donutSegmentSpacing =
      merged.donutSegmentSpacing ??
      CoreCategoryBreakdownStyle.defaultDonutSegmentSpacing;
  final legendSpacing =
      merged.legendSpacing ?? CoreCategoryBreakdownStyle.defaultLegendSpacing;
  final swatchSize =
      merged.swatchSize ?? CoreCategoryBreakdownStyle.defaultSwatchSize;
  final swatchBorderRadius =
      merged.swatchBorderRadius ??
      CoreCategoryBreakdownStyle.defaultSwatchBorderRadius;

  // ─── Data layout (shared Core geometry) ──────────────
  final geometry = CoreCategoryBreakdownGeometry.compute(
    [for (final item in items) item.value],
    arcGapTurns: CoreCategoryBreakdownGeometry.arcGapTurnsFor(
      gap: donutSegmentSpacing,
      diameter: donutSize,
      thickness: donutThickness,
    ),
  );
  final valueLabels = [
    for (final item in items)
      item.valueLabel ?? CoreCategoryBreakdownGeometry.formatValue(item.value),
  ];
  final percentLabels = [
    for (var i = 0; i < items.length; i++) geometry.percentLabel(i),
  ];
  CoreColor colorAt(int i) =>
      items[i].color ??
      (seriesColors.isEmpty
          ? CoreCategoryBreakdownStyle.defaultSeriesColors.first
          : seriesColors[i % seriesColors.length]);

  // ─── Stage 2 EMIT (theme-free) ────────────────────────
  final trackBg = emitColor(
    merged.trackColor,
    CoreCategoryBreakdownStyle.defaultTrackColor,
    .background,
  );
  final labelType = emitTypography(
    merged.labelStyle,
    CoreCategoryBreakdownStyle.defaultLabelStyle,
  );
  final valueType = emitTypography(
    merged.valueStyle,
    CoreCategoryBreakdownStyle.defaultValueStyle,
  );
  final percentType = emitTypography(
    merged.percentStyle,
    CoreCategoryBreakdownStyle.defaultPercentStyle,
  );

  String rem(double px) => '${px / kRemDivisor}rem';
  String join(List<String> classes) =>
      classes.where((c) => c.isNotEmpty).join(' ');
  Styles? inline(Map<String, String>? raw) =>
      raw == null ? null : Styles(raw: raw);
  // Ring geometry in the `0 0 100 100` viewBox: the stroke is centred on
  // the circle, so the radius sits half a thickness inside the edge.
  final thicknessUnits = donutThickness / donutSize * kPercentScale;
  final ringRadius = (kPercentScale - thicknessUnits) / 2;
  final circumference = 2 * 3.141592653589793 * ringRadius;
  String unit(double v) => v.toStringAsFixed(3);

  final fills = <WebElementChrome>[];
  final arcs = <WebElementChrome>[];
  final swatches = <WebElementChrome>[];
  for (var i = 0; i < items.length; i++) {
    final bg = emitColor(colorAt(i), colorAt(i), .background);
    final stroke = emitColor(colorAt(i), colorAt(i), .text);
    fills.add(
      WebElementChrome(
        className: join([WebLayout.hFull, bg.className]),
        inlineStyles: Styles(
          raw: {
            ...?bg.inline,
            'width': '${unit(geometry.fractions[i] * kPercentScale)}%',
            'border-radius': barBorderRadius.toValue(),
          },
        ),
      ),
    );
    arcs.add(
      WebElementChrome(
        className: stroke.className,
        inlineStyles: Styles(
          raw: {
            ...?stroke.inline,
            'stroke-width': unit(thicknessUnits),
            'stroke-dasharray':
                '${unit(geometry.arcSweeps[i] * circumference)} '
                '${unit(circumference)}',
            'stroke-dashoffset': unit(-geometry.arcStarts[i] * circumference),
          },
        ),
      ),
    );
    swatches.add(
      WebElementChrome(
        className: join([
          WebLayout.shrinkZero,
          WebLayout.inlineBlock,
          bg.className,
        ]),
        inlineStyles: Styles(
          raw: {
            ...?bg.inline,
            'width': rem(swatchSize),
            'height': rem(swatchSize),
            'border-radius': swatchBorderRadius.toValue(),
          },
        ),
      ),
    );
  }

  // Label, value and share share a line while they fit; once they do not,
  // the value and share wrap below the label — Flutter's `OverflowBar`.
  final textsChrome = WebElementChrome(
    className: join([
      WebLayout.flex,
      WebLayout.flexWrap,
      WebLayout.justifyBetween,
      WebLayout.itemsCenter,
    ]),
    inlineStyles: Styles(
      raw: {
        'column-gap': spaceCss(labelSpacing),
        'row-gap': spaceCss(rowContentSpacing),
      },
    ),
  );

  return ResolvedCategoryBreakdown(
    root: variant == CoreCategoryBreakdownVariant.bar
        ? WebElementChrome(
            className: join([
              WebLayout.flex,
              WebLayout.flexCol,
              WebLayout.wFull,
            ]),
            inlineStyles: Styles(raw: {'gap': spaceCss(rowSpacing)}),
          )
        : WebElementChrome(
            className: join([
              WebLayout.flex,
              WebLayout.flexWrap,
              WebLayout.itemsCenter,
              WebLayout.wFull,
            ]),
            inlineStyles: Styles(raw: {'gap': spaceCss(legendSpacing)}),
          ),
    row: WebElementChrome(
      className: join([WebLayout.flex, WebLayout.flexCol]),
      inlineStyles: Styles(raw: {'gap': spaceCss(rowContentSpacing)}),
    ),
    texts: textsChrome,
    label: WebElementChrome(
      className: join([WebLayout.minWZero, 'break-words', labelType.className]),
      inlineStyles: inline(labelType.inline),
    ),
    value: WebElementChrome(
      className: join([WebLayout.minWZero, 'break-words', valueType.className]),
      inlineStyles: inline(valueType.inline),
    ),
    percent: WebElementChrome(
      className: join([
        WebLayout.minWZero,
        'break-words',
        percentType.className,
      ]),
      inlineStyles: inline(percentType.inline),
    ),
    trailing: WebElementChrome(
      className: join([
        WebLayout.flex,
        WebLayout.flexWrap,
        WebLayout.itemsCenter,
        WebLayout.minWZero,
      ]),
      inlineStyles: Styles(raw: {'gap': spaceCss(labelSpacing)}),
    ),
    track: WebElementChrome(
      className: join([
        WebLayout.wFull,
        WebLayout.overflowHidden,
        trackBg.className,
      ]),
      inlineStyles: Styles(
        raw: {
          ...?trackBg.inline,
          'height': rem(barHeight),
          'border-radius': barBorderRadius.toValue(),
        },
      ),
    ),
    fills: fills,
    donut: WebElementChrome(
      className: join([WebLayout.relative, WebLayout.shrinkZero]),
      inlineStyles: Styles(
        raw: {'width': rem(donutSize), 'height': rem(donutSize)},
      ),
    ),
    donutSvg: WebElementChrome(
      className: join([
        WebLayout.absolute,
        WebLayout.insetZero,
        WebLayout.wFull,
        WebLayout.hFull,
        'rtl:-scale-x-100',
      ]),
    ),
    arcs: arcs,
    // The centre slot inherits the value typography (CoUI `Text` takes its
    // colour and size from the ancestor), as the Flutter twin's
    // `DefaultTextStyle.merge`.
    donutCenter: WebElementChrome(
      className: join([
        WebLayout.absolute,
        WebLayout.insetZero,
        WebLayout.flex,
        WebLayout.itemsCenter,
        WebLayout.justifyCenter,
        valueType.className,
      ]),
      inlineStyles: inline(valueType.inline),
    ),
    legend: WebElementChrome(
      className: join([WebLayout.flex, WebLayout.flexCol, WebLayout.minWZero]),
      inlineStyles: Styles(
        raw: {
          'gap': spaceCss(rowSpacing),
          // Basis of one donut width: the legend wraps below once it
          // would get less room than the donut itself.
          'flex': '1 1 ${rem(donutSize)}',
        },
      ),
    ),
    legendRow: WebElementChrome(
      className: join([WebLayout.flex, WebLayout.itemsCenter]),
      inlineStyles: Styles(raw: {'gap': spaceCss(labelSpacing)}),
    ),
    swatches: swatches,
    legendTexts: WebElementChrome(
      className: join([
        textsChrome.className,
        WebLayout.flex1,
        WebLayout.minWZero,
      ]),
      inlineStyles: textsChrome.inlineStyles,
    ),
    series: ResolvedCategoryBreakdownSeries(
      isEmpty: geometry.isEmpty,
      valueLabels: valueLabels,
      percentLabels: percentLabels,
      rowLabels: [
        for (var i = 0; i < items.length; i++)
          [items[i].label, valueLabels[i], percentLabels[i]].join(', '),
      ],
      ringRadius: unit(ringRadius),
    ),
  );
}
