import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/theme_context.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ─── File-local renderer constants (not design tokens) ────────────
// Web-specific implementation details that don't correspond to user
// override fields and aren't shared with Flutter as design tokens —
// they're derived math from the indeterminate fill ratio.

/// Percent per unit ratio — the CSS percentages are written as `ratio × 100`.
const double _kPercent = 100;

/// Marker className applied to the indicator `<div>` so the scoped
/// `<style>` block can target it via `#$scopeId .co-progress-indeterminate`.
const String _kIndeterminateMarker = 'co-progress-indeterminate';

// ═══════════════════════════════════════════════════
// Resolved output — linear progress
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Progress`.
///
/// DOM shape — the bar alone (no label cell):
///
/// ```text
/// root (<div>, role=progressbar)            // track — relative, overflow-hidden
///   ├─ <style>                              // co_progress emits only when isIndeterminate
///   └─ indicator (<div>)                    // moving fill / determinate width
/// ```
///
/// With a label cell (`labelled`), the root is the column the cells stack
/// in and the track moves inside it:
///
/// ```text
/// root (<div>, role=progressbar)            // flex column, full width
///   ├─ <style>                              // only when isIndeterminate
///   ├─ labelRow (<div>)                     // only with label / valueLabel
///   │    ├─ label (<div>)                   // flex-1 — empty when no label
///   │    └─ valueLabel (<div>)              // only with a valueLabel
///   ├─ Gap ← labelGapStyle                  // only with the label row
///   ├─ track (<div>)
///   │    └─ indicator (<div>)
///   ├─ Gap ← captionGapStyle                // only with a caption
///   └─ caption (<div>)                      // only with a caption
/// ```
///
/// A segmented bar (`segments` with a value — `segmented`) puts a row of
/// cells where the track would be — the root itself without a label cell:
///
/// ```text
/// segmentRow (<div>)                        // flex row, full width, gap
///   └─ filledSegment / emptySegment (<div>) × segments
/// ```
///
/// All slot chromes are non-null — `co_progress` reads
/// `resolved.<slot>.className` / `resolved.<slot>.inlineStyles`
/// straight off. Runtime state (`isIndeterminate` / `widthPercent` /
/// `animated` / `labelled`) is consumed by [resolveProgress] as
/// arguments; the resolver bakes them into the chrome bundles.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * nested `CoreGapStyle` slots forwarded raw to `Gap`.
///
/// The indeterminate `@keyframes` + selector `<style>` block is NOT
/// carried here — webkit/`@keyframes` CSS can't be expressed as a
/// className/inlineStyles bundle, so `co_progress` composes it (only
/// when `isIndeterminate`) via the separate top-level
/// [resolveProgressIndeterminateCss] resolver, which re-walks the same
/// merge chain for the slide cycle duration and folds in the runtime
/// scope id (Cat C scoped-CSS, number_ticker separate-resolver pattern).
class ResolvedProgress implements WebResolvedChrome {
  /// Creates a [ResolvedProgress].
  const ResolvedProgress({
    required this.root,
    required this.track,
    required this.indicator,
    required this.labelRow,
    required this.label,
    required this.valueLabel,
    required this.valueLabelReserve,
    required this.valueLabelValue,
    required this.caption,
    required this.labelGapStyle,
    required this.captionGapStyle,
    required this.segmentRow,
    required this.filledSegment,
    required this.emptySegment,
  });

  /// Paint-ready chrome for the outermost `<div>` — the [track] chrome
  /// itself when the bar has no label cell (the [segmentRow] chrome when
  /// the bar is segmented), the full-width flex column the cells stack in
  /// when it has.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the track `<div>` — `relative w-full
  /// overflow-hidden` plus the optional background Tailwind class.
  /// Inline CSS carries `height` + runtime `border-radius` + optional
  /// background override.
  final WebElementChrome track;

  /// Paint-ready chrome for the indicator `<div>` — `block h-full` +
  /// background class (when no inline override) + optional
  /// `co-progress-indeterminate` marker. Inline CSS carries height /
  /// width (percent or 0) / border-radius / transition / optional
  /// background override.
  final WebElementChrome indicator;

  /// Paint-ready chrome for the row holding `label` and `valueLabel`.
  final WebElementChrome labelRow;

  /// Paint-ready chrome for the `label` cell — it takes the row's free
  /// width, so a lone `valueLabel` still sits at the end. Typography from
  /// `CoreProgressStyle.defaultLabelStyle` (the role class alone).
  final WebElementChrome label;

