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

/// Paint-ready chrome for Web `Stepper`.
///
/// DOM shape (vertical):
///
/// ```text
/// root (<div>)                              // stepper container
///   └─ stepWrappers[i] (<div>)              // per-step row (vertical)
///        ├─ indicatorColumns[i] (<div>)     // indicator + connector column
///        │    ├─ <Clickable>                // navigable only — clickableStyle raw-forward
///        │    │    └─ indicators[i] (<div>)
///        │    │         └─ <Icon> | indicatorNumbers[i] (<span>)
///        │    └─ connectorWrappers[i] (<div>) // emitted for i < stepCount - 1
///        │         └─ <Divider>           // line chrome via connectorDividerStyles[i]
///        └─ contentColumns[i] (<div>)
///             ├─ labels[i] (<div>)
///             └─ descriptions[i] (<div>)    // optional, widget elects
/// ```
///
/// DOM shape (horizontal):
///
/// ```text
/// root (<div>)                              // stepper container
///   └─ stepWrappers[i] (<div>)              // per-step column — an equal share of the row
///        ├─ track (<div>)                   // half-line · indicator · half-line
///        │    ├─ connectorStart (<div>)     // leading half-line, flex-filling
///        │    │    └─ <Divider>             // connectorDividerStyles[i - 1]; none on the first step
///        │    ├─ <Clickable>                // navigable only — clickableStyle raw-forward
///        │    │    └─ indicators[i] (<div>)
///        │    │         └─ <Icon> | indicatorNumbers[i] (<span>)
///        │    └─ connectorEnd (<div>)       // trailing half-line, flex-filling
///        │         └─ <Divider>             // connectorDividerStyles[i]; none on the last step
///        └─ labels[i] (<div>)
/// ```
///
/// The connector between two steps is the trailing half of one and the
/// leading half of the next: the two meet at the column boundary and read
/// as one line. The first step's leading half and the last step's trailing
/// half are empty wrappers — no step lies beyond them — that keep their
/// width, which is what centres the circle in its column.
///
/// All slot chromes are non-null. `co_stepper` reads each entry's
/// `className` + `inlineStyles` straight off — no per-step merging or
/// fallback in the widget body. Per-step state (completed / current /
/// inactive) is closed over by `resolveStepper` via the
/// `currentStep` / `stepCount` arguments and baked into each indexed
/// entry. Interaction chrome (cursor / focus ring / press feedback /
/// keyboard activation) is owned by the composed `Clickable` — the
/// indicator chrome carries no navigability state.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [indicatorIconStyles] is forwarded per-step to the
///   completed-step check `Icon(iconStyle: …)` so the glyph size +
///   colour stay inside the single resolver entry point — no separate
///   `resolveStepperIndicatorIconSize` / `…IconColorClassNames`
///   helpers and no `CoreIconStyle` construction in the widget body.
///   [connectorDividerStyles] is forwarded per-connector to the line
///   `Divider(dividerStyle: …)` so the per-state colour + thickness
///   stay inside the single resolver entry point (mirrors the way Flutter
///   `Stepper` and `Menubar` pass a divider/separator style to the
///   composed * child — #1659).
class ResolvedStepper implements WebResolvedChrome {
  /// Creates a [ResolvedStepper].
  const ResolvedStepper({
    required this.root,
    required this.stepWrappers,
    required this.indicatorColumns,
    required this.indicators,
    required this.indicatorNumbers,
    required this.contentColumns,
    required this.track,
    required this.connectorStart,
    required this.connectorEnd,
    required this.labels,
    required this.labelSizerActive,
    required this.labelSizerInactive,
    required this.labelText,
    required this.descriptions,
    required this.connectorWrappers,
    required this.connectorDividerStyles,
    required this.indicatorIconStyles,
    required this.clickableStyle,
    required this.indicatorContentGapStyle,
    required this.labelGapStyle,
    required this.descriptionGapStyle,
  });

  /// Paint-ready chrome for the outer stepper container `<div>` —
  /// `flex flex-col` (vertical) or `flex flex-row items-start w-full`
  /// (horizontal).
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for each per-step wrapper `<div>` — one entry
  /// per step in input order.
  final List<WebElementChrome> stepWrappers;

  /// Paint-ready chrome for the per-step indicator column wrapper
  /// `<div>` (vertical layout only) — one entry per step. The widget
  /// skips emitting this slot in horizontal layout.
  final List<WebElementChrome> indicatorColumns;

  /// Paint-ready chrome for each indicator circle `<div>` — one entry
  /// per step, with per-state `bg-…` (or inline override) baked in.
  final List<WebElementChrome> indicators;

  /// Paint-ready chrome for each indicator number `<span>` (rendered
  /// only when the step is not completed; completed steps render a
  /// check `Icon` instead) — one entry per step.
  final List<WebElementChrome> indicatorNumbers;

  /// Paint-ready chrome for the per-step content column `<div>`
  /// (vertical layout only) — one entry per step. The widget skips
  /// emitting this slot in horizontal layout.
  final List<WebElementChrome> contentColumns;

  /// Paint-ready chrome for the per-step track `<div>` (horizontal layout
  /// only) — the row holding a step's half-line, circle and half-line. The
  /// widget skips emitting this slot in vertical layout.
  final WebElementChrome track;

