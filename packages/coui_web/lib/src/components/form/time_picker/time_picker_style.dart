library;

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

/// Paint-ready chrome for Web `TimePicker`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // grid wrapper (trigger stack)
///   └─ triggerSurface                       // Popover | <div> (dialog mode)
///        ├─ trigger (read-only TextField, fills the parent)
///        └─ {panel box: Popover→Popup | Dialog}  // single panel box
///             └─ popoverContent (<div>)     // role=dialog; stacks segmentRow over actionRow
///                  ├─ tier pin (<div>)                // TypographyTierScope(desktop)
///                  │    └─ segmentRow (<div>)
///                  │         ├─ segmentField (<div>)        // column: input over label
///                  │         │    ├─ segmentInput (<input>)    // HH / MM / SS
///                  │         │    └─ segmentLabel (<span>)  // Hour / Minute / Second
///                  │         ├─ separator (<div>)           // ':'
///                  │         ├─ Gap (dialogOuterGapStyle) // 12-hour mode only
///                  │         └─ amPmToggle (<div>)          // 12-hour mode only; vertical ToggleGroup
///                  ├─ Gap (actionRowGapStyle)         // segmentRow ↔ actionRow
///                  └─ actionRow (<div>)                // Cancel / Save Buttons
/// ```
///
/// The tier pin is a box-less wrapper
/// (`<div style="display: contents" data-coui-typography-tier="desktop">`)
/// that holds the digits to the desktop tier, so `segmentRow` is not a
/// direct child of `popoverContent`.
///
/// All chrome slot fields are non-null — `co_time_picker` decides
/// whether to render each optional element (separator / AM-PM spacer
/// `Gap` / amPmToggle) based on instance state.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome). Every
///   dimensional value (radius / size / gap / padding) and base colour
///   is emitted inline (`(merged.X ?? default)` — single inline
///   signature); only typography-role + pseudo-state colour classes stay
///   on `className`.
/// * Cat 2 — nested `CoreXxxStyle` slots forwarded to child unified
///   widgets ([popoverStyle] → `Popover.popoverStyle`,
///   [dialogStyle] → `Dialog.dialogStyle`,
///   [amPmToggleStyle] → the AM/PM `ToggleGroup.toggleGroupStyle`,
///   [triggerStyle] → the trigger `TextField.textFieldStyle`,
///   [dialogOuterGapStyle] → `Gap.gapStyle` for the segment ↔ AM/PM
///   gap, [actionRowGapStyle] → `Gap.gapStyle` between the segment
///   row and the action button row) plus the segment-input / label /
///   description / error text-style slots that mirror the Flutter
///   resolver 1:1 (forwarded as-is to the matching child renderers).
///
/// No scalar metadata is exposed — semantic identifiers (`mode` /
/// `use24HourFormat`) and behaviour fields stay on the widget prop.
class ResolvedTimePicker implements WebResolvedChrome {
  /// Creates a [ResolvedTimePicker].
  const ResolvedTimePicker({
    required this.root,
    required this.triggerStyle,
    required this.trailingIconStyle,
    required this.popoverContent,
    required this.segmentRow,
    required this.segmentField,
    required this.segmentInput,
    required this.segmentInputFocused,
    required this.segmentLabel,
    required this.separator,
    required this.amPmToggle,
    required this.actionRow,
    required this.popoverStyle,
    required this.dialogStyle,
    required this.amPmToggleStyle,
    required this.actionButtonStyle,
    required this.dialogOuterGapStyle,
    required this.actionRowGapStyle,
    required this.segmentInputStyle,
    required this.labelStyle,
    required this.descriptionStyle,
    required this.errorStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` grid wrapper that
  /// stacks the trigger row. Layout chrome is state-independent so the
  /// resolver pre-computes the `grid w-full` className once; inline CSS
  /// is `null` because the picker carries no per-instance dimensional
  /// override on the root (callers add their own via the widget `css`
  /// slot).
  @override
  final WebElementChrome root;

  /// Paint-ready trailing (clock) icon style — the trigger's
  /// `trailingIconStyle` override chained onto the design-system default
  /// (16px, placeholder colour). The widget forwards this straight to
  /// `Icon(iconStyle: …)` and never chains a fallback itself.
  final CoreIconStyle trailingIconStyle;

  /// Paint-ready chrome for the popover-content vertical wrapper `<div>`
  /// inside [popoverSurface] (stacks `segmentRow` above `actionRow`).
  final WebElementChrome popoverContent;

  /// Paint-ready chrome for the segment row `<div>` (horizontal flex
  /// holding `segmentField` × N, separator × N-1, optional spacer +
  /// AM/PM column).
  final WebElementChrome segmentRow;

  /// Paint-ready chrome for each segment field wrapper `<div>` (column
  /// holding the `<input>` above the `<span>` label).
  final WebElementChrome segmentField;

  /// Paint-ready chrome for each segment `<input>` (HH / MM / SS) —
  /// typography-role class, radius / size / base colours inline. The edited
  /// segment swaps to [segmentInputFocused]; there is no outer ring.
  final WebElementChrome segmentInput;

  /// [segmentInput] for the segment being edited — same classes, the
  /// `primaryContainer` face, its text colour and the inside border
  /// (`primaryText`, 2px) inline instead of the resting fill and border.
  /// The widget picks it by the segment it tracks as focused — the
  /// element's `focus` / `blur`, so a pointer focus shows it as much as a
  /// keyboard one.
  final WebElementChrome segmentInputFocused;

  /// Paint-ready chrome for each segment label `<span>` (Hour / Minute
  /// / Second) — typography-role className plus the per-instance
  /// margin-top / label-colour inline-CSS bundle.
  final WebElementChrome segmentLabel;

  /// Paint-ready chrome for the `':'` separator `<div>` between
  /// segments — typography-role className plus the per-instance
  /// padding / height / content-colour + flex centring inline-CSS bundle.
  final WebElementChrome separator;

  /// Paint-ready chrome for the AM/PM toggle wrapper `<div>` — holds the
  /// vertical `ToggleGroup`, its top on the segment boxes' top.
  final WebElementChrome amPmToggle;

  /// Paint-ready chrome for the action row `<div>` (horizontal flex
  /// holding Cancel / Save `Button`s, right-aligned). Spacing from
  /// the segment row is rendered as an explicit `Gap` sibling driven
  /// by [actionRowGapStyle] — no inline `margin-top` lives here.
  final WebElementChrome actionRow;

  /// Resolved nested [CoreGapStyle] for the horizontal spacer between
  /// the time segment row and the AM/PM column. Forwarded straight to
  /// `Gap(gapStyle: …)` in 12-hour mode (mirrors the Flutter widget
  /// which inserts the same `Gap` between the segments and
  /// `_AmPmToggle`). Always non-null — pre-merged with
  /// [CoreTimePickerStyle.defaultDialogOuterGapStyle].
  final CoreGapStyle dialogOuterGapStyle;

  /// Resolved nested [CoreGapStyle] for the vertical gap between the
  /// segment row and the action button row inside the picker popover.
  /// Forwarded straight to `Gap(gapStyle: …)` (mirrors the Flutter
  /// widget which inserts the same `Gap` between the inner `Row` and
  /// the action `Row`). Always non-null — pre-merged with
  /// [CoreTimePickerStyle.defaultActionRowGapStyle].
  final CoreGapStyle actionRowGapStyle;

  /// The trigger field's chrome — [CoreTimePickerStyle.defaultTriggerStyle]
  /// with the trigger height, the value / placeholder colours and (for the
  /// deprecated `errorTriggerStyle`) the error edge folded in, then the
  /// per-instance `triggerStyle` on top. Forwarded raw to the composed
  /// read-only `TextField`, which resolves it.
  final CoreTextFieldStyle triggerStyle;

  /// Nested [CorePopoverStyle] for the popover-mode picker — forwarded
  /// to `Popover(popoverStyle: …)`. `null` when the caller did not
  /// supply a popover override.
  final CorePopoverStyle? popoverStyle;

  /// Nested [CoreDialogStyle] for the dialog-mode picker — forwarded
  /// to `Dialog(dialogStyle: …)`. `null` when the caller did not
  /// supply a dialog override.
  final CoreDialogStyle? dialogStyle;

  /// Nested [CoreToggleGroupStyle] of the AM/PM `ToggleGroup` — forwarded
  /// to `ToggleGroup(toggleGroupStyle: …)`.
  final CoreToggleGroupStyle amPmToggleStyle;

  /// Nested button style merged into the Cancel / Save action buttons
  /// (single shared slot, mirroring `CoreDialogStyle.actionButtonStyle`).
  final CoreButtonStyle? actionButtonStyle;

  /// Nested [CoreTextFieldStyle] applied to each hour / minute / second
  /// segment input — mirrors the Flutter resolver slot 1:1. Its
  /// `borderColor` / `valueStyle` overrides are also folded into the
  /// [segmentInput] chrome above. `null` when not overridden.
  final CoreTextFieldStyle? segmentInputStyle;

  /// Label text style (text shown above the trigger) — mirrors the
  /// Flutter resolver slot 1:1. `null` when not overridden.
  final CoreTextStyle? labelStyle;

  /// Description / helper text style — mirrors the Flutter resolver slot
  /// 1:1. `null` when not overridden.
  final CoreTextStyle? descriptionStyle;

  /// Error text style — mirrors the Flutter resolver slot 1:1. `null`
  /// when not overridden.
  final CoreTextStyle? errorStyle;
}

/// Scoped CSS text for the `<style>` block in `TimePicker`.
///
/// Always empty: a hovered segment's state layer rides a marker class and an
/// inline custom property read by one global `ThemeConfig` rule, so no
/// per-instance rule is written any more. Kept for source compatibility.
@Deprecated(
  'No per-instance scoped rules are written any more — the segment hover '
  'state layer is a global rule (since 0.175).',
)
class ResolvedTimePickerRules {
  /// Creates a [ResolvedTimePickerRules].
  @Deprecated('Always empty (since 0.175).')
  const ResolvedTimePickerRules({required this.css});

  /// Raw CSS rule text — always empty.
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTimePicker] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default for time picker
///   → theme.coreComponentTheme.timePicker.style
///   → widget.timePickerStyle
/// ```
ResolvedTimePicker resolveTimePicker(
  BuildContext context, {
  @Deprecated('Ignored — no scoped rule needs an id (since 0.175).')
  String scopeId = '',
  CoreTimePickerStyle? timePickerStyle,
  bool enabled = true,
}) {
  final timePickerTheme = context.theme.coreComponentTheme?.timePicker;
  final scheme = context.theme.colorScheme;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTimePickerStyle(), [
    timePickerTheme?.style,
    timePickerStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly). Radius / size / gap / padding are always emitted inline
  // via `(merged.X ?? default)` — never a radius/padding Tailwind class
  // (single inline signature, Epic #1603 chaining gate).
  final segmentBorderRadius =
      merged.segmentBorderRadius ??
      CoreTimePickerStyle.defaultSegmentBorderRadius;
  // Nested `CoreGapStyle` slots — merge the design-system default with
  // the per-instance override and extract `size` for the inline CSS
  // declarations. Mirrors the Flutter resolver which forwards each slot to
  // `Gap`.
  final segmentSize =
      merged.segmentSize ?? CoreTimePickerStyle.defaultSegmentSize;
  final segmentHeight =
      merged.segmentHeight ?? CoreTimePickerStyle.defaultSegmentHeight;
  final dialogLabelSpacing =
      merged.dialogLabelSpacing ??
      CoreTimePickerStyle.defaultDialogLabelSpacing;
  final dialogOuterGapStyle = CoreTimePickerStyle.defaultDialogOuterGapStyle
      .merge(merged.dialogOuterGapStyle);
  final actionRowGapStyle = CoreTimePickerStyle.defaultActionRowGapStyle.merge(
    merged.actionRowGapStyle,
  );
  final separatorPadding =
      merged.separatorPadding ?? CoreTimePickerStyle.defaultSeparatorPadding;
  final triggerBorderWidth =
      merged.triggerBorderWidth ??
      CoreTimePickerStyle.defaultTriggerBorderWidth;

  // ── Base colours — `(merged.X ?? default).toValue()` inline. Caller
  // override wins, else the design-system default token. `.toValue()`
  // emits `var(--color-<token>)` for tokens / `rgb(...)` for raw ARGB
  // (single inline signature). The segment-input border colour also
  // folds the nested `segmentInputStyle.borderColor` (matches the
  // Flutter widget).
  //
  // A token border rides a class, a raw border goes inline (class XOR
  // inline). The border has no hover step: a hovered segment wears a state
  // layer below instead.
  final segmentBorder = emitColor(
    merged.segmentInputStyle?.borderColor ?? merged.segmentBorderColor,
    CoreTimePickerStyle.defaultSegmentBorderColor,
    .border,
  );
  // Segment hover layer — the state-layer colour at the hover weight,
  // published on the segment box; the shared `ThemeConfig` rule lays it over
  // the tile on `:hover`, whichever face (rest or edited) the tile wears.
  final segmentHoverLayer =
      (merged.segmentStateLayerColor ??
              CoreTimePickerStyle.defaultSegmentStateLayerColor)
          .scaleAlpha(
            (merged.segmentStateLayer ??
                    CoreTimePickerStyle.defaultSegmentStateLayer)
                .hover,
          )
          .toValue();
  final segmentSurfaceColor = scheme
      .resolve(
        merged.segmentSurfaceColor ??
            CoreTimePickerStyle.defaultSegmentSurfaceColor,
      )
      .toValue();
  final segmentContentColor = scheme
      .resolve(
        merged.segmentContentColor ??
            CoreTimePickerStyle.defaultSegmentContentColor,
      )
      .toValue();
  final segmentFocusedSurfaceColor = scheme
      .resolve(
        merged.segmentFocusedSurfaceColor ??
            CoreTimePickerStyle.defaultSegmentFocusedSurfaceColor,
      )
      .toValue();
  final segmentFocusedContentColor = scheme
      .resolve(
        merged.segmentFocusedContentColor ??
            CoreTimePickerStyle.defaultSegmentFocusedContentColor,
      )
      .toValue();
  // The edited segment's inside border — it replaces the resting border on
  // the same `<input>` (box-sizing: border-box, so the tile keeps its size).
  // Inside rather than the kit's outer ring: the segments sit next to each
  // other inside the popover, so a ring outside one would cover its
  // neighbour or be clipped at the popover edge (the Material 3 time input
  // marks its field the same way). The trigger field's ring is another
  // element.
  final segmentFocusedBorderColor =
      (merged.segmentFocusedBorderColor ??
              CoreTimePickerStyle.defaultSegmentFocusedBorderColor)
          .toValue();
  final segmentFocusedBorderWidth = strokeWidthCss(
    merged.segmentFocusedBorderWidth ??
        CoreTimePickerStyle.defaultSegmentFocusedBorderWidth,
  );
  final labelColor = scheme
      .resolve(merged.labelColor ?? CoreTimePickerStyle.defaultLabelColor)
      .toValue();
  // The colon's own role (a weight overlay on `headlineSmall`) and colour —
  // the role rides its class, the weight overlay and the colour go inline.
  final separatorTypography = emitTypography(
    merged.separatorTypography,
    CoreTimePickerStyle.defaultSeparatorTypography,
  );
  final separatorColor =
      (merged.separatorColor ?? CoreTimePickerStyle.defaultSeparatorColor)
          .toValue();
  // ── Typography roles — the default emits a `text-<role>` class; an
  // override suppresses the class so the inline `toInlineCss()` rule
  // wins (card typography model). The segment value role also folds the
  // nested `segmentInputStyle.valueStyle` (matches the Flutter widget).
  // The role string is read off the **default** only (always a
  // `CoreTypography.coui` role) — an arbitrary instance-level override
  // is emitted inline, never reverse-looked-up into a class.
  final valueTypographyOverride =
      merged.segmentInputStyle?.valueStyle ?? merged.valueTypography;
  final helperTypographyOverride = merged.helperTypography;
  final valueTypographyRole =
      CoreTimePickerStyle.defaultValueTypography.tailwindTypographyRole;
  final helperTypographyRole =
      CoreTimePickerStyle.defaultHelperTypography.tailwindTypographyRole;

  // ─── Local builders ───────────────────────────────────

  /// Composes the picker root `<div>` Tailwind className. `grid w-full`
  /// mirrors `DatePicker` so the trigger fills the inline axis
  /// (cross-axis stretch) regardless of how the popover wrapper sizes
  /// its own flex item.
  String buildRootClassName() => WebLayout.grid;

  /// Composes the segment input (HH / MM / SS) Tailwind className —
  /// typography-role class (suppressed on override) + structural border
  /// flag (dropped when [triggerBorderWidth] is overridden — the width
  /// then ships inline) + the border colour token class (a raw border goes
  /// inline) + the hover state-layer marker (the layer colour rides inline,
  /// see [buildSegmentInputInlineStyles]). No ring classes: the edited
  /// segment is marked by its focused face and inside border (inline), not
  /// an outer ring.
  /// `outline-none` stays so the browser's own focus outline does not draw
  /// one. Radius / size / base colours live inline.
  String buildSegmentInputClassName() => <String>[
    'text-center',
    if (merged.triggerBorderWidth == null) 'border',
    segmentBorder.className,
    if (enabled) kStateLayerHoverMarker,
    if (valueTypographyOverride == null) 'text-$valueTypographyRole',
    'outline-none',
  ].where((c) => c.isNotEmpty).join(' ');

  /// Inline CSS for the segment input — border radius / size / base
  /// colours emitted inline via `(merged.X ?? default)` (the border colour
  /// only when it is a raw override — a token rides a class, see
  /// [buildSegmentInputClassName]), plus the nested
  /// `segmentInputStyle.valueStyle` / flat `valueTypography` override
  /// (which wins when the role class is suppressed above). Border width
  /// only ships inline when overridden (else the `border` class above
  /// carries the design-system 1px default — border-width is a CSS
  /// sentinel that stays px-fixed, never rem-scaled, so text-scale
  /// doesn't thicken the stroke).
  Styles buildSegmentInputInlineStyles({required bool focused}) {
    final raw = {
      'border-radius': segmentBorderRadius.toValue(),
      ...?segmentBorder.inline,
      if (enabled) kStateLayerHoverVar: segmentHoverLayer,
      'background-color': focused
          ? segmentFocusedSurfaceColor
          : segmentSurfaceColor,
      'color': focused ? segmentFocusedContentColor : segmentContentColor,
      'width': '${segmentSize / kRemDivisor}rem',
      'height': '${segmentHeight / kRemDivisor}rem',
      if (merged.triggerBorderWidth != null)
        'border-width': strokeWidthCss(triggerBorderWidth),
      if (focused) ...{
        'border-color': segmentFocusedBorderColor,
        'border-width': segmentFocusedBorderWidth,
      },
    };
    final valueOverride = valueTypographyOverride;
    if (valueOverride != null) {
      raw.addAll(valueOverride.toInlineCss());
    }
    return .new(raw: raw);
  }

  /// Composes the segment label (Hour / Minute / Second) Tailwind
  /// className — typography-role class (suppressed on override) only;
  /// margin-top + colour live inline.
  String buildSegmentLabelClassName() => <String>[
    if (helperTypographyOverride == null) 'text-$helperTypographyRole',
  ].join(' ');

  /// Inline CSS for the segment label — margin-top gap + label colour
  /// emitted inline via `(merged.X ?? default)`, plus the
  /// `helperTypography` override typography rules when present. The
  /// `margin-top` derives from the resolved `dialogLabelSpacing` — Web
  /// applies the same uniform spacing as the Flutter `Column.spacing`
  /// between segment field and label sibling pair (N=2).
  Styles buildSegmentLabelInlineStyles() {
    final raw = {
      'margin-top': spaceCss(dialogLabelSpacing),
      'color': labelColor,
    };
    final helperOverride = helperTypographyOverride;
    if (helperOverride != null) {
      raw.addAll(helperOverride.toInlineCss());
    }
    return .new(raw: raw);
  }

  /// Composes the colon separator Tailwind className — the separator's
  /// own typography role class; padding / height / colour live inline.
  String buildSeparatorClassName() => separatorTypography.className;

  /// Inline CSS for the colon separator — horizontal padding + height
  /// (from `segmentHeight` so the glyph centres against the input row) +
  /// the separator colour, plus the role's weight overlay (and any
  /// `separatorTypography` override) from [emitTypography].
  Styles buildSeparatorInlineStyles() => .new(
    raw: {
      'padding': separatorPadding.toValue(),
      'height': '${segmentHeight / kRemDivisor}rem',
      'display': 'flex',
      'align-items': 'center',
      ...?separatorTypography.inline,
      'color': separatorColor,
    },
  );

  /// Composes the popover-content vertical wrapper Tailwind className.
  String buildPopoverContentClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol}';

  /// Composes the segment row horizontal-flex Tailwind className.
  String buildSegmentRowClassName() => WebLayout.flexRowItemsStart;

  /// Composes the per-segment field column-flex Tailwind className.
  String buildSegmentFieldClassName() => WebLayout.flexColItemsCenter;

  /// Composes the AM/PM toggle wrapper Tailwind className — a flex box
  /// holding the vertical `ToggleGroup` (AM above PM). The segment row's
  /// `items-start` puts its top on the segment boxes' top, like the
  /// Flutter row's `crossAxisAlignment: .start`.
  String buildAmPmToggleClassName() => WebLayout.flex;

  /// Composes the action row Tailwind className — right-aligned flex row
  /// holding the Cancel / Save buttons.
  String buildActionRowClassName() =>
      '${WebLayout.flex} ${WebLayout.flexRow} ${WebLayout.justifyEnd} ${WebLayout.itemsCenter}';

  /// Inline CSS for the action row — inner `gap` between Cancel / Save
  /// derived from `separatorPadding` (matches the Flutter action row
  /// spacing). Vertical spacing away from the segment row is rendered
  /// as an explicit `Gap` sibling driven by [actionRowGapStyle], not
  /// inline `margin-top` (parity with the Flutter widget).
  Styles buildActionRowInlineStyles() =>
      .new(raw: {'gap': spaceCss(separatorPadding.left)});

  // ─── Compose paint-ready chrome ───────────────────────
  // The popover panel box (background / border / radius / padding) is the
  // composed `Popup`'s panel, so it flows through the nested
  // `popoverStyle.panelStyle` — `CoreTimePickerStyle.defaultPopoverStyle`
  // carries the TimePicker-specific overrides (radius16 / outlineVariant /
  // padding16) and `Popup` fills the rest. The caller's own `popoverStyle`
  // wins on top.
  final popoverStyle = CoreTimePickerStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );
  // Trailing (clock) icon — the top-level override wins, else the
  // design-system default. Chained here so the widget only renders
  // `resolved.…`.
  // A disabled picker leaves the clock untinted: the trigger field's own
  // disabled foreground applies to the glyph the way it does to the text.
  final trailingIconRung =
      merged.trailingIconStyle ?? CoreTimePickerStyle.defaultTrailingIconStyle;
  final trailingIconStyle = enabled
      ? trailingIconRung
      : trailingIconRung.withoutColor;
  // The trigger field's chrome: the default (pressed-only state layer), then
  // the picker's own decisions — an explicit height, the value / placeholder
  // colours (a disabled picker leaves them to the field's disabled tone) and,
  // for the deprecated `errorTriggerStyle`, its border colour as the field's
  // error edge — then the per-instance `triggerStyle` on top. Mirrors the
  // Flutter resolver 1:1.
  // guard-nested-override: triggerHeight — `merged.triggerHeight` is folded
  // into the field's `height` by `effectiveTriggerStyle`.
  // The value colour, `merged.contentColor`, is folded the same way — into
  // the field's `valueStyle`. The colon in the panel has its own
  // `separatorColor`.
  final triggerStyle = enabled
      ? merged.effectiveTriggerStyle
      : merged.effectiveDisabledTriggerStyle;
  // The am/pm toggle sits on the panel: its track is the slot default's
  // one step up, the rest is the composed ToggleGroup's (raw-forward).
  final amPmToggleStyle = CoreTimePickerStyle.defaultAmPmToggleStyle.merge(
    merged.amPmToggleStyle,
  );
  return ResolvedTimePicker(
    root: WebElementChrome(className: buildRootClassName()),
    triggerStyle: triggerStyle,
    trailingIconStyle: trailingIconStyle,
    popoverContent: WebElementChrome(className: buildPopoverContentClassName()),
    segmentRow: WebElementChrome(className: buildSegmentRowClassName()),
    segmentField: WebElementChrome(className: buildSegmentFieldClassName()),
    segmentInput: WebElementChrome(
      className: buildSegmentInputClassName(),
      inlineStyles: buildSegmentInputInlineStyles(focused: false),
    ),
    segmentInputFocused: WebElementChrome(
      className: buildSegmentInputClassName(),
      inlineStyles: buildSegmentInputInlineStyles(focused: true),
    ),
    segmentLabel: WebElementChrome(
      className: buildSegmentLabelClassName(),
      inlineStyles: buildSegmentLabelInlineStyles(),
    ),
    separator: WebElementChrome(
      className: buildSeparatorClassName(),
      inlineStyles: buildSeparatorInlineStyles(),
    ),
    amPmToggle: WebElementChrome(className: buildAmPmToggleClassName()),
    actionRow: WebElementChrome(
      className: buildActionRowClassName(),
      inlineStyles: buildActionRowInlineStyles(),
    ),
    popoverStyle: popoverStyle,
    dialogStyle: merged.dialogStyle,
    amPmToggleStyle: amPmToggleStyle,
    actionButtonStyle: merged.actionButtonStyle,
    dialogOuterGapStyle: dialogOuterGapStyle,
    actionRowGapStyle: actionRowGapStyle,
    segmentInputStyle: merged.segmentInputStyle,
    labelStyle: merged.labelStyle,
    descriptionStyle: merged.descriptionStyle,
    errorStyle: merged.errorStyle,
  );
}

/// Resolves the scoped `<style>` rules for a `TimePicker`. Always empty — see
/// [ResolvedTimePickerRules].
@Deprecated(
  'No per-instance scoped rules are written any more — the segment hover '
  'state layer is a global rule (since 0.175).',
)
ResolvedTimePickerRules resolveTimePickerRules(
  BuildContext context, {
  required String scopeId,
  CoreTimePickerStyle? timePickerStyle,
}) => const ResolvedTimePickerRules(css: '');