  /// Paint-ready chrome for the `valueLabel` cell — a one-cell grid whose
  /// tabular numerals keep a changing value from jittering, and whose width
  /// is the widest value ([CoreProgressContract.defaultValueLabelReserve]).
  final WebElementChrome valueLabel;

  /// Paint-ready chrome for the hidden reserve text that sizes the
  /// `valueLabel` cell — stacked in the grid cell under the value.
  final WebElementChrome valueLabelReserve;

  /// Paint-ready chrome for the value itself — stacked in the grid cell and
  /// aligned to the end.
  final WebElementChrome valueLabelValue;

  /// Paint-ready chrome for the `caption` cell.
  final WebElementChrome caption;

  /// Nested [CoreGapStyle] for the label row → bar spacer — forwarded raw
  /// to `Gap`.
  final CoreGapStyle labelGapStyle;

  /// Nested [CoreGapStyle] for the bar → caption spacer — forwarded raw to
  /// `Gap`.
  final CoreGapStyle captionGapStyle;

  /// Paint-ready chrome for the row of cells of a segmented bar — full
  /// width, the track's height, `column-gap` from
  /// `CoreProgressStyle.segmentSpacing`.
  final WebElementChrome segmentRow;

  /// Paint-ready chrome for a cell of a step passed — an equal share of the
  /// row in the fill colour, the track's corner.
  final WebElementChrome filledSegment;

  /// Paint-ready chrome for a cell of a step still to come — the same cell
  /// in the track colour.
  final WebElementChrome emptySegment;
}

