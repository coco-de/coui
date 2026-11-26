import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Steps`.
///
/// DOM shape (vertical):
///
/// ```text
/// root (<div>)                              // steps container (flex flex-col)
///   └─ stepWrappers[i] (<div>)              // per-step vertical row
///        ├─ indicatorColumns[i] (<div>)     // indicator + connector column (vertical only)
///        │    ├─ indicators[i] (<div>)
///        │    │    └─ Icon(iconStyle | failedIconStyle)
///        │    │       | indicatorNumbers[i] (<span>)
///        │    ├─ Gap(indicatorConnectorGapStyle) // emitted for i < stepCount - 1
///        │    ├─ connectors[i] (<div>)      // emitted for i < stepCount - 1
///        │    └─ Gap(indicatorConnectorGapStyle) // emitted for i < stepCount - 1
///        ├─ Gap(indicatorContentGapStyle) // indicator ↔ content
///        └─ contentColumns[i] (<div>)
///             ├─ titles[i] (<div>)
///             └─ descriptions[i] (<div>)    // optional, widget elects
/// ```
///
/// DOM shape (horizontal):
///
/// ```text
/// root (<div>)                              // steps container (flex flex-row)
///   └─ stepWrappers[i] (<div>)              // per-step column
///        ├─ indicatorRows[i] (<div>)        // indicator + connector row (horizontal only)
///        │    ├─ indicators[i] (<div>)
///        │    ├─ Gap(indicatorConnectorGapStyle) // emitted for i < stepCount - 1
///        │    ├─ connectors[i] (<div>)      // emitted for i < stepCount - 1
///        │    └─ Gap(indicatorConnectorGapStyle) // emitted for i < stepCount - 1
///        └─ contentColumns[i] (<div>)
///             ├─ titles[i] (<div>)
///             └─ descriptions[i] (<div>)    // optional, widget elects
/// ```
///
/// DOM shape (list):
///
/// ```text
/// root (<div role="list">)                  // steps container (flex flex-col w-full)
///   └─ StepItem (stepItemStyle)             // one row per step — role="listitem"
/// ```
///
/// All slot chromes are non-null. `Steps` reads each entry's
/// `className` + `inlineStyles` straight off — no per-step merging or
/// fallback in the widget body. Per-step state (the step's
/// [CoreStepStatus], last) is closed over by [resolveSteps] via the
/// `statuses` argument and baked into each indexed entry. The list
/// variant draws none of the per-step entries — they are empty.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome), one per
///   DOM element (lists for the per-step / per-connector elements).
/// * Cat 2 — the nested [CoreIconStyle] slot ([iconStyle]) passed to
///   the completed-step check `Icon(iconStyle: …)`. Carries the
///   resolved glyph size (`indicatorSize × iconSizeRatio`) and the
///   active-step (`onPrimary`) colour; [failedIconStyle] is the same box
///   in the failed label colour, for the failed step's cross.
/// * Cat 2 — the nested [CoreStepItemStyle] slot ([stepItemStyle])
///   forwarded raw to every `StepItem` the list variant stacks.
/// * Cat 2 — the nested [CoreGapStyle] slots
///   ([indicatorContentGapStyle], [indicatorConnectorGapStyle])
///   forwarded straight to `Gap(gapStyle: …)` between the indicator
///   column and the content column, and on either side of every
///   connector inside the indicator column / row (matching the Flutter
///   widget).
class ResolvedSteps implements WebResolvedChrome {
  /// Creates a [ResolvedSteps].
  const ResolvedSteps({
    required this.root,
    required this.stepWrappers,
    required this.indicatorColumns,
    required this.indicatorRows,
    required this.indicators,
    required this.indicatorNumbers,
    required this.contentColumns,
    required this.titles,
    required this.descriptions,
    required this.connectors,
    required this.iconStyle,
    required this.failedIconStyle,
    required this.indicatorContentGapStyle,
    required this.indicatorConnectorGapStyle,
    required this.indicatorConnectorGapHorizontalStyle,
    required this.stepItemStyle,
  });