  /// Paint-ready chrome for the leading half-line wrapper `<div>` of a
  /// step's track (horizontal layout only) — flex-fills the track beside the
  /// circle, holds [CoreStepperStyle.connectorMargin] off it, and centres
  /// the line in a band the height of the indicator.
  final WebElementChrome connectorStart;

  /// Paint-ready chrome for the trailing half-line wrapper `<div>` of a
  /// step's track (horizontal layout only) — the mirror of [connectorStart].
  final WebElementChrome connectorEnd;

  /// Paint-ready chrome for each step label `<div>` — one entry per
  /// step, with the bold weight baked in for the current step and the
  /// horizontal `margin-top` / `text-align: center` baked in for
  /// horizontal layout. In horizontal layout the wrapper is a 1×1
  /// `grid` so the width-reservation layers below can stack in the
  /// same cell.
  final List<WebElementChrome> labels;

  /// Paint-ready chrome for the invisible active-state label layer
  /// (horizontal layout only) — stacked in the label wrapper's grid
  /// cell so the step column always reserves the **active (bold)**
  /// label width. Without the reservation the active⇄inactive weight
  /// toggle changes the column width and shifts every later indicator
  /// (~1.2px per bold label on both platforms — the Flutter twin
  /// reserves the same way with invisible `Text` layers).
  final WebElementChrome labelSizerActive;

  /// Paint-ready chrome for the invisible inactive-state label layer
  /// (horizontal layout only) — same cell as [labelSizerActive] so the
  /// reserved width is the max of both states even when an override
  /// styles the inactive label wider.
  final WebElementChrome labelSizerInactive;

  /// Paint-ready chrome for the visible label text `<span>`
  /// (horizontal layout only) — pins the span to the same grid cell as
  /// the reservation layers; typography inherits from the per-step
  /// label wrapper ([labels]).
  final WebElementChrome labelText;

  /// Paint-ready chrome for each step description `<div>` — one entry
  /// per step; the widget elects not to render the element when the
  /// underlying [CoreStepItem] supplies no description.
  final List<WebElementChrome> descriptions;

  /// Paint-ready chrome for each connector layout wrapper `<div>`
  /// between adjacent steps (vertical layout only) — `stepCount - 1`
  /// entries. Carries the flex-fill / min-extent / design-system margin
  /// layout only (the line colour + thickness live on the nested
  /// [connectorDividerStyles] passed to the composed `Divider`). The
  /// horizontal layout's connector is the two half-line wrappers
  /// [connectorStart] / [connectorEnd] instead.
  final List<WebElementChrome> connectorWrappers;

  /// Nested [CoreDividerStyle] slot for each connector line — one entry
  /// per gap (`stepCount - 1`), forwarded to `Divider(dividerStyle:
  /// …)`; in the horizontal layout step `i`'s trailing half and step
  /// `i + 1`'s leading half both read entry `i`. Carries the per-state
  /// colour (completed → `connectorActiveColor` override else `primary`;
  /// upcoming → `connectorInactiveColor` override else `outlineVariant`;
  /// disabled → the one `connectorDisabledColor`) plus the resolved connector
  /// thickness. The composed `Divider` finalises the platform
  /// conversion (mirrors `Menubar` forwarding `separatorStyle` to its
  /// nested `Separator`).
  final List<CoreDividerStyle> connectorDividerStyles;

  /// Nested [CoreIconStyle] slot for each step's completed-state check
  /// glyph — one entry per step, forwarded to `Icon(iconStyle: …)`.
  /// Carries the resolved glyph size (indicator diameter × the resolved
  /// `iconSizeRatio`) and `onSecondary` colour, merged with the
  /// per-instance `indicatorIconStyle` override. The widget reads the
  /// entry only when the step renders the check icon (completed steps);
  /// pending steps render the number `<span>`.
  final List<CoreIconStyle> indicatorIconStyles;

  /// Nested [CoreClickableStyle] slot for the composed per-indicator
  /// `Clickable` — `CoreStepperStyle.defaultClickableStyle` merged with
  /// the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)` when the stepper is navigable.
  final CoreClickableStyle clickableStyle;

  /// Nested [CoreGapStyle] slot for the gap between the indicator column
  /// and the step content column — forwarded straight to
  /// `Gap(gapStyle: …)` inside `co_stepper` (vertical layout only).
  /// `Gap` runs its own resolve / scaling step so the slot stays in
  /// pre-scaling units (mirrors the Flutter widget's `Gap` sibling
  /// between the indicator `Column` and content `Expanded`).
  final CoreGapStyle indicatorContentGapStyle;

  /// Nested [CoreGapStyle] slot for the gap between the indicator and
  /// its label in the horizontal layout — forwarded straight to
  /// `Gap(gapStyle: …)` inside `co_stepper`. `Gap` runs its own
  /// resolve / scaling step so the slot stays in pre-scaling units
  /// (mirrors the Flutter widget's `Gap` sibling between the indicator
  /// and the label `Text`).
  final CoreGapStyle labelGapStyle;

  /// Nested [CoreGapStyle] slot for the gap between a step's label and its
  /// description (vertical layout only) — forwarded straight to
  /// `Gap(gapStyle: …)` inside `co_stepper`, between the label `<div>` and
  /// the description `<div>` (mirrors the Flutter widget's `Gap` sibling
  /// between the two `Text`s).
  final CoreGapStyle descriptionGapStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedStepper] for the given [context].