// ═══════════════════════════════════════════════════
// resolveProgress — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedProgress] for the given [context].
///
/// Single entry point — `co_progress.dart` must not call
/// `context.theme.coreComponentTheme.progress` directly nor invoke
/// `CoreProgressStyle.merge(...)` outside this function. All fallback
/// chains terminate at `coui_core`'s [CoreProgressStyle] static const
/// defaults.
///
/// [isIndeterminate] / [widthPercent] / [animated] / [labelled] /
/// [segmented] are the per-build runtime inputs — the resolver bakes them
/// into the chrome bundles (className + inline CSS). [labelled] says the
/// bar has at least one label cell, which moves the [ResolvedProgress.root]
/// from the track to the column around it. [segmented] says the bar draws
/// a row of cells instead of the track — without a label cell that row is
/// the root. The indeterminate `<style>` block is composed
/// separately by `co_progress` via [resolveProgressIndeterminateCss] when
/// [isIndeterminate] is `true`.
///
/// [size] and [tone] are semantic identifiers (widget-only props — the
/// theme cannot override them, mirroring `resolveFab`'s `size`). [size]
/// selects the per-size track thickness from
/// [CoreProgressStyle.defaultsBySize]; [tone] selects the fill from
/// [CoreProgressStyle.defaultsByTone] and the project's
/// [CoreProgressTheme.toneStyles] row.
ResolvedProgress resolveProgress({
  required BuildContext context,
  required CoreProgressSize size,
  required bool isIndeterminate,
  required double widthPercent,
  required bool animated,
  CoreProgressTone tone = CoreProgressTone.defaultTone,
  bool labelled = false,
  bool segmented = false,
  CoreProgressStyle? progressStyle,
}) {
  final merged = _mergeProgressStyle(
    context,
    tone: tone,
    progressStyle: progressStyle,
  );

  // ── Indicator colour ──
  // EMIT Stage 2 (Web, theme-free) — every colour routes through the
  // emit family. A token-bound colour (default OR token override) emits
  // a `bg-{token}` Tailwind class so it stays dark-mode reactive; a raw
  // override goes inline. No `scheme.resolve` (a no-op on Web) and no
  // hand-rolled `if (override != null)` branches. Without a stated colour
  // the fill is the tone's — every tone row states it.
  final toneStyle = CoreProgressStyle.defaultsByTone[tone]!;
  final indicatorEmit = emitColor(
    merged.color,
    toneStyle.color!,
    .background,
  );

  // ── Track colour ──
  // Without an explicit `backgroundColor` override the track is the neutral
  // [CoreProgressStyle.defaultBackgroundColor]; a stated `backgroundAlpha`
  // derives it from the indicator colour instead — the Flutter twin's
  // `scaleAlpha` on the same colour. A token stays a token (`primary` →
  // `primary/20`, a class); a raw colour stays raw and goes inline, so a raw
  // fill gets a track of its own hue, not the default's.
  final trackBgAlpha = merged.backgroundAlpha;
  final trackBasis = trackBgAlpha == null
      ? CoreProgressStyle.defaultBackgroundColor
      : (merged.color ?? toneStyle.color!).scaleAlpha(trackBgAlpha);
  final trackEmit = emitColor(
    merged.backgroundColor,
    trackBasis,
    .background,
  );

  // ── Border radius ──
  final radius = merged.borderRadius ?? CoreProgressStyle.defaultBorderRadius;
  final borderRadius = radius.toValue();

  // ── Min height ──
  // Semantic `size` is a widget-only prop (the theme cannot override it).
  // Resolve straight to the per-size default style (minHeight). Web
  // stores logical px (no `* scaling` — CSS `rem` tracks the
  // accessibility text scale), unlike Flutter.
  final sizeStyle = CoreProgressStyle.defaultsBySize[size]!;
  final minHeight = merged.minHeight ?? sizeStyle.minHeight!;
  final minHeightRem = '${minHeight / kRemDivisor}rem';

  // ── Animation timings ──
  // Determinate transition (consumed by indicator inline CSS). The
  // indeterminate slide cycle is resolved separately by
  // [resolveProgressIndeterminateCss] (same merge chain).
  final duration = merged.duration ?? CoreProgressStyle.defaultDuration;
  final determinateTransitionMs = duration.inMilliseconds;
  // The Flutter twin's determinate fill and segment cells both ease on
  // `CoreEasing.move`; the indeterminate slide below reads the same alias.
  final determinateEasing = CoreEasing.move.toVarCss();

  // ── Segment gap ──
  // Spacing — a theme density moves it through the `--coui-space-*`
  // variable, as the Flutter twin's `geometry.space` does.
  final segmentSpacing =
      merged.segmentSpacing ?? CoreProgressStyle.defaultSegmentSpacing;

  // ── Label cells ──
  // Each cell's role rides its `text-{role}` class; the valueLabel's regular
  // weight is an overlay on the role and goes inline beside it.
  final labelEmit = emitTypography(
    merged.labelStyle,
    CoreProgressStyle.defaultLabelStyle,
  );
  final valueLabelEmit = emitTypography(
    merged.valueLabelStyle,
    CoreProgressStyle.defaultValueLabelStyle,
  );
  final captionEmit = emitTypography(
    merged.captionStyle,
    CoreProgressStyle.defaultCaptionStyle,
  );

  // Nested CoreGapStyle slots — forwarded raw to `Gap`.
  final labelGapStyle = CoreProgressStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );
  final captionGapStyle = CoreProgressStyle.defaultCaptionGapStyle.merge(
    merged.captionGapStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the track `<div>` Tailwind className — layout primitives
  /// plus the [trackEmit] background class. The class is present only
  /// when the colour went the token path (`trackEmit.inline == null`);
  /// a raw override leaves the class empty and the inline CSS carries the
  /// colour. Layout primitives (`position` / `width` / `overflow`) flow
  /// through the className so no duplication.
  String buildTrackClassName() {
    final classList = [
      WebLayout.relative,
      WebLayout.wFull,
      WebLayout.overflowHidden,
    ];
    if (trackEmit.className.isNotEmpty) classList.add(trackEmit.className);
    // Deliberately NOT taking the contributed boundary. The track
    // renders 8px tall, so a 4px boundary on top and bottom is the whole
    // height and the fill has nowhere left to paint — the bar comes out
    // a solid outline with no progress in it. The reference draws this
    // bar at 16px, where the same boundary leaves room; matching it is a
    // change to the component's authored height, not to this axis.
    return classList.join(' ');
  }

  /// Composes the track `<div>` inline CSS — runtime `height` /
  /// `border-radius` plus the [trackEmit] background fragment (raw
  /// override only — token colours stay on the class above). Layout
  /// primitives flow through the className so no duplication here.
  Styles buildTrackInlineStyles() {
    final raw = {
      'height': minHeightRem,
      'border-radius': borderRadius,
      ...?trackEmit.inline,
    };
    return Styles(raw: raw);
  }

  /// Composes the indicator `<div>` Tailwind className — `block h-full`
  /// plus the [indicatorEmit] background class (token path only) plus the
  /// `co-progress-indeterminate` marker (only when indeterminate).
  String buildIndicatorClassName() {
    final classList = [WebLayout.block, WebLayout.hFull];
    if (indicatorEmit.className.isNotEmpty) {
      classList.add(indicatorEmit.className);
    }
    if (isIndeterminate) classList.add(_kIndeterminateMarker);
    return classList.join(' ');
  }

  /// Composes the indicator `<div>` inline CSS — `height` / runtime
  /// `width` / `border-radius` / `transition` (animated only) + the
  /// [indicatorEmit] background fragment (raw override only).
  Styles buildIndicatorInlineStyles() {
    final raw = {
      'height': '100%',
      // Indeterminate fill width comes from the scoped
      // `.co-progress-indeterminate { width: 60% }` rule — emitting an
      // inline `width: 0%` here would win over the stylesheet rule
      // (inline specificity) and collapse the sliding fill to zero
      // width, so the moving bar renders invisibly.
      if (!isIndeterminate) 'width': '$widthPercent%',
      'border-radius': borderRadius,
      'transition': animated
          ? 'width ${durationMsCss(determinateTransitionMs)} '
                '$determinateEasing'
          : 'none',
      ...?indicatorEmit.inline,
    };
    return Styles(raw: raw);
  }

  /// Composes a label cell's inline CSS — the [Emit]'s overlay fragment,
  /// or nothing when the role class carries the whole style.
  Styles? buildCellInlineStyles(Emit emitted) {
    final inline = emitted.inline;
    return inline == null ? null : Styles(raw: inline);
  }

  /// Composes the label cell `<div>` className — it takes the free width
  /// of the label row and wraps long words, plus the [labelEmit] role
  /// class.
  String buildLabelClassName() {
    return [
      WebLayout.flex1,
      WebLayout.minWZero,
      WebLayout.breakWords,
      labelEmit.className,
    ].join(' ');
  }

  /// Composes the value-label cell `<div>` className — it never shrinks
  /// out of the row, plus the [valueLabelEmit] role class.
  String buildValueLabelClassName() {
    return '${WebLayout.shrinkZero} ${valueLabelEmit.className}';
  }

  /// Composes the caption cell `<div>` className — wraps long words, plus
  /// the [captionEmit] role class.
  String buildCaptionClassName() {
    return '${WebLayout.breakWords} ${captionEmit.className}';
  }

  /// Composes the segment row `<div>` inline CSS — the track's `height`
  /// and the gap between cells.
  Styles buildSegmentRowInlineStyles() {
    return Styles(
      raw: {
        'height': minHeightRem,
        'column-gap': spaceCss(segmentSpacing),
      },
    );
  }

  /// Composes a segment cell `<div>` className — an equal share of the row
  /// (the Flutter twin's `Expanded`), full height, plus [emitted]'s
  /// background class (token path only).
  String buildSegmentClassName(Emit emitted) {
    return [
      WebLayout.flex1,
      WebLayout.minWZero,
      WebLayout.hFull,
      if (emitted.className.isNotEmpty) emitted.className,
    ].join(' ');
  }

  /// Composes a segment cell `<div>` inline CSS — the track's corner, the
  /// colour change between the two cell states (animated only), plus
  /// [emitted]'s background fragment (raw override only).
  Styles buildSegmentInlineStyles(Emit emitted) {
    return Styles(
      raw: {
        'border-radius': borderRadius,
        'transition': animated
            ? 'background-color ${durationMsCss(determinateTransitionMs)} '
                  '$determinateEasing'
            : 'none',
        ...?emitted.inline,
      },
    );
  }

  final trackChrome = WebElementChrome(
    className: buildTrackClassName(),
    inlineStyles: buildTrackInlineStyles(),
  );

  final segmentRowChrome = WebElementChrome(
    className: '${WebLayout.flex} ${WebLayout.wFull}',
    inlineStyles: buildSegmentRowInlineStyles(),
  );

  // Without label cells the bar is the root (the DOM is exactly the bare
  // bar — the track, or the row of cells of a segmented bar); with them the
  // root becomes the column that stacks the label row, the bar and the
  // caption.
  final rootChrome = labelled
      ? const WebElementChrome(className: WebLayout.flexColFull)
      : segmented
      ? segmentRowChrome
      : trackChrome;

  const labelRowChrome = WebElementChrome(
    className: WebLayout.flexItemsCenterFull,
  );

  final labelChrome = WebElementChrome(
    className: buildLabelClassName(),
    inlineStyles: buildCellInlineStyles(labelEmit),
  );

  final valueLabelChrome = WebElementChrome(
    className: buildValueLabelClassName(),
    inlineStyles: Styles(
      raw: {
        'display': 'grid',
        'font-variant-numeric': 'tabular-nums',
        ...?valueLabelEmit.inline,
      },
    ),
  );

  // The two stacked cells of the value label — the hidden reserve sizes the
  // grid, the value sits at its end.
  const valueLabelReserveChrome = WebElementChrome(
    className: '',
    inlineStyles: Styles(
      raw: {
        'grid-area': '1 / 1',
        'visibility': 'hidden',
        'justify-self': 'end',
      },
    ),
  );
  const valueLabelValueChrome = WebElementChrome(
    className: '',
    inlineStyles: Styles(raw: {'grid-area': '1 / 1', 'justify-self': 'end'}),
  );

  final captionChrome = WebElementChrome(
    className: buildCaptionClassName(),
    inlineStyles: buildCellInlineStyles(captionEmit),
  );

  final indicatorChrome = WebElementChrome(
    className: buildIndicatorClassName(),
    inlineStyles: buildIndicatorInlineStyles(),
  );

  final filledSegmentChrome = WebElementChrome(
    className: buildSegmentClassName(indicatorEmit),
    inlineStyles: buildSegmentInlineStyles(indicatorEmit),
  );

  final emptySegmentChrome = WebElementChrome(
    className: buildSegmentClassName(trackEmit),
    inlineStyles: buildSegmentInlineStyles(trackEmit),
  );

  return ResolvedProgress(
    root: rootChrome,
    track: trackChrome,
    indicator: indicatorChrome,
    labelRow: labelRowChrome,
    label: labelChrome,
    valueLabel: valueLabelChrome,
    valueLabelReserve: valueLabelReserveChrome,
    valueLabelValue: valueLabelValueChrome,
    caption: captionChrome,
    labelGapStyle: labelGapStyle,
    captionGapStyle: captionGapStyle,
    segmentRow: segmentRowChrome,
    filledSegment: filledSegmentChrome,
    emptySegment: emptySegmentChrome,
  );
}