  /// Paint-ready chrome for the outer steps container `<div>` —
  /// `flex flex-col` (numbered vertical), `flex flex-row items-start
  /// w-full` (numbered horizontal) or `flex flex-col w-full` (list).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for each per-step wrapper `<div>` — one entry
  /// per step.
  final List<WebElementChrome> stepWrappers;

  /// Paint-ready chrome for the per-step indicator column `<div>`
  /// (vertical layout only) — one entry per step. Widget skips
  /// emitting in horizontal layout.
  final List<WebElementChrome> indicatorColumns;

  /// Paint-ready chrome for the per-step indicator row `<div>`
  /// (horizontal layout only) — one entry per step. Widget skips
  /// emitting in vertical layout.
  final List<WebElementChrome> indicatorRows;

  /// Paint-ready chrome for each indicator circle `<div>` — one
  /// entry per step.
  final List<WebElementChrome> indicators;

  /// Paint-ready chrome for each indicator number `<span>` (rendered
  /// only for a current or upcoming step; a done step renders a check
  /// `Icon` and a failed one a cross instead) — one entry per step.
  final List<WebElementChrome> indicatorNumbers;

  /// Paint-ready chrome for the per-step content column `<div>` —
  /// one entry per step.
  final List<WebElementChrome> contentColumns;

  /// Paint-ready chrome for each step title `<div>` — one entry per
  /// step, carrying the title typography and the colour of that step's
  /// status (an upcoming step reads quieter).
  final List<WebElementChrome> titles;

  /// Paint-ready chrome for each step description `<div>` — one
  /// entry per step; widget skips emitting when the underlying
  /// [CoreStepData] has no description.
  final List<WebElementChrome> descriptions;

  /// Paint-ready chrome for each connector `<div>` between adjacent
  /// steps — `stepCount - 1` entries; the one leaving a completed step is
  /// filled with the active connector colour.
  final List<WebElementChrome> connectors;

  /// Nested [CoreIconStyle] slot — forwarded to the completed-step
  /// check `Icon(iconStyle: …)`. Carries the resolved glyph size
  /// (`indicatorSize × iconSizeRatio`) and the active-step (`onPrimary`)
  /// colour.
  final CoreIconStyle iconStyle;

  /// Nested [CoreIconStyle] slot — forwarded to the failed-step cross
  /// `Icon(iconStyle: …)`. The same glyph size as [iconStyle], in the
  /// failed label colour (`onError`).
  final CoreIconStyle failedIconStyle;

  /// Nested [CoreGapStyle] slot — forwarded straight to
  /// `Gap(gapStyle: …)` between the indicator column / row and the
  /// content column (one `Gap` per step). Mirrors the Flutter widget;
  /// no inline padding / margin CSS leaks into the surrounding
  /// `contentColumns` chrome.
  final CoreGapStyle indicatorContentGapStyle;

  /// Nested [CoreGapStyle] slot — forwarded straight to
  /// `Gap(gapStyle: …)` on either side of every connector inside the
  /// indicator column (vertical). Two `Gap` siblings per connector,
  /// matching the Flutter widget; no inline margin / min-height CSS leaks
  /// into the connector chrome.
  final CoreGapStyle indicatorConnectorGapStyle;

  /// Nested [CoreGapStyle] slot — the same two `Gap` siblings on either
  /// side of the connector inside the indicator **row** (horizontal), which
  /// states a wider distance than the column's [indicatorConnectorGapStyle].
  final CoreGapStyle indicatorConnectorGapHorizontalStyle;

  /// Nested [CoreStepItemStyle] slot — forwarded raw to every
  /// `StepItem(stepItemStyle: …)` the list variant stacks
  /// (`CoreStepsStyle.defaultStepItemStyle` under the merged override).
  /// The row resolver fills the rest from its own defaults and status row.
  final CoreStepItemStyle stepItemStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSteps] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.steps.style