///
/// [enabled] picks the disabled palette — `disabledContainer` /
/// `disabledOutline` / `disabledContent` — instead of the state colours; it
/// is a semantic state, not an interaction one, so it is a resolver input.
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → theme.coreComponentTheme.stepper.style
///   → widget.stepperStyle
/// ```
///
/// Closes over the per-build [currentStep] / [stepCount] / [vertical]
/// inputs so every per-step / per-connector chrome bundle is baked
/// into the matching list entry.
///
/// Web EMIT is theme-free — every colour / typography value routes
/// through the named [CoreStepperStyle] defaults and the emit family
/// ([emitColor] / [emitTypography]), so the browser resolves the
/// `--coui-*` CSS variables at runtime. No `scheme.resolve` (a no-op on
/// Web), no direct `colorScheme.X` / `typography.X` references.
ResolvedStepper resolveStepper(
  BuildContext context, {
  required bool vertical,
  required bool enabled,
  required int currentStep,
  required int stepCount,
  CoreStepperStyle? stepperStyle,
}) {
  final coreTheme = context.theme.coreComponentTheme?.stepper;

  final merged = resolveStyleChain(const CoreStepperStyle(), [
    coreTheme?.style,
    stepperStyle,
  ]);

  // ─── Stage 1 RESOLVE — dimensional / nested-slot values ───
  final indicatorSize =
      merged.indicatorSize ?? CoreStepperStyle.defaultIndicatorSize;
  final connectorThickness =
      merged.connectorThickness ?? CoreStepperStyle.defaultConnectorThickness;
  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override and forward the resulting slot straight to
  // the sibling `Gap` in `co_stepper` (Epic #1603 chaining gate —
  // mirrors the Flutter `Gap(gapStyle: …)` sibling pattern). `Gap`
  // runs its own resolve / scaling step inside its own resolver.
  final indicatorContentGapStyle = CoreStepperStyle
      .defaultIndicatorContentGapStyle
      .merge(merged.indicatorContentGapStyle);
  final labelGapStyle = CoreStepperStyle.defaultLabelGapStyle.merge(
    merged.labelGapStyle,
  );
  final descriptionGapStyle = CoreStepperStyle.defaultDescriptionGapStyle.merge(
    merged.descriptionGapStyle,
  );
  final stepPaddingInsets =
      merged.stepPadding ?? CoreStepperStyle.defaultStepPadding;
  final stepPadding = stepPaddingInsets.toValue();
  final connectorMargin =
      merged.connectorMargin ?? CoreStepperStyle.defaultConnectorMargin;
  final connectorMarginVertical =
      merged.connectorMarginVertical ??
      CoreStepperStyle.defaultConnectorMarginVertical;
  final connectorMinExtent =
      merged.connectorMinExtent ?? CoreStepperStyle.defaultConnectorMinExtent;
  final iconSizeRatio =
      merged.iconSizeRatio ?? CoreStepperStyle.defaultIconSizeRatio;

  // The disabled ink — the one colour a disabled stepper writes and draws
  // in, laid over whatever the state would have chosen.
  final disabledForegroundToken =
      merged.disabledForegroundColor ??
      CoreStepperStyle.defaultDisabledForegroundColor;
  final disabledInk = CoreTextStyle(color: disabledForegroundToken);

  /// A text override with the disabled ink laid on top when the stepper is
  /// disabled; the override itself when it is enabled.
  CoreTextStyle? inkOver(CoreTextStyle? override) => enabled
      ? override
      : (override == null ? disabledInk : override.merge(disabledInk));

  // Completed-step check-glyph icon style — design-system size
  // (indicator diameter × ratio) + `onPrimary` colour (the disabled ink
  // while disabled), merged with the per-instance `indicatorIconStyle`
  // override. The check glyph only renders on completed steps (state
  // colour is always `onPrimary`), so a single resolved slot covers every
  // rendered icon — `co_stepper` forwards it straight to
  // `Icon(iconStyle: …)`.
  final indicatorIconSize = (indicatorSize * iconSizeRatio).roundToDouble();
  final indicatorIconEnabledStyle = CoreStepperStyle.defaultIndicatorIconStyle
      .copyWith(size: indicatorIconSize)
      .merge(merged.indicatorIconStyle);
  final indicatorIconStyle = enabled
      ? indicatorIconEnabledStyle
      : indicatorIconEnabledStyle.copyWith(color: disabledForegroundToken);

  // Nested Clickable slot — partial default merged with the override,
  // raw-forwarded (the Clickable's own resolver fills the rest: press
  // scale / focus ring / cursor / durations).
  final clickableStyle = CoreStepperStyle.defaultClickableStyle.merge(
    merged.clickableStyle,
  );

  // Indicator ring. A completed circle draws one only when the caller opts
  // in with a colour or a width (mirrors the Flutter `hasBorder` branch);
  // the current and upcoming circles are outlined by design — the current
  // one's ring takes `indicatorBorderColor`, else
  // `indicatorCurrentBorderColor`, else `primary`; the upcoming one's
  // `indicatorBorderColor`, else
  // `indicatorInactiveBorderColor`, else `outlineVariant` (a disabled stepper:
  // `indicatorDisabledBorderColor`, else `disabledOutline`, for both). Web
  // EMIT is theme-free — every colour emits as a token reference
  // (`.toValue()` → `rgb(var(--coui-X))`) and the browser resolves the CSS
  // variable at runtime, so `scheme.resolve` (a no-op on Web) is omitted.
  final indicatorBorderColor = merged.indicatorBorderColor?.toValue();
  final indicatorBorderWidth = merged.indicatorBorderWidth;
  final indicatorCurrentRingColor =
      (enabled
              ? (merged.indicatorBorderColor ??
                    merged.indicatorCurrentBorderColor ??
                    CoreStepperStyle.defaultIndicatorCurrentBorderColor)
              : (merged.indicatorDisabledBorderColor ??
                    CoreStepperStyle.defaultIndicatorDisabledBorderColor))
          .toValue();
  final indicatorInactiveRingColor =
      (enabled
              ? (merged.indicatorBorderColor ??
                    merged.indicatorInactiveBorderColor ??
                    CoreStepperStyle.defaultIndicatorInactiveBorderColor)
              : (merged.indicatorDisabledBorderColor ??
                    CoreStepperStyle.defaultIndicatorDisabledBorderColor))
          .toValue();
  final indicatorBorderRadius =
      merged.indicatorBorderRadius ??
      CoreStepperStyle.defaultIndicatorBorderRadius;

  // ─── Stage 2 EMIT (Web, theme-free) — indicator fill colours ──
  // Completed indicators use the `primary` token (or the
  // `indicatorActiveColor` override; `disabledContainer` while disabled);
  // the current indicator the `surface` token (or the `indicatorCurrentColor`
  // override) and upcoming indicators the `surface` token (or the
  // `indicatorInactiveColor` override). Each value routes through
  // `emitColor` so a token-bound colour emits a `bg-{token}` class
  // (dark-mode reactive) and a raw override goes inline (mirrors the
  // Flutter per-state indicator fill).
  final completedFillEmit = emitColor(
    enabled ? merged.indicatorActiveColor : merged.indicatorDisabledColor,
    enabled
        ? CoreStepperStyle.defaultIndicatorActiveColor
        : CoreStepperStyle.defaultIndicatorDisabledColor,
    .background,
  );
  final currentFillEmit = emitColor(
    merged.indicatorCurrentColor,
    CoreStepperStyle.defaultIndicatorCurrentColor,
    .background,
  );
  final inactiveFillEmit = emitColor(
    merged.indicatorInactiveColor,
    CoreStepperStyle.defaultIndicatorInactiveColor,
    .background,
  );
  // Fill token per state (pre-EMIT `CoreColor`) — the same source the
  // `bg-{token}` class above emits from. Published verbatim via
  // `surfaceFillVar` below so a material preset can restate the fill at
  // its own alpha without knowing which token the indicator chose.
  final completedFillToken = enabled
      ? (merged.indicatorActiveColor ??
            CoreStepperStyle.defaultIndicatorActiveColor)
      : (merged.indicatorDisabledColor ??
            CoreStepperStyle.defaultIndicatorDisabledColor);
  final currentFillToken =
      merged.indicatorCurrentColor ??
      CoreStepperStyle.defaultIndicatorCurrentColor;
  final inactiveFillToken =
      merged.indicatorInactiveColor ??
      CoreStepperStyle.defaultIndicatorInactiveColor;
  // CSS fill colour of a completed circle — the `border-color` fallback when
  // the caller opts into an indicator border without a colour (mirrors the
  // Flutter `indicatorBorderColor ?? color` branch). Theme-free
  // (`.toValue()` → `rgb(var(--coui-X))`).
  final completedFillCss = completedFillToken.toValue();
  // The ring of each state, or null where none is drawn: a completed circle
  // wears one only on an opt-in.
  final completedRing =
      indicatorBorderColor != null || indicatorBorderWidth != null
      ? (indicatorBorderColor ?? completedFillCss)
      : null;

  // ─── Stage 2 EMIT — indicator number typography (per state) ──
  // The number glyph uses the `labelMedium` role at a semi-bold weight,
  // with the `onSurface` foreground on the current step and the
  // `onSurfaceVariant` foreground on the pending ones, both over the
  // surface fill (the disabled ink on both while disabled). The two roles
  // live on the named Core defaults; `emitTypography` materialises the role
  // as a `text-{role}` class (+ token colour class) and the weight inline.
  final numberActiveEmit = emitTypography(
    inkOver(merged.indicatorNumberActiveStyle),
    CoreStepperStyle.defaultIndicatorNumberActiveStyle,
  );
  final numberInactiveEmit = emitTypography(
    inkOver(merged.indicatorNumberInactiveStyle),
    CoreStepperStyle.defaultIndicatorNumberInactiveStyle,
  );

  // ─── Stage 2 EMIT — step label typography (per state) ──
  // The orientation-specific role (`titleSmall` vertical / `labelLarge`
  // horizontal) + `onSurface` colour live on the named Core defaults
  // (merged with the orientation-specific override); the per-instance
  // `labelStyle` overlays through `emitTypography`. The current step's
  // label takes its overlay (semi-bold by default) and an upcoming step's
  // its own (`onSurfaceVariant` by default) between the two, so a weight
  // or colour stated on `labelStyle` still reaches every step (mirrors
  // the Flutter `label{Active|Inactive|Upcoming}TextStyle`). A disabled
  // stepper writes every label in the one disabled ink.
  final labelDefault = vertical
      ? CoreStepperStyle.defaultLabelVerticalStyle.merge(
          merged.labelVerticalStyle,
        )
      : CoreStepperStyle.defaultLabelHorizontalStyle.merge(
          merged.labelHorizontalStyle,
        );
  final labelInactiveEmit = emitTypography(
    inkOver(merged.labelStyle),
    labelDefault,
  );
  final labelActiveOverlay = CoreStepperStyle.defaultLabelActiveStyle.merge(
    merged.labelActiveStyle,
  );
  final labelActiveEmit = emitTypography(
    inkOver(merged.labelStyle),
    labelDefault.merge(labelActiveOverlay),
  );
  final labelUpcomingOverlay = CoreStepperStyle.defaultLabelUpcomingStyle.merge(
    merged.labelUpcomingStyle,
  );
  final labelUpcomingEmit = emitTypography(
    inkOver(merged.labelStyle),
    labelDefault.merge(labelUpcomingOverlay),
  );

  // ─── Stage 2 EMIT — step description typography ──
  // The `bodySmall` role + `onSurfaceVariant` colour live on the named
  // `defaultDescriptionStyle`; the per-instance `descriptionStyle`
  // overlays through `emitTypography` (the disabled ink on top while
  // disabled).
  final descriptionEmit = emitTypography(
    inkOver(merged.descriptionStyle),
    CoreStepperStyle.defaultDescriptionStyle,
  );

  // ─── Stage 1 RESOLVE — per-state connector colours ──
  // Completed segments use the `connectorActiveColor` override else the
  // named `primary` default; upcoming segments use the
  // `connectorInactiveColor` override else the named `outlineVariant`
  // default; a disabled stepper draws every segment in its one disabled
  // colour (mirrors the Flutter resolver's per-state connector fill).
  // The colour stays a `CoreColor` token and rides on the nested
  // `Divider` (`connectorDividerStyles`), which finalises the platform
  // conversion.
  final connectorDisabledColor =
      merged.connectorDisabledColor ??
      CoreStepperStyle.defaultConnectorDisabledColor;
  final connectorActiveColor = enabled
      ? (merged.connectorActiveColor ??
            CoreStepperStyle.defaultConnectorActiveColor)
      : connectorDisabledColor;
  final connectorInactiveColor = enabled
      ? (merged.connectorInactiveColor ??
            CoreStepperStyle.defaultConnectorInactiveColor)
      : connectorDisabledColor;

  // ─── Local builders ───────────────────────────────────

  /// The label emit of step [index] — current, completed or upcoming.
  Emit labelEmitFor(int index) {
    if (index == currentStep) return labelActiveEmit;
    return index < currentStep ? labelInactiveEmit : labelUpcomingEmit;
  }

  /// Composes the outer stepper container `<div>` Tailwind className —
  /// `flex flex-col` (vertical) or `flex flex-row items-start w-full`
  /// (horizontal).
  String buildRootClassName() => vertical
      ? '${WebLayout.flex} ${WebLayout.flexCol}'
      : WebLayout.flexRowItemsStartFull;

  /// Composes the per-step wrapper `<div>` Tailwind className —
  /// `flex flex-row items-stretch` (vertical row) or `flex flex-col
  /// items-stretch flex-1` (horizontal step column: an equal share of the
  /// row, its track and label stretched across it).
  String buildStepWrapperClassName() => vertical
      ? WebLayout.flexRowItemsStretch
      : '${WebLayout.flex} ${WebLayout.flexCol} '
            '${WebLayout.itemsStretch} ${WebLayout.flex1}';

  /// Composes the per-step wrapper `<div>` inline CSS — horizontal only: a
  /// `min-width` of the indicator, so a row too narrow for its circles
  /// overflows instead of squeezing them. A column with no `min-width` could
  /// not shrink below its longest word; this one states a floor and nothing
  /// above it, so a label that does not fit its share wraps inside its
  /// column instead of pushing the row past its edge. The Flutter twin
  /// reads the same floor as `minColumnWidth`.
  Styles? buildStepWrapperInlineStyles() {
    if (vertical || stepCount == 0) return null;

    return Styles(
      raw: {'min-width': '${indicatorSize / kRemDivisor}rem'},
    );
  }

  /// Composes the indicator column `<div>` Tailwind className —
  /// `flex flex-col items-center` (vertical layout only).
  String buildIndicatorColumnClassName() => WebLayout.flexColItemsCenter;

  /// Composes the indicator column `<div>` inline CSS —
  /// `align-self: stretch`, fixed `width: Xrem` matching the indicator
  /// diameter, `flex-shrink: 0` (vertical layout only).
  Styles buildIndicatorColumnInlineStyles() => .new(
    raw: {
      'align-self': 'stretch',
      'width': '${indicatorSize / kRemDivisor}rem',
      'flex-shrink': '0',
    },
  );

  /// Composes the indicator circle `<div>` Tailwind className —
  /// `flex items-center justify-center shrink-0`, plus the per-state
  /// `bg-…` token when the fill is token-bound. Interaction chrome
  /// (cursor / focus ring / press feedback) is owned by the composing
  /// `Clickable`. The circular shape is emitted inline (resolved
  /// `indicatorBorderRadius.toValue()`, defaulting to a full circle)
  /// rather than via a structural radius class so the indicator stays
  /// on the single inline-CSS signature and the shape stays overridable
  /// (Epic #1603 — matches the `radio_group` ring).
  String buildIndicatorClassName(String bgClass) {
    final parts = [
      WebLayout.flex,
      WebLayout.itemsCenter,
      WebLayout.justifyCenter,
      WebLayout.shrinkZero,
      if (bgClass.isNotEmpty) bgClass,
      // Marks this circle as a component surface, so a material preset
      // reaches it. Its Flutter twin gets the same treatment by
      // composing `OutlinedContainer`. Unconditional — every state's
      // fill token always resolves to a real, opaque design token, so
      // there is no fill-less-circle risk in any of them.
      ...webSurfaceMarkerFor(.content),
    ];
    return parts.join(' ');
  }

  /// Composes the indicator circle `<div>` inline CSS — `width` /
  /// `height` (rem) matching the resolved indicator diameter, the
  /// resolved `indicatorBorderRadius` (a full circle by default), the
  /// optional inline `background-color` override (when the fill is a
  /// raw colour), plus the ring when [ringCss] is given: the current and
  /// upcoming circles always wear one, a completed one only when the caller
  /// opts in with a colour or width override (mirrors the Flutter
  /// `Border.all` branch; the ring colour then falls back to the completed
  /// fill when only a width override is set).
  Styles buildIndicatorInlineStyles(
    Map<String, String>? inlineFill,
    CoreColor fillToken, {
    required String? ringCss,
  }) {
    return Styles(
      raw: {
        // The ring is inside the stated diameter, as on Flutter/Figma.
        'box-sizing': 'border-box',
        'width': '${indicatorSize / kRemDivisor}rem',
        'height': '${indicatorSize / kRemDivisor}rem',
        'border-radius': indicatorBorderRadius.toValue(),
        ...?inlineFill,
        // The other half of the surface marker above.
        ...surfaceFillVar(fillToken),
        if (ringCss != null) ...{
          'border-style': 'solid',
          'border-width': strokeWidthCss(
            indicatorBorderWidth ??
                CoreStepperStyle.defaultIndicatorBorderWidth,
          ),
          ...surfaceBleedVar(
            strokeWidthCss(
              indicatorBorderWidth ??
                  CoreStepperStyle.defaultIndicatorBorderWidth,
            ),
          ),
          'border-color': ringCss,
        },
      },
    );
  }

  /// Composes the content column `<div>` Tailwind className —
  /// `flex flex-col flex-1 min-w-0` (vertical layout only).
  String buildContentColumnClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol} '
      '${WebLayout.flex1} ${WebLayout.minWZero}';

  /// Composes the content column `<div>` inline CSS — optional
  /// `padding` shorthand from the resolved `stepPadding` (which the
  /// design system encodes as bottom-only) when the step is not the
  /// final one. The horizontal gap between the indicator column and the
  /// content column is emitted as a sibling `Gap` (carrying
  /// [indicatorContentGapStyle]) in `co_stepper` — mirrors the Flutter
  /// `Gap` `Row` sibling — so it is *not* baked into this slot.
  Styles buildContentColumnInlineStyles({
    required bool isNotLast,
    required int index,
  }) {
    // 1lh uses this step's final label typography, not the surrounding body.
    // Authored spacing follows density; centering uses line/size geometry.
    final labelEmit = labelEmitFor(index);
    final diameter = pinnedLengthCss(indicatorSize);
    // Flutter LineMetrics.height rounds ascent + descent to logical pixels:
    // https://api.flutter.dev/flutter/dart-ui/LineMetrics/height.html
    // Project only the alignment metric, after resolving the effective 1lh.
    // 1px is that metric's quantum, not authored spacing.
    // The rendered text stays fractional.
    final alignment =
        'max(${pinnedLengthCss(0)}, '
        'calc(($diameter - round(nearest, 1lh, 1px)) / 2))';
    return Styles(
      raw: {
        ...?labelEmit.inline,
        if (isNotLast) 'padding': stepPadding,
        'padding-top': isNotLast
            ? 'calc(${spaceCss(stepPaddingInsets.top)} + $alignment)'
            : alignment,
      },
    );
  }

  /// Composes the label `<div>` Tailwind className — the per-state
  /// label typography class ([emitTypography] role + token colour,
  /// including the current step's overlay or an upcoming step's).
  /// Word-wrap fallback inherits from the `CoUIWeb` app root
  /// (`break-words`).
  String buildLabelClassName({required int index}) {
    final labelClass = labelEmitFor(index).className;
    // Horizontal wrapper is a 1×1 grid so the invisible state-sizer
    // layers (labelSizerActive / labelSizerInactive) and the visible
    // text stack in one cell — the wrapper then sizes to the widest
    // state and the active⇄inactive weight toggle cannot shift the
    // step columns.
    if (!vertical) return '${labelClass.trim()} ${WebLayout.grid}'.trim();
    return labelClass.trim();
  }

  /// Composes the label `<div>` inline CSS — the per-state `labelStyle`
  /// overlay ([emitTypography] inline) merged with the horizontal
  /// layout's `text-align: center`. The horizontal-axis `margin-top`
  /// between the indicator and the label is emitted as a sibling `Gap`
  /// (carrying [labelGapStyle]) in `co_stepper` — mirrors the Flutter
  /// `Gap` `Column` sibling — so it is *not* baked into this slot.
  /// Returns `null` when no inline CSS is needed.
  Styles? buildLabelInlineStyles({required int index}) {
    final overlay = labelEmitFor(index).inline;
    final raw = <String, String>{
      if (!vertical) 'text-align': 'center',
      ...?overlay,
    };
    if (raw.isEmpty) return null;
    return Styles(raw: raw);
  }

  /// Composes the description `<div>` Tailwind className — the
  /// [emitTypography] role + token colour class.
  String buildDescriptionClassName() => descriptionEmit.className.trim();

  /// Composes the description `<div>` inline CSS — the optional
  /// `descriptionStyle` overlay ([emitTypography] inline).
  Styles? buildDescriptionInlineStyles() {
    final overlay = descriptionEmit.inline;
    if (overlay == null || overlay.isEmpty) return null;
    return Styles(raw: overlay);
  }

  /// Composes the vertical connector layout wrapper `<div>` inline CSS —
  /// flex / min-extent sizing and the design-system margin tokens. The line
  /// colour + thickness live on the nested `Divider` (via
  /// [connectorDividerStyles]) — convention #6 keeps the surrounding layout
  /// on this wrapper, not the composed child.
  Styles buildConnectorWrapperInlineStyles() {
    return Styles(
      raw: {
        'display': WebLayout.flex,
        WebLayout.flex: '1 1 auto',
        'min-height': '${connectorMinExtent / kRemDivisor}rem',
        'margin-top': spaceCss(connectorMarginVertical),
        'margin-bottom': spaceCss(connectorMarginVertical),
      },
    );
  }

  /// Composes a horizontal half-line wrapper `<div>` inline CSS — the band
  /// beside the circle. It flex-fills what the circle leaves, holds
  /// `connectorMargin` off the circle on the side [towardsCircle] names
  /// (logical, so a right-to-left row mirrors like its Flutter twin), and
  /// is a band the height of the indicator with the line centred in it.
  /// Offsetting the wrapper's TOP to the indicator centre — which is what
  /// `margin-top: indicatorSize/2` did — lands the line's centre half a
  /// thickness low, because the line's box is exactly its thickness tall.
  /// Centring in a band needs no knowledge of the thickness, and is the same
  /// construction the Flutter twin uses. `min-width: 0` lets the band shrink
  /// below its line's own width, so the share stays an even split.
  Styles buildConnectorHalfInlineStyles({required bool towardsCircleAtEnd}) {
    return Styles(
      raw: {
        'display': WebLayout.flex,
        WebLayout.flex: '1 1 0%',
        'min-width': '0',
        towardsCircleAtEnd ? 'margin-inline-end' : 'margin-inline-start':
            spaceCss(connectorMargin),
        'align-self': 'flex-start',
        'height': '${indicatorSize / kRemDivisor}rem',
        'align-items': 'center',
      },
    );
  }

  // ─── Per-step list construction ───────────────────────
  final stepWrappers = <WebElementChrome>[];
  final indicatorColumns = <WebElementChrome>[];
  final indicators = <WebElementChrome>[];
  final indicatorNumbers = <WebElementChrome>[];
  final contentColumns = <WebElementChrome>[];
  final labels = <WebElementChrome>[];
  final descriptions = <WebElementChrome>[];
  final indicatorIconStyles = <CoreIconStyle>[];

  final stepWrapperClassName = buildStepWrapperClassName();
  final stepWrapperInlineStyles = buildStepWrapperInlineStyles();
  final indicatorColumnClassName = buildIndicatorColumnClassName();
  final indicatorColumnInlineStyles = buildIndicatorColumnInlineStyles();
  final contentColumnClassName = buildContentColumnClassName();
  final descriptionClassName = buildDescriptionClassName();
  final descriptionInlineStyles = buildDescriptionInlineStyles();
  // The three completed / current / upcoming indicator chrome bundles never
  // vary across steps (only the per-step state flag selects between them),
  // so compose them once and index by state below.
  final completedIndicatorClassName = buildIndicatorClassName(
    completedFillEmit.className,
  );
  final currentIndicatorClassName = buildIndicatorClassName(
    currentFillEmit.className,
  );
  final inactiveIndicatorClassName = buildIndicatorClassName(
    inactiveFillEmit.className,
  );
  final completedIndicatorInlineStyles = buildIndicatorInlineStyles(
    completedFillEmit.inline,
    completedFillToken,
    ringCss: completedRing,
  );
  final currentIndicatorInlineStyles = buildIndicatorInlineStyles(
    currentFillEmit.inline,
    currentFillToken,
    ringCss: indicatorCurrentRingColor,
  );
  final inactiveIndicatorInlineStyles = buildIndicatorInlineStyles(
    inactiveFillEmit.inline,
    inactiveFillToken,
    ringCss: indicatorInactiveRingColor,
  );

  for (var i = 0; i < stepCount; i++) {
    final isCompleted = i < currentStep;
    final isCurrent = i == currentStep;
    final isNotLast = i < stepCount - 1;

    stepWrappers.add(
      WebElementChrome(
        className: stepWrapperClassName,
        inlineStyles: stepWrapperInlineStyles,
      ),
    );
    indicatorColumns.add(
      WebElementChrome(
        className: indicatorColumnClassName,
        inlineStyles: indicatorColumnInlineStyles,
      ),
    );
    indicators.add(
      WebElementChrome(
        className: isCompleted
            ? completedIndicatorClassName
            : isCurrent
            ? currentIndicatorClassName
            : inactiveIndicatorClassName,
        inlineStyles: isCompleted
            ? completedIndicatorInlineStyles
            : isCurrent
            ? currentIndicatorInlineStyles
            : inactiveIndicatorInlineStyles,
      ),
    );
    final numberEmit = isCurrent ? numberActiveEmit : numberInactiveEmit;
    indicatorNumbers.add(
      WebElementChrome(
        className: numberEmit.className,
        inlineStyles: numberEmit.inline == null
            ? null
            : Styles(raw: numberEmit.inline),
      ),
    );
    contentColumns.add(
      WebElementChrome(
        className: '$contentColumnClassName ${labelEmitFor(i).className}',
        inlineStyles: buildContentColumnInlineStyles(
          isNotLast: isNotLast,
          index: i,
        ),
      ),
    );
    labels.add(
      WebElementChrome(
        className: buildLabelClassName(index: i),
        inlineStyles: buildLabelInlineStyles(index: i),
      ),
    );
    descriptions.add(
      WebElementChrome(
        className: descriptionClassName,
        inlineStyles: descriptionInlineStyles,
      ),
    );
    // Same resolved icon style for every step — the check glyph only
    // renders on completed steps (always `onPrimary`), so there is no
    // per-step variation. Indexed by step so `co_stepper` reads it the
    // same way as the other per-step slots.
    indicatorIconStyles.add(indicatorIconStyle);
  }

  // ─── Per-connector list construction ──────────────────
  // The wrapper layout stays identical for every gap because it is
  // state independent (and is only the vertical layout's — the horizontal
  // connector is the two half-line wrappers below). Only the line colour
  // varies with the completed flag and that colour rides on the nested
  // divider style slot.
  final connectorWrapperInlineStyles = vertical
      ? buildConnectorWrapperInlineStyles()
      : null;
  final connectorWrappers = <WebElementChrome>[];
  final connectorDividerStyles = <CoreDividerStyle>[];
  for (var i = 0; i < stepCount - 1; i++) {
    final isCompleted = i < currentStep;
    if (connectorWrapperInlineStyles != null) {
      connectorWrappers.add(
        WebElementChrome(
          className: '',
          inlineStyles: connectorWrapperInlineStyles,
        ),
      );
    }
    connectorDividerStyles.add(
      CoreDividerStyle(
        color: isCompleted ? connectorActiveColor : connectorInactiveColor,
        thickness: connectorThickness,
      ),
    );
  }

  // ─── Label width-reservation layers (horizontal only) ─
  // Invisible copies of both label states stack in the label wrapper's
  // 1×1 grid cell, so the wrapper always sizes to the widest state and
  // the active⇄inactive bold toggle repaints in place instead of
  // resizing the step column (which shifted every later indicator).
  String buildLabelSizerClassName(String stateClassName) => <String>[
    if (stateClassName.trim().isNotEmpty) stateClassName.trim(),
    _kLabelCell,
    WebLayout.invisible,
  ].join(' ');
  final labelSizerActive = WebElementChrome(
    className: buildLabelSizerClassName(labelActiveEmit.className),
    inlineStyles: labelActiveEmit.inline == null
        ? null
        : Styles(raw: labelActiveEmit.inline),
  );
  final labelSizerInactive = WebElementChrome(
    className: buildLabelSizerClassName(labelInactiveEmit.className),
    inlineStyles: labelInactiveEmit.inline == null
        ? null
        : Styles(raw: labelInactiveEmit.inline),
  );

  // ─── Horizontal track and its two half-line wrappers ──
  // The row a step's circle sits in, and the half-line bands either side of
  // it. State independent, and only the horizontal layout's.
  const track = WebElementChrome(className: WebLayout.flexRowItemsStartFull);
  final connectorStart = WebElementChrome(
    className: '',
    inlineStyles: buildConnectorHalfInlineStyles(towardsCircleAtEnd: true),
  );
  final connectorEnd = WebElementChrome(
    className: '',
    inlineStyles: buildConnectorHalfInlineStyles(towardsCircleAtEnd: false),
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedStepper(
    root: WebElementChrome(className: buildRootClassName()),
    stepWrappers: stepWrappers,
    indicatorColumns: indicatorColumns,
    indicators: indicators,
    indicatorNumbers: indicatorNumbers,
    contentColumns: contentColumns,
    track: track,
    connectorStart: connectorStart,
    connectorEnd: connectorEnd,
    labels: labels,
    labelSizerActive: labelSizerActive,
    labelSizerInactive: labelSizerInactive,
    labelText: const WebElementChrome(className: _kLabelCell),
    descriptions: descriptions,
    connectorWrappers: connectorWrappers,
    connectorDividerStyles: connectorDividerStyles,
    indicatorIconStyles: indicatorIconStyles,
    clickableStyle: clickableStyle,
    indicatorContentGapStyle: indicatorContentGapStyle,
    labelGapStyle: labelGapStyle,
    descriptionGapStyle: descriptionGapStyle,
  );
}

/// Shared 1×1 grid-cell pin for the label stack layers — every layer
/// (invisible state sizers + visible text) occupies the same cell so
/// the label wrapper sizes to the widest one. Structural layout only,
/// not a design token.
const String _kLabelCell = 'col-start-1 row-start-1';