/// Merges the linear progress style chain shared by [resolveProgress] and
/// [resolveProgressIndeterminateCss] — project style → project tone row →
/// instance — so the chrome and the scoped rule read the same values.
CoreProgressStyle _mergeProgressStyle(
  BuildContext context, {
  required CoreProgressTone tone,
  CoreProgressStyle? progressStyle,
}) {
  final compTheme = context.theme.coreComponentTheme?.progress;
  return resolveStyleChain(const CoreProgressStyle(), [
    compTheme?.style,
    compTheme?.toneStyles?[tone],
    progressStyle,
  ]);
}

// ═══════════════════════════════════════════════════
// Scoped-CSS resolver (Category C)
// ═══════════════════════════════════════════════════

/// Composes the indeterminate `<style>` block contents for `Progress`
/// scoped to the supplied [scopeId].
///
/// Emits the `@keyframes` slide-from-left-to-right rule plus the
/// selector binding the animation to the indicator marker class
/// (`co-progress-indeterminate`). A 60 %-wide fill slides from
/// `-100 %` (offscreen left) to `166.67 %` (offscreen right) over the
/// resolved slide-cycle duration with `ease-in-out`. Mirrors Flutter
/// `_IndeterminateBar` motion 1:1.
///
/// Walks the same merge chain as [resolveProgress]
/// (design-system default → `CoreProgressTheme.style` →
/// `CoreProgressTheme.toneStyles[tone]` → `widget.progressStyle`) for the
/// slide-cycle duration. Kept as a separate `resolveCo*` entry point — the
/// `@keyframes` + selector CSS can't be expressed as a
/// className/inlineStyles bundle, so it lives outside [ResolvedProgress]
/// which stays pure paint-ready chrome (number_ticker separate-resolver
/// pattern).
String resolveProgressIndeterminateCss(
  BuildContext context, {
  required String scopeId,
  CoreProgressTone tone = CoreProgressTone.defaultTone,
  CoreProgressStyle? progressStyle,
}) {
  final merged = _mergeProgressStyle(
    context,
    tone: tone,
    progressStyle: progressStyle,
  );
  final indeterminateDuration =
      merged.indeterminateDuration ??
      CoreProgressStyle.defaultIndeterminateDuration;
  final cycleMs = indeterminateDuration.inMilliseconds;
  // The fill is a share of the track; the slide runs from just off the left
  // edge to just off the right one, so it travels `100 / ratio` % of its own
  // width (the Flutter twin slides `-fillWidth → trackWidth`).
  final fillRatio =
      merged.indeterminateFillRatio ??
      CoreProgressStyle.defaultIndeterminateFillRatio;
  final fillPercent = fillRatio * _kPercent;
  final translateEndPercent = _kPercent / fillRatio;

  return '@keyframes $scopeId-progress { '
      '0% { transform: translateX(-100%); } '
      '100% { transform: translateX('
      '${translateEndPercent.toStringAsFixed(2)}%); } '
      '} '
      '#$scopeId .$_kIndeterminateMarker { '
      'width: ${fillPercent.toStringAsFixed(2)}%; '
      'animation: $scopeId-progress '
      '${durationMsCss(cycleMs)} ${CoreEasing.move.toVarCss()} infinite; '
      '}';
}