///   → theme.coreComponentTheme.steps.variantStyles[variant]
///   → widget.stepsStyle
/// ```
///
/// Closes over the per-build [statuses] (one [CoreStepStatus] per step,
/// decided by `CoreStepStatus.effective` — the same rule the Flutter
/// widget reads) and [vertical] so every per-step / per-connector chrome
/// bundle is baked into the matching list entry. The list [variant]
/// bakes none of them: its rows are `StepItem`s that resolve their own.
ResolvedSteps resolveSteps(
  BuildContext context, {
  required CoreStepsVariant variant,
  required bool vertical,
  required List<CoreStepStatus> statuses,
  CoreStepsStyle? stepsStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.steps;

  // ─── Merge chain ──────────────────────────────────────
  // `variant` comes straight from the widget — the theme only answers how
  // each variant looks (render-only.md (c)).
  final merged = resolveStyleChain(const CoreStepsStyle(), [
    coreTheme?.style,
    coreTheme?.variantStyles?[variant],
    stepsStyle,
  ]);
  final isList = variant == CoreStepsVariant.list;

  // ─── Resolved chrome values ───────────────────────────
  final indicatorSize =
      merged.indicatorSize ?? CoreStepsStyle.defaultIndicatorSize;
  final indicatorBorderRadius =
      merged.indicatorBorderRadius ??
      CoreStepsStyle.defaultIndicatorBorderRadius;
  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override. Forwarded straight to `Gap(gapStyle: …)`
  // siblings in `co_steps` (Web Flutter parity — no inline padding /
  // margin CSS leaked into the surrounding chrome). Mirrors the Flutter
  // resolver.
  final indicatorContentGapStyle = CoreStepsStyle
      .defaultIndicatorContentGapStyle
      .merge(merged.indicatorContentGapStyle);
  final indicatorConnectorGapStyle = CoreStepsStyle
      .defaultIndicatorConnectorGapStyle
      .merge(merged.indicatorConnectorGapStyle);
  final indicatorConnectorGapHorizontalStyle = CoreStepsStyle
      .defaultIndicatorConnectorGapHorizontalStyle
      .merge(merged.indicatorConnectorGapHorizontalStyle);
  final stepPadding = (merged.stepPadding ?? CoreStepsStyle.defaultStepPadding)
      .toValue();
  final stepPaddingHorizontal =
      merged.stepPaddingHorizontal ??
      CoreStepsStyle.defaultStepPaddingHorizontal;
  final connectorThickness =
      merged.connectorThickness ?? CoreStepsStyle.defaultConnectorThickness;
  final iconSizeRatio =
      merged.iconSizeRatio ?? CoreStepsStyle.defaultIconSizeRatio;
  final indicatorBorderWidth =
      merged.indicatorBorderWidth ?? CoreStepsStyle.defaultIndicatorBorderWidth;

  // ─── EMIT Stage 2 colour and typography ───────────────
  // Every colour and typography value routes through the emit family,
  // a single class-XOR-inline decision per design value. Token-bound
  // values emit Tailwind classes that stay dark-mode reactive via CSS
  // variables, while raw overrides go inline. The Web scheme resolve is a
  // no-op, so it is gone, along with the hand-rolled colour-scheme token
  // suffix interpolation that used to build the class keys.
  final activeIndicatorEmit = emitColor(
    merged.activeIndicatorColor,
    CoreStepsStyle.defaultActiveIndicatorColor,
    .background,
  );
  final inactiveIndicatorEmit = emitColor(
    merged.indicatorColor,
    CoreStepsStyle.defaultIndicatorColor,
    .background,
  );
  final failedIndicatorEmit = emitColor(
    merged.failedIndicatorColor,
    CoreStepsStyle.defaultFailedIndicatorColor,
    .background,
  );
  // Ring of an upcoming indicator — the fill is the page's own, the ring
  // is what sets it apart from a completed one.
  final indicatorBorderEmit = emitColor(
    merged.indicatorBorderColor,
    CoreStepsStyle.defaultIndicatorBorderColor,
    .border,
  );
  // Connector — a pair of values of its own: the segment leaving a
  // completed step fills in with the active colour, every other one keeps
  // the quiet one. The indicator's fill emits are not reused.
  final connectorEmit = emitColor(
    merged.connectorColor,
    CoreStepsStyle.defaultConnectorColor,
    .background,
  );
  final activeConnectorEmit = emitColor(
    merged.activeConnectorColor,
    CoreStepsStyle.defaultActiveConnectorColor,
    .background,
  );
  final activeLabelEmit = emitColor(
    merged.activeLabelColor,
    CoreStepsStyle.defaultActiveLabelColor,
    .text,
  );
  final inactiveLabelEmit = emitColor(
    merged.inactiveLabelColor,
    CoreStepsStyle.defaultInactiveLabelColor,
    .text,
  );
  final failedLabelEmit = emitColor(
    merged.failedLabelColor,
    CoreStepsStyle.defaultFailedLabelColor,
    .text,
  );
  final titleEmit = emitColor(
    merged.titleColor,
    CoreStepsStyle.defaultTitleColor,
    .text,
  );
  final inactiveTitleEmit = emitColor(
    merged.inactiveTitleColor,
    CoreStepsStyle.defaultInactiveTitleColor,
    .text,
  );
  final descriptionEmit = emitColor(
    merged.descriptionColor,
    CoreStepsStyle.defaultDescriptionColor,
    .text,
  );
  // Label / title / description typography — `emitTypography` emits a
  // `text-{role}` class for a pure role plus inline overlay for any
  // explicit scalar override (e.g. the label's `bold` font-weight).
  final labelEmit = emitTypography(
    merged.labelStyle,
    CoreStepsStyle.defaultLabelStyle,
  );
  // The current step's title takes its overlay between the title default
  // and the per-instance `titleStyle`, so a weight stated on `titleStyle`
  // still reaches every step (mirrors the Flutter `currentTitleTextStyle`).
  final titleEmitTypo = emitTypography(
    merged.titleStyle,
    CoreStepsStyle.defaultTitleStyle,
  );
  final currentTitleOverlay = CoreStepsStyle.defaultCurrentTitleStyle.merge(
    merged.currentTitleStyle,
  );
  final currentTitleEmitTypo = emitTypography(
    merged.titleStyle,
    CoreStepsStyle.defaultTitleStyle.merge(currentTitleOverlay),
  );
  final descriptionEmitTypo = emitTypography(
    merged.descriptionStyle,
    CoreStepsStyle.defaultDescriptionStyle,
  );

  // ─── Single inline signature for dimensional chrome (Epic #1603) ───
  // Every remaining (non-gap) spacing / size value is emitted
  // branch-lessly inline — no Tailwind `w-`/`pl-`/… utility class, no
  // override-suppression branch, so the computed pixels are identical for
  // the default and the override path (card model). Padding goes through
  // `spaceCss` (a step names its `--coui-space-*` variable); the
  // indicator size is a literal `rem`. Gap chrome is rendered as
  // explicit `Gap` siblings (see `indicatorContentGapStyle` /
  // `indicatorConnectorGapStyle` slots above). Only colour / typography
  // stay as token classes.
  final indicatorDimensionRem = '${indicatorSize / kRemDivisor}rem';
  final stepTopPaddingCss = spaceCss(stepPaddingHorizontal.top);
  final stepRightPaddingCss = spaceCss(stepPaddingHorizontal.end);
  final stepBottomPaddingHorizontalCss = spaceCss(stepPaddingHorizontal.bottom);
  final stepLeftPaddingHorizontalCss = spaceCss(stepPaddingHorizontal.start);

  // Completed-step check glyph — `CoreIconStyle` sized to
  // `indicatorSize × iconSizeRatio` carrying the active-step label
  // colour (the resolved `merged.activeLabelColor ?? default` Core token,
  // forwarded raw so `Icon` runs its own theme-free resolution).
  // `co_steps` only renders the glyph for completed steps, which are
  // always active, so a single resolved slot suffices.
  final activeLabelCore =
      merged.activeLabelColor ?? CoreStepsStyle.defaultActiveLabelColor;
  final glyphSize = (indicatorSize * iconSizeRatio).roundToDouble();
  final iconStyle = CoreIconStyle(size: glyphSize, color: activeLabelCore);
  // Failed-step cross: the same glyph box as the check, in the failed
  // label colour (the ink paired with the failed fill).
  final failedLabelCore =
      merged.failedLabelColor ?? CoreStepsStyle.defaultFailedLabelColor;
  final failedIconStyle = CoreIconStyle(
    size: glyphSize,
    color: failedLabelCore,
  );

  // List variant — the row slot, raw-forwarded. `StepItem` resolves its
  // own status row and geometry; this resolver only lays the Steps
  // partial under the caller's override (style-contract.md "합성 = 재구현
  // 금지" facet 3). Mirrors the Flutter resolver.
  final stepItemStyle = CoreStepsStyle.defaultStepItemStyle.merge(
    merged.stepItemStyle,
  );

  /// Selects the (`bg`, `text`, ring) [emitColor] results for the
  /// indicator at the given step [status]. A done or current step pins
  /// the primary/onPrimary token classes, an upcoming one the
  /// surface/onSurfaceVariant tokens inside an outlineVariant ring, a
  /// failed one the error/onError tokens (or the caller's raw override
  /// inline) — all routed through the [emitColor] results above. Only an
  /// upcoming indicator has a ring.
  ({Emit bg, Emit text, Emit? border, CoreColor fillToken})
  resolveIndicatorTokens(CoreStepStatus status) => switch (status) {
    CoreStepStatus.done || CoreStepStatus.current => (
      bg: activeIndicatorEmit,
      text: activeLabelEmit,
      border: null,
      fillToken:
          merged.activeIndicatorColor ??
          CoreStepsStyle.defaultActiveIndicatorColor,
    ),
    CoreStepStatus.todo => (
      bg: inactiveIndicatorEmit,
      text: inactiveLabelEmit,
      border: indicatorBorderEmit,
      fillToken: merged.indicatorColor ?? CoreStepsStyle.defaultIndicatorColor,
    ),
    CoreStepStatus.failed => (
      bg: failedIndicatorEmit,
      text: failedLabelEmit,
      border: null,
      fillToken:
          merged.failedIndicatorColor ??
          CoreStepsStyle.defaultFailedIndicatorColor,
    ),
  };

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer container `<div>` Tailwind className. The list
  /// variant is always a full-width column — its rows pin their trailing
  /// note to the end, so they need the width; it ignores [vertical].
  String buildRootClassName() {
    if (isList) return WebLayout.flexColFull;
    return vertical
        ? '${WebLayout.flex} ${WebLayout.flexCol}'
        : WebLayout.flexRowItemsStartFull;
  }

  /// Composes the per-step wrapper `<div>` Tailwind className.
  String buildStepWrapperClassName() => vertical
      ? WebLayout.flexRowItemsStretch
      : '${WebLayout.flex} ${WebLayout.flexCol} '
            '${WebLayout.flex1} ${WebLayout.minWZero}';

  /// Composes the indicator column `<div>` chrome — vertical only.
  /// The column width tracks the indicator diameter and is always
  /// emitted inline (`${indicatorSize / kRemDivisor}rem`) — single inline
  /// signature, no `w-size{N}` class / override branch.
  WebElementChrome buildIndicatorColumnChrome() => .new(
    className:
        '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.itemsCenter} '
        '${WebLayout.selfStretch} ${WebLayout.shrinkZero}',
    inlineStyles: Styles(raw: {'width': indicatorDimensionRem}),
  );

  /// Composes the indicator row `<div>` chrome — horizontal only.
  WebElementChrome buildIndicatorRowChrome() =>
      const .new(className: WebLayout.flexRowItemsCenter);

  /// Composes the indicator circle `<div>` Tailwind className. Only the
  /// structural flex / background-token class (`bgEmit`) and, for an
  /// upcoming indicator, the ring (`border` + the ring colour class) live
  /// here — the circle diameter (`width` + `height`), the ring thickness
  /// and the resolved `indicatorBorderRadius` (a full circle by default)
  /// are always emitted inline (single inline signature, no size or shape
  /// utility class).
  String buildIndicatorClassName(Emit bgEmit, Emit? borderEmit) => <String>[
    WebLayout.flex,
    WebLayout.itemsCenter,
    WebLayout.justifyCenter,
    WebLayout.shrinkZero,
    bgEmit.className,
    if (borderEmit != null) ...['border', borderEmit.className],
    // Marks this circle as a component surface, so a material preset
    // reaches it. Its Flutter twin gets the same treatment by
    // composing `OutlinedContainer`. Unconditional — the active,
    // inactive and failed fill tokens always resolve to a real, opaque
    // design token, so there is no fill-less-circle risk in any state.
    ...webSurfaceMarkerFor(.content),
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the indicator circle `<div>` inline CSS — diameter
  /// (`width` + `height`) and the resolved `indicatorBorderRadius` are
  /// always emitted (single inline signature), plus the optional
  /// inactive `background-color` raw override (spread from [bgEmit]).
  Styles buildIndicatorInlineStyles(
    Emit bgEmit,
    Emit? borderEmit,
    CoreColor fillToken,
  ) => .new(
    raw: {
      'width': indicatorDimensionRem,
      'height': indicatorDimensionRem,
      'border-radius': indicatorBorderRadius.toValue(),
      // The ring rides `strokeWidthCss` so a preset's stroke floor reaches
      // it through `--coui-stroke-width-N`, like every other line.
      if (borderEmit != null) ...{
        'border-width': strokeWidthCss(indicatorBorderWidth),
        ...surfaceBleedVar(strokeWidthCss(indicatorBorderWidth)),
      },
      ...?borderEmit?.inline,
      ...?bgEmit.inline,
      // The other half of the surface marker above.
      ...surfaceFillVar(fillToken),
    },
  );

  /// Composes the indicator number `<span>` Tailwind className —
  /// the label typography role + overlay class ([labelEmit]) plus the
  /// per-state text-colour class ([textEmit]; raw override stays inline).
  String buildIndicatorNumberClassName(Emit textEmit) => <String>[
    labelEmit.className,
    textEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the indicator number `<span>` inline CSS — the label
  /// typography scalar overlay (e.g. `font-weight`) plus the per-state
  /// text colour when it came from a raw (non-token) override (spread
  /// from [textEmit]).
  Styles? buildIndicatorNumberInlineStyles(Emit textEmit) {
    final raw = {...?labelEmit.inline, ...?textEmit.inline};
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the content column `<div>` chrome — axis-specific
  /// padding, all emitted inline (single inline signature, no
  /// `pb-`/`pt-`/`pr-` utility / override branch). The indicator ↔
  /// content gap is no longer baked here — it's rendered as an explicit
  /// `Gap(gapStyle: indicatorContentGapStyle)` sibling by `co_steps`.
  WebElementChrome buildContentColumnChrome({required bool isLast}) {
    if (vertical) {
      return WebElementChrome(
        className: '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.flex1}',
        inlineStyles: Styles(
          raw: {
            // `stepPadding` is encoded as a bottom-only `CoreEdgeInsets`
            // (see `CoreStepsStyle.defaultStepPadding`); emit the
            // `padding` shorthand so the bottom edge picks up the value
            // and the other three remain zero — equivalent to the
            // previous `padding-bottom`.
            if (!isLast) 'padding': stepPadding,
          },
        ),
      );
    }
    return WebElementChrome(
      className: '${WebLayout.flex} ${WebLayout.flexCol} ${WebLayout.minWZero}',
      inlineStyles: Styles(
        raw: {
          // Logical inline sides: the separation is from the *next* step,
          // which sits at the end — the right in English and the left in
          // Arabic. Physical `padding-right` put it on the wrong edge in
          // half the world's locales, and the layout still rendered.
          'padding-block-start': stepTopPaddingCss,
          'padding-block-end': stepBottomPaddingHorizontalCss,
          'padding-inline-start': stepLeftPaddingHorizontalCss,
          if (!isLast) 'padding-inline-end': stepRightPaddingCss,
        },
      ),
    );
  }

  /// The title colour emit of a step in [status] — an upcoming step reads
  /// quieter ([inactiveTitleEmit]), every other one ([titleEmit]).
  Emit titleColorEmitFor(CoreStepStatus status) =>
      status == CoreStepStatus.todo ? inactiveTitleEmit : titleEmit;

  /// Composes the title `<div>` Tailwind className — the per-state title
  /// typography role ([currentTitleEmitTypo] for the current step,
  /// [titleEmitTypo] for the rest) and the colour token class of the
  /// step's [status].
  String buildTitleClassName(CoreStepStatus status) => <String>[
    (status == CoreStepStatus.current ? currentTitleEmitTypo : titleEmitTypo)
        .className,
    titleColorEmitFor(status).className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the title `<div>` inline CSS — the per-state weight overlay
  /// plus any typography / colour scalar overlay that came from a raw
  /// override (token values stay on classes and contribute nothing here).
  Styles? buildTitleInlineStyles(CoreStepStatus status) {
    final raw = {
      ...?(status == CoreStepStatus.current
              ? currentTitleEmitTypo
              : titleEmitTypo)
          .inline,
      ...?titleColorEmitFor(status).inline,
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the description `<div>` Tailwind className — the
  /// description typography role + overlay ([descriptionEmitTypo]) and
  /// colour token class ([descriptionEmit]).
  String buildDescriptionClassName() => <String>[
    descriptionEmitTypo.className,
    descriptionEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the description `<div>` inline CSS — the typography /
  /// colour scalar overlays that came from a raw override.
  Styles? buildDescriptionInlineStyles() {
    final raw = {...?descriptionEmitTypo.inline, ...?descriptionEmit.inline};
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the connector `<div>` Tailwind className — only the
  /// background token class (the gap margins are always emitted inline;
  /// single inline signature). The connector leaving a completed step takes
  /// [activeConnectorEmit], every other one [connectorEmit].
  String buildConnectorClassName(Emit emit) => emit.className;

  /// Composes the connector `<div>` inline CSS — axis-specific
  /// thickness / flex, all emitted inline (single inline signature),
  /// plus the optional inline `background-color` override
  /// ([emit]). The pre/post-connector gap is no longer baked as
  /// `margin-*` / `min-height` here — it's rendered as two explicit
  /// `Gap(gapStyle: indicatorConnectorGapStyle)` siblings by
  /// `co_steps` (matching the Flutter widget).
  Styles buildConnectorInlineStyles(Emit emit) {
    final inlineBg = emit.inline?['background-color'];
    final raw = <String, String>{};
    // Stroke-axis value (mirrors Flutter's composed `Divider`, which
    // always runs `theme.geometry.stroke` on this same field) — must
    // ride `strokeWidthCss` so the neo-brutalism `strokeFloor` preset
    // reaches it via `--coui-stroke-width-N`, not a literal rem it can't
    // override.
    if (vertical) {
      raw
        ..['width'] = strokeWidthCss(connectorThickness)
        ..[WebLayout.flex] = '1 1 auto';
    } else {
      raw
        ..['height'] = strokeWidthCss(connectorThickness)
        ..[WebLayout.flex] = '1';
    }
    if (inlineBg != null) {
      raw['background-color'] = inlineBg;
    }
    return Styles(raw: raw);
  }

  // ─── Per-step list construction ───────────────────────
  final stepWrappers = <WebElementChrome>[];
  final indicatorColumns = <WebElementChrome>[];
  final indicatorRows = <WebElementChrome>[];
  final indicators = <WebElementChrome>[];
  final indicatorNumbers = <WebElementChrome>[];
  final contentColumns = <WebElementChrome>[];
  final titles = <WebElementChrome>[];
  final descriptions = <WebElementChrome>[];

  final stepWrapperClassName = buildStepWrapperClassName();
  final descriptionClassName = buildDescriptionClassName();
  final descriptionInlineStyles = buildDescriptionInlineStyles();
  // The list variant stacks `StepItem`s, which resolve their own chrome —
  // none of the numbered per-step entries are drawn, so none are baked.
  final stepCount = isList ? 0 : statuses.length;

  for (var i = 0; i < stepCount; i++) {
    final status = statuses[i];
    final isLast = i == stepCount - 1;
    final tokens = resolveIndicatorTokens(status);

    stepWrappers.add(WebElementChrome(className: stepWrapperClassName));
    indicatorColumns.add(buildIndicatorColumnChrome());
    indicatorRows.add(buildIndicatorRowChrome());
    indicators.add(
      WebElementChrome(
        className: buildIndicatorClassName(tokens.bg, tokens.border),
        inlineStyles: buildIndicatorInlineStyles(
          tokens.bg,
          tokens.border,
          tokens.fillToken,
        ),
      ),
    );
    indicatorNumbers.add(
      WebElementChrome(
        className: buildIndicatorNumberClassName(tokens.text),
        inlineStyles: buildIndicatorNumberInlineStyles(tokens.text),
      ),
    );
    contentColumns.add(buildContentColumnChrome(isLast: isLast));
    titles.add(
      WebElementChrome(
        className: buildTitleClassName(status),
        inlineStyles: buildTitleInlineStyles(status),
      ),
    );
    descriptions.add(
      WebElementChrome(
        className: descriptionClassName,
        inlineStyles: descriptionInlineStyles,
      ),
    );
  }

  // ─── Per-connector list construction ──────────────────
  // The connector leaving a completed step is filled in; every other one
  // keeps the quiet colour — two chromes, picked by the step it leaves.
  final activeConnectorChrome = WebElementChrome(
    className: buildConnectorClassName(activeConnectorEmit),
    inlineStyles: buildConnectorInlineStyles(activeConnectorEmit),
  );
  final inactiveConnectorChrome = WebElementChrome(
    className: buildConnectorClassName(connectorEmit),
    inlineStyles: buildConnectorInlineStyles(connectorEmit),
  );
  final connectors = <WebElementChrome>[
    for (var i = 0; i < stepCount - 1; i++)
      if (statuses[i] == CoreStepStatus.done)
        activeConnectorChrome
      else
        inactiveConnectorChrome,
  ];

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSteps(
    root: WebElementChrome(className: buildRootClassName()),
    stepWrappers: stepWrappers,
    indicatorColumns: indicatorColumns,
    indicatorRows: indicatorRows,
    indicators: indicators,
    indicatorNumbers: indicatorNumbers,
    contentColumns: contentColumns,
    titles: titles,
    descriptions: descriptions,
    connectors: connectors,
    iconStyle: iconStyle,
    failedIconStyle: failedIconStyle,
    indicatorContentGapStyle: indicatorContentGapStyle,
    indicatorConnectorGapStyle: indicatorConnectorGapStyle,
    indicatorConnectorGapHorizontalStyle: indicatorConnectorGapHorizontalStyle,
    stepItemStyle: stepItemStyle,
  );
}