// ═══════════════════════════════════════════════════
// Resolved output — radial progress
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `RadialProgress`.
///
/// DOM shape:
///
/// ```text
/// root (<div>, role=progressbar)            // wrapper — inline runtime rem size
///   ├─ <svg>                                // viewBox of sizePx
///   │    ├─ <circle> trackCircle            // stroke = trackCircle.className (token) or trackInlineColor
///   │    └─ <circle> arcCircle              // stroke = arcCircle.className (token) or arcInlineColor
///   └─ label (<span>)                       // co_progress renders only when showValueText && child == null
/// ```
///
/// All slot chromes are non-null — `co_progress` reads
/// `resolved.<slot>.className` / `resolved.<slot>.inlineStyles`
/// straight off.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
///
/// The SVG `<circle>` geometry + `stroke` values (`sizePx` /
/// `strokeWidthPx` / `arcInlineColor` / `trackInlineColor`) are NOT
/// carried here — they live on the `<circle>` / `<svg>` XML attributes
/// (not className/inlineStyles), and the widget needs the raw doubles to
/// compute the dash geometry. They are resolved separately via
/// [resolveRadialProgressGeometry] (number_ticker separate-resolver
/// pattern), keeping this struct pure paint-ready chrome.
class ResolvedRadialProgress implements WebResolvedChrome {
  /// Creates a [ResolvedRadialProgress].
  const ResolvedRadialProgress({
    required this.root,
    required this.label,
    required this.trackCircle,
    required this.arcCircle,
  });

  /// Paint-ready chrome for the outer wrapper `<div>` — no Tailwind
  /// class; inline CSS carries runtime rem dimensions plus the
  /// `position: relative; display: inline-block` layout used to
  /// absolute-center the label over the SVG.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the center label `<span>` — typography
  /// className plus absolute-center inline CSS. The widget renders
  /// the slot only when no `child` is supplied and `showValueText`
  /// is true. `null` for a size that draws no value text (`sm`) unless
  /// a `valueTextStyle` is stated.
  final WebElementChrome? label;

  /// Paint-ready chrome for the SVG track `<circle>` — the optional
  /// `stroke-${token}` Tailwind class. Empty when the geometry record's
  /// `trackInlineColor` carries the override instead.
  final WebElementChrome trackCircle;

  /// Paint-ready chrome for the SVG arc `<circle>` — the optional
  /// `stroke-${token}` Tailwind class. Empty when the geometry record's
  /// `arcInlineColor` carries the override instead.
  final WebElementChrome arcCircle;
}

// ═══════════════════════════════════════════════════
// resolveRadialProgress — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedRadialProgress] for the given [context].
ResolvedRadialProgress resolveRadialProgress({
  required BuildContext context,
  CoreProgressSize size = CoreRadialProgressContract.defaultSize,
  CoreProgressTone tone = CoreRadialProgressContract.defaultTone,
  CoreRadialProgressStyle? radialProgressStyle,
}) {
  final compTheme = context.theme.coreComponentTheme?.radialProgress;
  final merged = resolveStyleChain(const CoreRadialProgressStyle(), [
    compTheme?.style,
    radialProgressStyle,
  ]);

  // ── Arc colour ──
  // The SVG `<circle>` stroke uses a `stroke-{token}` Tailwind class for a
  // token-bound colour (default OR token override). A raw override has no
  // class — [resolveRadialProgressGeometry] supplies it inline on the
  // `<circle>` `stroke` XML attribute. No `scheme.resolve` (a no-op on
  // Web): the class-vs-inline split keys off the colour's `.token` identity.
  final ringSize =
      CoreRadialProgressStyle.defaultsBySize[CoreRadialProgressStyle.sizeOf(
        size,
      )]!;
  final toneColor = CoreRadialProgressStyle.defaultsByTone[tone]!.color!;
  final arcColorValue = merged.color ?? toneColor;
  final arcColorClass = arcColorValue.token != null
      ? 'stroke-${arcColorValue.tailwindColor}'
      : '';

  // ── Track colour ──
  // A token-bound track ring emits a `stroke-{token}` class; a raw one has
  // no class — [resolveRadialProgressGeometry] supplies it inline. Both
  // read the one colour [_radialTrackColor] derives.
  final trackColorValue = _radialTrackColor(merged, toneColor);
  final trackColorClass = trackColorValue.token != null
      ? 'stroke-${trackColorValue.tailwindColor}'
      : '';

  // ── Geometry ──
  // Only `size` feeds chrome here (root wrapper rem dimensions); the
  // SVG `<circle>` `stroke-width` + dash geometry is resolved separately
  // by [resolveRadialProgressGeometry].
  final diameter = merged.size ?? ringSize.size!;

  // ── Centre value-text typography ──
  // EMIT Stage 2 (Web, theme-free) — `emitTypography` merges the
  // single-source role default (`bodyLarge` + semi-bold + `on-surface`)
  // with any per-instance overlay, emitting a `text-{role}` (+ token
  // colour) class with explicit scalar overlays inline.
  // A size with no value-text default (`sm`) draws none unless one is stated.
  final valueDefault = ringSize.valueTextStyle;
  final valueEmit = valueDefault == null && merged.valueTextStyle == null
      ? null
      : emitTypography(
          merged.valueTextStyle,
          valueDefault ?? const CoreTextStyle(),
        );

  // ─── Local builders ───────────────────────────────────

  /// Composes the wrapper `<div>` inline CSS — `position` + `display`
  /// + runtime rem `width` / `height` so the SVG sizing scales with
  /// the user's root font-size.
  Styles buildRootInlineStyles() => .new(
    raw: {
      'position': 'relative',
      'display': 'inline-block',
      'width': '${diameter / kRemDivisor}rem',
      'height': '${diameter / kRemDivisor}rem',
    },
  );

  /// Composes the label `<span>` Tailwind className — the [valueEmit]
  /// typography class (role + token colour). Explicit scalar overlays
  /// (e.g. `fontWeight`) flow through the inline CSS below.
  String buildLabelClassName() => valueEmit?.className ?? '';

  /// Composes the label `<span>` inline CSS — absolute-center over the
  /// SVG plus the [valueEmit] typography fragment (explicit scalar
  /// overlays / raw colour only — the role + token colour stay on the
  /// class above).
  Styles buildLabelInlineStyles() => .new(
    raw: {
      'position': 'absolute',
      'inset': '0',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      ...?valueEmit?.inline,
    },
  );

  /// Composes the SVG track `<circle>` Tailwind className —
  /// `stroke-${token}` colour-token class. Empty only when a non-token
  /// override flows through the inline-colour escape hatch on the
  /// `<circle>` `stroke` attribute ([resolveRadialProgressGeometry]).
  String buildTrackCircleClassName() => trackColorClass;

  /// Composes the SVG arc `<circle>` Tailwind className —
  /// `stroke-${token}` colour-token class. Empty only when a non-token
  /// override flows through the inline-colour escape hatch on the
  /// `<circle>` `stroke` attribute ([resolveRadialProgressGeometry]).
  String buildArcCircleClassName() => arcColorClass;

  return ResolvedRadialProgress(
    root: WebElementChrome(
      className: '',
      inlineStyles: buildRootInlineStyles(),
    ),
    label: valueEmit == null
        ? null
        : WebElementChrome(
            className: buildLabelClassName(),
            inlineStyles: buildLabelInlineStyles(),
          ),
    trackCircle: WebElementChrome(className: buildTrackCircleClassName()),
    arcCircle: WebElementChrome(className: buildArcCircleClassName()),
  );
}

/// Resolves the SVG geometry + non-token `stroke` colours for
/// `RadialProgress` — the raw doubles `co_progress` needs to compute
/// the `<circle>` dash geometry plus the inline-colour escape-hatch
/// values that flow through the `stroke` XML attribute.
///
/// Walks the same merge chain as [resolveRadialProgress]
/// (design-system default → `CoreRadialProgressTheme.style` →
/// `widget.radialProgressStyle`). Kept as a separate `resolveCo*` entry
/// point — the `<circle>` geometry (`cx` / `cy` / `r` / `stroke-width`)
/// and the arbitrary `stroke` colour live as XML attributes, not as a
/// className/inlineStyles bundle, so they stay off [ResolvedRadialProgress]
/// (number_ticker separate-resolver pattern).
///
/// `arcInlineColor` / `trackInlineColor` are `null` when the colour fell
/// through the Tailwind token path — then the matching `<circle>`'s
/// `stroke-${token}` className (from [ResolvedRadialProgress.arcCircle]
/// / `.trackCircle`) carries the colour instead.
///
/// `strokeWidthCssValue` and `strokeWidthPx` are deliberately two
/// separate values rather than one. Flutter floors this same field via
/// `theme.geometry.stroke` (a neo-brutalism-style `strokeFloor` preset
/// thickens it), so the *painted* stroke must ride
/// `strokeWidthCss(strokeWidth)` (→ `var(--coui-stroke-width-N)`) to stay
/// reactive — that is `strokeWidthCssValue`, consumed as a CSS `style`
/// property on the `<circle>`, not an XML attribute (XML attribute
/// values cannot reference a CSS custom property at all). But `radius`
/// / `circumference` / `stroke-dashoffset` are plain SVG numeric
/// attributes with no CSS equivalent for `co_progress` to compute them
/// from, and Web has no rebuild hook when a surface style is switched
/// (§ Web 는 CSS 변수로만 재지정한다 — the geometry is settled once, in
/// Dart, at resolve/SSR time). So the circle's radius keeps assuming the
/// *unfloored* `strokeWidthPx` — under a preset whose floor actually
/// raises this component's configured width, the ring paints thicker
/// (correctly reactive) but its outer edge can extend a few px past the
/// radius the geometry assumed, clipped by the SVG viewBox rather than
/// perfectly inscribed. That is a strictly smaller defect than not
/// reaching the floor at all, and matches the one CSS property this
/// value has a variable for.
({
  double sizePx,
  double strokeWidthPx,
  String strokeWidthCssValue,
  String? arcInlineColor,
  String? trackInlineColor,
})
resolveRadialProgressGeometry(
  BuildContext context, {
  CoreProgressSize size = CoreRadialProgressContract.defaultSize,
  CoreProgressTone tone = CoreRadialProgressContract.defaultTone,
  CoreRadialProgressStyle? radialProgressStyle,
}) {
  final compTheme = context.theme.coreComponentTheme?.radialProgress;
  final merged = resolveStyleChain(const CoreRadialProgressStyle(), [
    compTheme?.style,
    radialProgressStyle,
  ]);

  // ── Arc colour ── (inline value only on a non-token override) ──
  // Web emits the raw CSS via `.toValue()` (token → `var(--coui-X)`, raw
  // → rgba) — `scheme.resolve` is a no-op on Web. A token-bound colour
  // carries no inline value here; its `stroke-{token}` class is composed
  // by [resolveRadialProgress].
  final ringSize =
      CoreRadialProgressStyle.defaultsBySize[CoreRadialProgressStyle.sizeOf(
        size,
      )]!;
  final toneColor = CoreRadialProgressStyle.defaultsByTone[tone]!.color!;
  final arcColor = merged.color;
  final String? arcInlineColor;
  if (arcColor == null || arcColor.token != null) {
    arcInlineColor = null;
  } else {
    arcInlineColor = arcColor.toValue();
  }

  // ── Track colour ── (inline value only when it is not a token) ──
  // The same colour [resolveRadialProgress] classes — an explicit override
  // or the arc's own fade, which is raw whenever the arc is raw.
  final trackColor = _radialTrackColor(merged, toneColor);
  final trackInlineColor = trackColor.token != null
      ? null
      : trackColor.toValue();

  // ── Geometry ──
  final diameter = merged.size ?? ringSize.size!;
  final strokeWidth = merged.strokeWidth ?? ringSize.strokeWidth!;

  return (
    sizePx: diameter,
    strokeWidthPx: strokeWidth,
    strokeWidthCssValue: strokeWidthCss(strokeWidth),
    arcInlineColor: arcInlineColor,
    trackInlineColor: trackInlineColor,
  );
}

/// The track ring colour both radial resolvers read: the explicit
/// `backgroundColor`, else — when `backgroundAlpha` is stated — the arc
/// colour with its alpha scaled by it (the Flutter twin's `scaleAlpha` on
/// the same colour; a token arc fades to a token, a raw arc to a raw colour
/// of its own hue), else the neutral
/// [CoreRadialProgressStyle.defaultBackgroundColor].
CoreColor _radialTrackColor(
  CoreRadialProgressStyle merged,
  CoreColor toneColor,
) {
  final alpha = merged.backgroundAlpha;
  return merged.backgroundColor ??
      (alpha == null
          ? CoreRadialProgressStyle.defaultBackgroundColor
          : (merged.color ?? toneColor).scaleAlpha(alpha));
}
