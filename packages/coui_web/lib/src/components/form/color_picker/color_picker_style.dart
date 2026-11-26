import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/dashed_overlay.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

const String _kSwatchEdgeVar = '--co-color-picker-edge';
const String _kDisabledSwatchEdgeVar = '--co-color-picker-disabled-edge';
const String _kDisabledSwatchEdgeClass =
    'disabled:[--co-color-picker-edge:var(--co-color-picker-disabled-edge)]';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ColorPicker`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="group">)                       // relative inline-flex wrapper
///   └─ Popover (or bare triggerRow when disabled)
///        ├─ triggerRow (<div role="group">)
///        │    ├─ swatch (<button>)
///        │    ├─ Gap(swatchGapStyle)             // co_color_picker renders only when showLabel || showHexInput
///        │    └─ hexInputWrap (<div> wrapping TextField, optional)
///        └─ popoverContent (<div>)                 // flex flex-col + inline gap = popoverSpacing
///             ├─ optional dialog title
///             ├─ mode tabs                      // composed ToggleGroup (modeTabsStyle)
///             ├─ saturationValueArea (<div>)
///             ├─ hueSlider (<div>)
///             ├─ alphaSlider (<div>)               // co_color_picker renders only when showAlpha
///             ├─ modeInputsRow (<div>)             // flex + inline gap = modeInputSpacing
///             │    ├─ modeInputCell (<div>)
///             │    │    └─ modeInputCellInner (<div>)
///             │    │         ├─ modeInputLabel (<div>)
///             │    │         ├─ Gap(modeInputLabelGapStyle)
///             │    │         └─ TextField
///             │    ├─ modeInputCell (<div>)         // (same nested structure)
///             │    └─ modeInputCell (<div>)         // (same nested structure)
///             ├─ recentColorsGrid (<div>)  // when history exists
///             │    └─ Clickable (role="button") × N  // recentSwatchClickableStyle
///             │         └─ recentSwatch{Unselected,Selected} (<div>)
///             └─ actionRow (<div>)
///                  ├─ eye-dropper Button          // co_color_picker renders only when enableEyeDropper
///                  ├─ actionRowSpacer (<div>)
///                  ├─ Cancel Button
///                  ├─ Gap(actionRowGapStyle)
///                  └─ Save Button
/// ```
///
/// `co_color_picker.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body.
///
/// Per Epic #1603 (옵션 B 최종) the resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets (`Gap`, `Icon`, `TextField`, `Button`, etc.).
///
/// No scalar metadata (sizes / gaps / etc.) is exposed — every numeric
/// value lives inside a [WebElementChrome.inlineStyles] bundle or a
/// nested `CoreXxxStyle` slot.
class ResolvedColorPicker implements WebResolvedChrome {
  /// Creates a [ResolvedColorPicker].
  const ResolvedColorPicker({
    required this.root,
    required this.triggerRow,
    required this.swatch,
    required this.swatchEmpty,
    required this.swatchDashOverlay,
    required this.swatchDashRect,
    required this.hexInputWrap,
    required this.popoverContent,
    required this.modeInputsRow,
    required this.modeInputCell,
    required this.modeInputCellInner,
    required this.modeInputLabel,
    required this.modeInputLabelText,
    required this.recentColorsGrid,
    required this.recentSwatchUnselected,
    required this.recentSwatchSelected,
    required this.saturationValueArea,
    required this.hueSlider,
    required this.hueTrack,
    required this.handle,
    required this.hueHandle,
    required this.alphaSlider,
    required this.actionRow,
    required this.actionRowSpacer,
    required this.swatchGapStyle,
    required this.modeInputLabelGapStyle,
    required this.actionRowGapStyle,
    required this.eyeDropperIconStyle,
    required this.popoverStyle,
    required this.dialogStyle,
    required this.swatchButtonStyle,
    required this.recentSwatchClickableStyle,
    required this.hexInputStyle,
    required this.modeTabsStyle,
    required this.triggerField,
    required this.triggerValue,
    required this.triggerPlaceholder,
    required this.modeHexInputCell,
    required this.recentSection,
    required this.recentTitle,
    required this.compareCell,
    required this.compareSwatch,
    required this.inlineInert,
    required this.triggerChevronIconStyle,
    required this.recentTitleGapStyle,
    required this.inlinePanelStyle,
    @Deprecated(
      'Read by nothing — ColorPicker draws no label (since 0.183). Wrap the '
      'picker in a FormField with a label instead; this goes with '
      'CoreColorPickerStyle.labelStyle.',
    )
    this.labelStyle,
    @Deprecated(
      'Read by nothing — ColorPicker draws no description (since 0.183). Wrap '
      'the picker in a FormField with a description instead; this goes with '
      'CoreColorPickerStyle.descriptionStyle.',
    )
    this.descriptionStyle,
    @Deprecated(
      'Read by nothing — ColorPicker draws no error text (since 0.183). Wrap '
      'the picker in a FormField that shows the error instead; this goes with '
      'CoreColorPickerStyle.errorStyle.',
    )
    this.errorStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="group">` wrapper —
  /// `relative inline-flex items-center` className.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the trigger row `<div role="group">`
  /// (swatch + optional hex input) — `inline-flex items-center`.
  final WebElementChrome triggerRow;

  /// Paint-ready chrome for the trigger swatch `<button>` — width /
  /// height + base Tailwind classes (background-color is merged in at
  /// the call site because it tracks the live `_hexBuffer`).
  final WebElementChrome swatch;

  /// Paint-ready chrome for the hex-input wrapping `<div>` — fixed
  /// width so the TextField does not stretch beyond the swatch.
  final WebElementChrome hexInputWrap;

  /// Paint-ready chrome for the popover content `<div>` — `flex
  /// flex-col` column hosting all picker sections + per-instance width.
  final WebElementChrome popoverContent;

  /// Nested style for the composed mode-tabs `ToggleGroup` — raw-forwarded
  /// (the group's own resolver fills the rest).
  final CoreToggleGroupStyle modeTabsStyle;

  /// Paint-ready chrome for the empty ("no colour") trigger swatch
  /// `<button>` — no fill, no border; the dashed outline is the overlay.
  final WebElementChrome swatchEmpty;

  /// Dashed-outline `<svg>` overlay of the empty swatch.
  final WebElementChrome swatchDashOverlay;

  /// Dashed-outline `<rect>` of the empty swatch.
  final WebElementChrome swatchDashRect;

  /// Paint-ready chrome for the hue bar `<div>` that sits centred inside
  /// the taller [hueSlider] hit box.
  final WebElementChrome hueTrack;

  /// Paint-ready chrome for the round picked-point handle on the
  /// saturation/value area and the hue bar. Position (`left` / `top`) is
  /// merged at the call site since it depends on the live colour.
  final WebElementChrome handle;

  /// Paint-ready chrome for the round handle on the hue bar — its ring and
  /// shadow. The fill (the current colour) and the position (`left` /
  /// `top`) are merged at the call site, as for [handle].
  final WebElementChrome hueHandle;

  /// Paint-ready typography for the channel caption (`R` / `G` / `B`).
  final WebElementChrome modeInputLabelText;

  /// Paint-ready chrome for the numeric mode inputs row `<div>`
  /// (`flex w-full`).
  final WebElementChrome modeInputsRow;

  /// Paint-ready chrome for a single mode input cell `<div>` (`flex-1`)
  /// — repeated three times (one per RGB / HSL / HSV channel).
  final WebElementChrome modeInputCell;

  /// Paint-ready chrome for the inner `<div>` of a mode input cell —
  /// `flex flex-col` so label + TextField stack vertically.
  final WebElementChrome modeInputCellInner;

  /// Paint-ready chrome for the mode input cell label `<div>` —
  /// `text-center leading-none` (collapses the wrapper line-height).
  final WebElementChrome modeInputLabel;

  /// Paint-ready chrome for the recent colours grid `<div>` —
  /// `grid w-full` + per-instance `grid-template-columns` / `gap`.
  final WebElementChrome recentColorsGrid;

  /// Paint-ready chrome for an unselected recent-color swatch's inner
  /// `<div>` (composed inside a `Clickable`) — `transition-shadow ...
  /// hover:ring-1 ...` className plus per-swatch `width` / `height` /
  /// `border-radius` inline-CSS. `co_color_picker` merges the
  /// per-instance `background-color` into `inlineStyles` at the call site;
  /// the interactive chrome (tap / cursor / focus ring) is owned by the
  /// wrapping `Clickable` ([recentSwatchClickableStyle]).
  final WebElementChrome recentSwatchUnselected;

  /// Paint-ready chrome for the currently-selected recent-color swatch's
  /// inner `<div>` — same base as [recentSwatchUnselected] plus the
  /// `ring-2 ring-primary` highlight.
  final WebElementChrome recentSwatchSelected;

  /// Paint-ready chrome for the saturation/value `<div>` — className +
  /// `null` inline styles (the dynamic gradient background is merged in
  /// at the call site since it depends on the live hue).
  final WebElementChrome saturationValueArea;

  /// Paint-ready chrome for the hue slider `<div>` — className + slider
  /// track `height`. The hue gradient is a static constant and the
  /// per-instance `background` value is merged at the call site.
  final WebElementChrome hueSlider;

  /// Paint-ready chrome for the alpha slider `<div>` — className +
  /// slider track `height`. The alpha gradient depends on the live draft
  /// hex so it is merged at the call site.
  final WebElementChrome alphaSlider;

  /// Paint-ready chrome for the action row `<div>` — `flex items-center
  /// w-full`.
  final WebElementChrome actionRow;

  /// Paint-ready chrome for the action row's flexible spacer `<div>`
  /// (`flex-1`) that pushes Cancel / Save to the right edge.
  final WebElementChrome actionRowSpacer;

  /// Nested [CoreGapStyle] for the swatch → hex-input spacer —
  /// forwarded to `Gap(gapStyle: …)`. `co_color_picker` renders the
  /// gap only when `showLabel || showHexInput`.
  final CoreGapStyle swatchGapStyle;

  /// Nested [CoreGapStyle] for the 1-off spacer between a mode input
  /// cell's label and its number field — forwarded to
  /// `Gap(gapStyle: …)`. The label/field stacking is internal to a
  /// single mode input cell (matches Flutter parity).
  final CoreGapStyle modeInputLabelGapStyle;

  /// Nested [CoreGapStyle] for the gap between Cancel / Save buttons
  /// in the action row — forwarded to `Gap(gapStyle: …)`.
  final CoreGapStyle actionRowGapStyle;

  /// Nested [CoreIconStyle] for the eye-dropper button icon —
  /// forwarded to `Icon(iconStyle: …)`.
  final CoreIconStyle eyeDropperIconStyle;

  /// Nested popover style for popover-mode picker —
  /// `CoreColorPickerStyle.defaultPopoverStyle` merged with the per-instance
  /// override, raw-forwarded to `Popover(popoverStyle: …)` as on Flutter.
  final CorePopoverStyle popoverStyle;

  /// Nested dialog style for dialog-mode picker.
  final CoreDialogStyle? dialogStyle;

  /// Nested button style applied to each swatch button.
  final CoreButtonStyle? swatchButtonStyle;

  /// Nested [CoreClickableStyle] for the composed recent-color swatch
  /// `Clickable` — `CoreColorPickerStyle.defaultRecentSwatchClickableStyle`
  /// merged with the per-instance override, raw-forwarded to
  /// `Clickable(clickableStyle:)`.
  final CoreClickableStyle recentSwatchClickableStyle;

  /// Nested text-field style applied to the hex input —
  /// `CoreColorPickerStyle.defaultHexInputStyle` merged with the per-instance
  /// override, raw-forwarded to `TextField(textFieldStyle: …)` as on
  /// Flutter.
  final CoreTextFieldStyle hexInputStyle;

  /// The field-shaped trigger box — swatch, text and chevron in one
  /// outlined field.
  final WebElementChrome triggerField;

  /// The trigger's hex value text (picked colour).
  final WebElementChrome triggerValue;

  /// The trigger's placeholder text (no colour picked).
  final WebElementChrome triggerPlaceholder;

  /// The panel's HEX input cell — wider than a channel cell.
  final WebElementChrome modeHexInputCell;

  /// The recent-colours section — title above the swatches.
  final WebElementChrome recentSection;

  /// The recent-colours title text.
  final WebElementChrome recentTitle;

  /// The inline panel's previous / current comparison cell.
  final WebElementChrome compareCell;

  /// One half of the comparison cell.
  final WebElementChrome compareSwatch;

  /// Wrapper that keeps a disabled inline panel in view but inert.
  final WebElementChrome inlineInert;

  /// Style of the trigger's chevron, raw-forwarded to `Icon`.
  final CoreIconStyle triggerChevronIconStyle;

  /// Gap between the recent-colours title and the swatches.
  final CoreGapStyle recentTitleGapStyle;

  /// Style of the inline presentation's panel box, raw-forwarded to `Popup`.
  final CorePopupStyle inlinePanelStyle;

  /// The deprecated `CoreColorPickerStyle.labelStyle`, carried as is.
  /// Nothing reads it — `ColorPicker` draws no label.
  @Deprecated(
    'Read by nothing — ColorPicker draws no label (since 0.183). Wrap the '
    'picker in a FormField with a label instead; this goes with '
    'CoreColorPickerStyle.labelStyle.',
  )
  final CoreTextStyle? labelStyle;

  /// The deprecated `CoreColorPickerStyle.descriptionStyle`, carried as
  /// is. Nothing reads it — `ColorPicker` draws no description.
  @Deprecated(
    'Read by nothing — ColorPicker draws no description (since 0.183). Wrap '
    'the picker in a FormField with a description instead; this goes with '
    'CoreColorPickerStyle.descriptionStyle.',
  )
  final CoreTextStyle? descriptionStyle;

  /// The deprecated `CoreColorPickerStyle.errorStyle`, carried as is.
  /// Nothing reads it — `ColorPicker` draws no error text.
  @Deprecated(
    'Read by nothing — ColorPicker draws no error text (since 0.183). Wrap '
    'the picker in a FormField that shows the error instead; this goes with '
    'CoreColorPickerStyle.errorStyle.',
  )
  final CoreTextStyle? errorStyle;
}

/// Scoped CSS text for the `<style>` block in `ColorPicker`.
///
/// Non-empty only when a raw (token-less) `borderColor` override moves the
/// recent-swatch hover ring off the Tailwind `ring-*` scale — the recent
/// swatches then carry a `.co-color-picker-sw-<id>` scope class and
/// `resolveColorPicker` drops the `hover:ring-1 hover:ring-*` utility
/// classes (class XOR rule). The scoped rule reproduces the 1px outset
/// hover ring as a `box-shadow`:
/// * `.co-color-picker-sw-<id>:hover{box-shadow: 0 0 0 …rem …}`.
class ResolvedColorPickerRules {
  /// Creates a [ResolvedColorPickerRules].
  const ResolvedColorPickerRules({required this.css});

  /// Raw CSS rule text — empty on the default path (pure utility classes).
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedColorPicker] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design system default (CoreColorPickerStyle.defaultX)
///   → theme.coreComponentTheme.colorPicker.style
///   → widget.colorPickerStyle
/// ```
ResolvedColorPicker resolveColorPicker(
  BuildContext context, {
  required String scopeId,
  CoreColorPickerStyle? colorPickerStyle,
}) {
  final colorPickerTheme = context.theme.coreComponentTheme?.colorPicker;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreColorPickerStyle(), [
    colorPickerTheme?.style,
    colorPickerStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  // Trigger swatch size — nested `swatchButtonStyle.width` slot wins
  // (height tracks width since the swatch is square), else flat
  // `swatchSize`, else design-system default.
  final swatchSize =
      merged.swatchButtonStyle?.width ??
      merged.swatchSize ??
      CoreColorPickerStyle.defaultSwatchSize;
  final hexInputWidth =
      merged.hexInputWidth ?? CoreColorPickerStyle.defaultHexInputWidth;
  final popoverWidth =
      merged.popoverWidth ?? CoreColorPickerStyle.defaultPopoverWidth;
  final sliderHeight =
      merged.sliderHeight ?? CoreColorPickerStyle.defaultSliderHeight;
  final recentSwatchSize =
      merged.recentSwatchSize ?? CoreColorPickerStyle.defaultRecentSwatchSize;
  final recentSwatchSpacing =
      merged.recentSwatchSpacing ??
      CoreColorPickerStyle.defaultRecentSwatchSpacing;
  final recentColumns =
      merged.recentColumns ?? CoreColorPickerStyle.defaultRecentColumns;
  final pickMarkerSize =
      merged.pickMarkerSize ?? CoreColorPickerStyle.defaultPickMarkerSize;

  // Nested CoreGapStyle slots — built once and forwarded to every
  // Gap render site in co_color_picker. Design-system default merged
  // with the per-instance override so each slot is a single, paint-ready
  // CoreGapStyle.
  final swatchGapStyle = CoreColorPickerStyle.defaultSwatchGapStyle.merge(
    merged.swatchGapStyle,
  );
  // Native-API spacing — flows directly into the `flex` parent's CSS
  // `gap` declaration on `popoverContent` / `modeInputsRow`. Per-instance
  // override wins, else the design-system default.
  final popoverSpacing =
      merged.popoverSpacing ?? CoreColorPickerStyle.defaultPopoverSpacing;
  final modeInputSpacing =
      merged.modeInputSpacing ?? CoreColorPickerStyle.defaultModeInputSpacing;
  // 1-off spacer between a mode input cell's label and its number field
  // — design-system default merged with the per-instance override so the
  // Resolved class carries a single paint-ready `CoreGapStyle` that
  // `co_color_picker` raw-forwards to `Gap(gapStyle: …)`.
  final modeInputLabelGapStyle = CoreColorPickerStyle
      .defaultModeInputLabelGapStyle
      .merge(
        merged.modeInputLabelGapStyle,
      );
  final actionRowGapStyle = CoreColorPickerStyle.defaultActionRowGapStyle.merge(
    merged.actionRowGapStyle,
  );

  // Eye-dropper icon style — design-system default (16px) merged with
  // the per-instance override, forwarded to `Icon(iconStyle: …)`
  // inside the action-row eye-dropper button.
  final eyeDropperIconStyle = CoreColorPickerStyle.defaultEyeDropperIconStyle
      .merge(
        merged.eyeDropperIconStyle,
      );

  // Nested Clickable slot for the recent-color swatch — partial default
  // merged with the override, raw-forwarded to `Clickable(clickableStyle:)`.
  final recentSwatchClickableStyle = CoreColorPickerStyle
      .defaultRecentSwatchClickableStyle
      .merge(
        merged.recentSwatchClickableStyle,
      );
  // Hex-input slot — same shape as the Clickable slot above: this
  // component's partial default merged with the caller's override, then
  // raw-forwarded so the `TextField`'s own resolver fills its defaults.
  final hexInputStyle = CoreColorPickerStyle.defaultHexInputStyle.merge(
    merged.hexInputStyle,
  );
  final modeTabsStyle = CoreColorPickerStyle.defaultModeTabsStyle.merge(
    merged.modeTabsStyle,
  );
  // Channel caption typography — `bodySmall` role + `onSurfaceSubtle`
  // colour (Core `defaultModeInputLabelStyle`) merged with the override.
  final modeInputLabelEmit = emitTypography(
    merged.modeInputLabelStyle,
    CoreColorPickerStyle.defaultModeInputLabelStyle,
  );

  // Chrome border colour — routed through the emit family so a raw
  // (token-less) override no longer throws `token!.name`. A design-system
  // token emits the `border-<token>` class (dark-mode reactive,
  // byte-identical to the previous emission); a raw override emits an
  // inline `{border-color: rgb(...)}` bundle instead. The same border
  // colour is shared by the trigger swatch + saturation/value area + hue +
  // alpha slider, so the emit is computed once and its className / inline
  // reused across all four (non-pseudo) elements.
  final borderColor =
      merged.borderColor ?? CoreColorPickerStyle.defaultBorderColor;
  final borderColorEmit = emitColor(
    merged.borderColor,
    CoreColorPickerStyle.defaultBorderColor,
    .border,
  );
  // Border width shared by the trigger swatch + saturation/value area +
  // hue + alpha slider — always inline (`strokeWidthCss`), mirroring
  // `borderColorEmit`'s "computed once, reused across all four" shape.
  final borderWidth =
      merged.borderWidth ?? CoreColorPickerStyle.defaultBorderWidth;
  final borderWidthCss = strokeWidthCss(borderWidth);
  // Recent-colour swatch border widths — unselected vs. selected. The
  // selected ring (`selectedRingColor`, below) stays as the persistent
  // *highlight* indicator; this is the swatch's own resting boundary
  // stroke, same as every other border in this resolver.
  final recentSwatchBorderWidth =
      merged.recentSwatchBorderWidth ??
      CoreColorPickerStyle.defaultRecentSwatchBorderWidth;
  final recentSwatchSelectedBorderWidth =
      merged.recentSwatchSelectedBorderWidth ??
      CoreColorPickerStyle.defaultRecentSwatchSelectedBorderWidth;
  // Disabled trigger border — dedicated `disabledOutline` token (#3469),
  // not the enabled border dimmed by the swatch's own `opacity-50` (which
  // stays: the swatch fill shows an arbitrary user-picked colour with no
  // dedicated "disabled" substitute, the one case design-tokens.md still
  // allows a multiplier for). Token-backed values (the default, and any
  // override) ride the `disabled:border-*` class. If either edge colour
  // is raw, the trigger's inline colour reads a private variable instead:
  // :disabled selects that variable, so an enabled inline raw colour
  // cannot outrank the disabled edge. Both values stay on this button;
  // sibling swatches and the hex input inherit neither value.
  final disabledBorderColor =
      merged.disabledBorderColor ??
      CoreColorPickerStyle.defaultDisabledBorderColor;
  final triggerEdgeUsesVariable =
      borderColor.token == null || disabledBorderColor.token == null;
  final triggerEdgeCss = 'var($_kSwatchEdgeVar, ${borderColor.toValue()})';
  final disabledBorderClass = triggerEdgeUsesVariable
      ? _kDisabledSwatchEdgeClass
      : 'disabled:border-${disabledBorderColor.tailwindColor}';

  // Selected recent-swatch ring colour (non-pseudo persistent ring). A
  // token colour rides `ring-2 ring-<token>` utility classes; a raw
  // override can't, so the ring paints as an inline `box-shadow` on the
  // selected swatch chrome (a persistent ring needs no pseudo-state, so it
  // stays inline — no scoped rule).
  final selectedRingColor =
      merged.selectedRingColor ?? CoreColorPickerStyle.defaultSelectedRingColor;
  final selectedRingRaw = selectedRingColor.token == null;

  // Border-radius chrome — every radius is emitted **inline**
  // (`(merged.X ?? default).toValue()`) so the override path and the
  // default path share one CSS surface (Epic #1603 signature gate —
  // radius is always-inline, never a Tailwind radius class).
  // Swatch corner radius — nested `swatchButtonStyle.borderRadius` slot
  // wins, else flat `swatchBorderRadius`, else design-system default.
  final swatchBorderRadius =
      (merged.swatchButtonStyle?.borderRadius ??
              merged.swatchBorderRadius ??
              CoreColorPickerStyle.defaultSwatchBorderRadius)
          .toValue();
  final saturationValueBorderRadius =
      (merged.saturationValueBorderRadius ??
              CoreColorPickerStyle.defaultSaturationValueBorderRadius)
          .toValue();
  final sliderBorderRadius =
      (merged.sliderBorderRadius ??
              CoreColorPickerStyle.defaultSliderBorderRadius)
          .toValue();
  final recentSwatchBorderRadius =
      (merged.recentSwatchBorderRadius ??
              CoreColorPickerStyle.defaultRecentSwatchBorderRadius)
          .toValue();
  // Handle ring — border-colour emit family + stroke width, like every
  // other border here.
  final handleBorderEmit = emitColor(
    merged.pickMarkerBorderColor,
    CoreColorPickerStyle.defaultPickMarkerBorderColor,
    .border,
  );
  final pickMarkerBorderWidthCss = strokeWidthCss(
    merged.pickMarkerBorderWidth ??
        CoreColorPickerStyle.defaultPickMarkerBorderWidth,
  );
  // Handle shadow — the weakest scale step, via the shared shadow
  // variable so a surface style and the dark strength reach it.
  final pickMarkerShadowCss = emitShadow(
    merged.pickMarkerShadow ?? CoreColorPickerStyle.defaultPickMarkerShadow,
    base: kShadowVariableBase,
  );
  // Hue-bar handle: the current colour (filled at the call site) inside
  // its own ring.
  final hueHandleBorderEmit = emitColor(
    merged.hueMarkerBorderColor,
    CoreColorPickerStyle.defaultHueMarkerBorderColor,
    .border,
  );
  final hueMarkerBorderWidthCss = strokeWidthCss(
    merged.hueMarkerBorderWidth ??
        CoreColorPickerStyle.defaultHueMarkerBorderWidth,
  );
  // Empty swatch: the dashes stroke with `currentColor`, so the border
  // colour rides the text-colour channel (and its disabled tone).
  final emptyDashColorEmit = emitColor(
    merged.borderColor,
    CoreColorPickerStyle.defaultBorderColor,
    .text,
  );
  final emptyDashDisabledClass = triggerEdgeUsesVariable
      ? _kDisabledSwatchEdgeClass
      : 'disabled:text-${disabledBorderColor.tailwindColor}';
  final emptyDashLength =
      merged.emptySwatchDashLength ??
      CoreColorPickerStyle.defaultEmptySwatchDashLength;
  final emptyDashSpacing =
      merged.emptySwatchDashSpacing ??
      CoreColorPickerStyle.defaultEmptySwatchDashSpacing;
  // SVG `rect` takes one uniform `rx`: the canonical top-left scalar.
  final swatchDashRadius =
      (merged.swatchButtonStyle?.borderRadius ??
              merged.swatchBorderRadius ??
              CoreColorPickerStyle.defaultSwatchBorderRadius)
          .topLeft;
  // Swatch / recent-swatch / slider hover-focus colour transition
  // duration — the existing CSS adapter retains arbitrary durations and
  // token remapping. The override wins through merged.transitionDuration.
  final transitionMs =
      (merged.transitionDuration ??
              CoreColorPickerStyle.defaultTransitionDuration)
          .inMilliseconds;
  final transitionDurationCss = durationMsCss(transitionMs);
  // Popover panel chrome is owned by [Popover] (→ `Popup`), the single
  // source of truth for the floating panel box. ColorPicker declares no
  // panel chrome of its own — the panel padding flows from `Popup`'s
  // default (16px, matching the popover panel default) unless the caller
  // overrides it via `colorPickerStyle.popoverStyle.panelStyle`. So the
  // partial default (empty — no divergence) is merged with the override
  // and forwarded raw.
  final resolvedPopoverStyle = CoreColorPickerStyle.defaultPopoverStyle.merge(
    merged.popoverStyle,
  );

  // ─── Field-shaped trigger ─────────────────────────────
  final triggerBackgroundEmit = emitColor(
    merged.triggerBackgroundColor,
    CoreColorPickerStyle.defaultTriggerBackgroundColor,
    .background,
  );
  final triggerBorderEmit = emitColor(
    merged.triggerBorderColor,
    CoreColorPickerStyle.defaultTriggerBorderColor,
    .border,
  );
  final triggerBorderWidthCss = strokeWidthCss(
    merged.triggerBorderWidth ?? CoreColorPickerStyle.defaultTriggerBorderWidth,
  );
  final triggerBorderRadius =
      (merged.triggerBorderRadius ??
              CoreColorPickerStyle.defaultTriggerBorderRadius)
          .toValue();
  // Logical (`padding-inline-*`) when directional, so the start and end
  // follow the document's `dir` like Flutter's `EdgeInsetsDirectional`.
  final triggerPaddingDeclarations =
      (merged.triggerPadding ?? CoreColorPickerStyle.defaultTriggerPadding)
          .toLogicalDeclarations('padding');
  final triggerSpacing =
      merged.triggerSpacing ?? CoreColorPickerStyle.defaultTriggerSpacing;
  final triggerMinWidth =
      merged.triggerMinWidth ?? CoreColorPickerStyle.defaultTriggerMinWidth;
  final triggerValueEmit = emitTypography(
    merged.triggerValueTextStyle,
    CoreColorPickerStyle.defaultTriggerValueTextStyle,
  );
  final triggerPlaceholderEmit = emitTypography(
    merged.triggerPlaceholderTextStyle,
    CoreColorPickerStyle.defaultTriggerPlaceholderTextStyle,
  );
  final triggerChevronIconStyle = CoreColorPickerStyle
      .defaultTriggerChevronIconStyle
      .merge(merged.triggerChevronIconStyle);

  // ─── Panel sections ───────────────────────────────────
  final recentTitleEmit = emitTypography(
    merged.recentTitleTextStyle,
    CoreColorPickerStyle.defaultRecentTitleTextStyle,
  );
  final recentTitleGapStyle = CoreColorPickerStyle.defaultRecentTitleGapStyle
      .merge(merged.recentTitleGapStyle);
  final modeHexInputFlex =
      merged.modeHexInputFlex ?? CoreColorPickerStyle.defaultModeHexInputFlex;

  // ─── Inline presentation ──────────────────────────────
  final compareSwatchSize =
      merged.compareSwatchSize ?? CoreColorPickerStyle.defaultCompareSwatchSize;
  final compareBorderRadius =
      (merged.compareBorderRadius ??
              CoreColorPickerStyle.defaultCompareBorderRadius)
          .toValue();
  final compareBorderEmit = emitColor(
    merged.compareBorderColor,
    CoreColorPickerStyle.defaultCompareBorderColor,
    .border,
  );
  final compareBorderWidthCss = strokeWidthCss(
    merged.compareBorderWidth ?? CoreColorPickerStyle.defaultCompareBorderWidth,
  );
  final inlinePanelStyle = CoreColorPickerStyle.defaultInlinePanelStyle.merge(
    merged.inlinePanelStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the color-picker root `<div>` Tailwind className. Shared
  /// by both the enabled (popover-wrapped) and disabled (inert trigger
  /// only) build branches.
  String buildTriggerFieldClassName() => [
    '${WebLayout.inlineFlexItemsCenter} border',
    triggerBackgroundEmit.className,
    triggerBorderEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  Styles buildTriggerFieldInlineStyles() => .new(
    raw: {
      'min-width': '${triggerMinWidth / kRemDivisor}rem',
      ...triggerPaddingDeclarations,
      'gap': spaceCss(triggerSpacing),
      'border-radius': triggerBorderRadius,
      'border-width': triggerBorderWidthCss,
      ...?triggerBackgroundEmit.inline,
      ...?triggerBorderEmit.inline,
    },
  );

  String buildTriggerTextClassName(Emit emit) => [
    '${WebLayout.flex1} ${WebLayout.minWZero} ${WebLayout.truncate}',
    emit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  String buildRecentSectionClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol}';

  String buildCompareCellClassName() => [
    '${WebLayout.inlineFlex} ${WebLayout.overflowHidden} border',
    compareBorderEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  Styles buildCompareCellInlineStyles() => .new(
    raw: {
      'border-radius': compareBorderRadius,
      'border-width': compareBorderWidthCss,
      ...?compareBorderEmit.inline,
    },
  );

  Styles buildCompareSwatchInlineStyles() => .new(
    raw: {
      'width': '${compareSwatchSize / kRemDivisor}rem',
      'height': '${compareSwatchSize / kRemDivisor}rem',
    },
  );

  String buildRootClassName() =>
      '${WebLayout.relative} ${WebLayout.inlineFlex} ${WebLayout.itemsCenter}';

  /// Trigger row `<div>` className — hosts the swatch + optional hex
  /// input side-by-side.
  String buildTriggerRowClassName() => WebLayout.inlineFlexItemsCenter;

  /// Trigger swatch `<button>` className. Background-color is merged
  /// in at the call site because it tracks the live `_hexBuffer`.
  /// Border colour token is bound to the current color scheme outline.
  /// The corner radius is emitted inline (see [buildSwatchInlineStyles]).
  // The border colour class is dropped when the edge rides the shared
  // variable — that is a colour, not chrome geometry, so it is listed
  // conditionally rather than blanked.
  String buildSwatchClassName() => [
    '${WebLayout.shrinkZero} cursor-pointer',
    'border',
    if (!triggerEdgeUsesVariable) borderColorEmit.className,
    'transition-colors',
    'disabled:cursor-not-allowed disabled:opacity-50',
    disabledBorderClass,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Inline CSS for the trigger swatch — width / height (matches
  /// Flutter logical px) plus the inline corner radius. A raw border-colour
  /// override lands here via [borderColorEmit.inline] (token colours ride
  /// the `border-<token>` class instead).
  Styles buildSwatchInlineStyles() => .new(
    raw: {
      'transition-duration': transitionDurationCss,
      'width': '${swatchSize / kRemDivisor}rem',
      'height': '${swatchSize / kRemDivisor}rem',
      'border-radius': swatchBorderRadius,
      'border-width': borderWidthCss,
      if (triggerEdgeUsesVariable) ...{
        _kDisabledSwatchEdgeVar: disabledBorderColor.toValue(),
        'border-color': triggerEdgeCss,
      } else
        ...?borderColorEmit.inline,
    },
  );

  /// Inline CSS for the hex-input wrapper `<div>` — fixed width.
  Styles buildHexInputWrapInlineStyles() =>
      .new(raw: {'width': '${hexInputWidth / kRemDivisor}rem'});

  /// Popover content `<div>` className — vertical column.
  String buildPopoverContentClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol}';

  /// Inline CSS for the popover content `<div>` — fixed width plus the
  /// vertical `gap` between popover sections (rendered natively by the
  /// `flex flex-col` parent instead of a manual `Gap` interleave).
  /// The popover panel padding is owned by [Popover] (→ `Popup`, via
  /// `popoverStyle.panelStyle.padding`), so this inner column carries no
  /// padding of its own.
  Styles buildPopoverContentInlineStyles() => .new(
    raw: {
      'width': '${popoverWidth / kRemDivisor}rem',
      'gap': spaceCss(popoverSpacing),
    },
  );

  /// Empty ("no colour") swatch className — no fill and no border, the
  /// dashed overlay is the outline. `relative` hosts the overlay; the
  /// dashes stroke with `currentColor`, so the border colour rides the
  /// text-colour channel.
  String buildSwatchEmptyClassName() => [
    '${WebLayout.relative} ${WebLayout.shrinkZero} cursor-pointer',
    if (!triggerEdgeUsesVariable) emptyDashColorEmit.className,
    'transition-colors',
    'disabled:cursor-not-allowed',
    emptyDashDisabledClass,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Inline CSS for the empty swatch — size + radius, transparent fill.
  Styles buildSwatchEmptyInlineStyles() => .new(
    raw: {
      'transition-duration': transitionDurationCss,
      'width': '${swatchSize / kRemDivisor}rem',
      'height': '${swatchSize / kRemDivisor}rem',
      'border-radius': swatchBorderRadius,
      'background-color': 'transparent',
      if (triggerEdgeUsesVariable) ...{
        _kDisabledSwatchEdgeVar: disabledBorderColor.toValue(),
        'color': triggerEdgeCss,
      } else
        ...?emptyDashColorEmit.inline,
    },
  );

  /// Mode inputs row className.
  String buildModeInputsRowClassName() => WebLayout.flexFull;

  /// Inline CSS for the mode inputs row — horizontal `gap` between
  /// RGB / HSL / HSV cells (rendered natively by the `flex` parent
  /// instead of a manual `Gap` interleave).
  Styles buildModeInputsRowInlineStyles() =>
      .new(raw: {'gap': spaceCss(modeInputSpacing)});

  /// Mode input cell className — repeated × 3.
  String buildModeInputCellClassName() => WebLayout.flex1;

  /// Inner `<div>` of a mode input cell.
  String buildModeInputCellInnerClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol}';

  /// Mode input label wrapper className — `text-center leading-none`
  /// collapses the wrapper line-height to keep label-to-field gap
  /// matching Flutter. The caption typography rides the inner span
  /// ([ResolvedColorPicker.modeInputLabelText]).
  String buildModeInputLabelClassName() => 'text-center leading-none';

  /// Recent colours row className — a one-row grid; anything past
  /// [recentColumns] lands in a zero-height auto row and is clipped.
  String buildRecentColorsGridClassName() =>
      '${WebLayout.gridFull} ${WebLayout.overflowHidden}';

  /// Inline CSS for the recent colours row — [recentColumns] fixed-width
  /// columns, a single swatch-high row (further rows collapse to 0) and
  /// the `gap` between swatches.
  Styles buildRecentColorsGridInlineStyles() => .new(
    raw: {
      'grid-template-columns':
          'repeat($recentColumns, ${recentSwatchSize / kRemDivisor}rem)',
      'grid-template-rows': '${recentSwatchSize / kRemDivisor}rem',
      'grid-auto-rows': '0',
      'height': '${recentSwatchSize / kRemDivisor}rem',
      'gap': spaceCss(recentSwatchSpacing),
    },
  );

  /// Recent swatch base className (shared by unselected and selected).
  /// The corner radius is emitted inline (see
  /// [buildRecentSwatchInlineStyles]) — same for the resting-boundary
  /// `border` colour class (the swatch's own stroke, distinct from the
  /// persistent selected-state ring below).
  ///
  /// Hover ring — a design-system token rides the `hover:ring-1
  /// hover:ring-<token>` utility classes; a raw (token-less) override
  /// can't, so the swatch carries a `co-color-picker-sw-<id>` scope class
  /// targeted by the scoped `.co-color-picker-sw-<id>:hover` box-shadow
  /// rule from [resolveColorPickerRules] instead (recent swatches are
  /// repeated → class scoping: one class + one rule).
  String buildRecentSwatchBaseClassName() {
    if (borderColor.token == null) {
      return '${WebLayout.shrinkZero} transition-shadow '
          'border '
          'co-color-picker-sw-$scopeId';
    }
    return '${WebLayout.shrinkZero} transition-shadow '
        'border ${borderColorEmit.className} '
        'hover:ring-1 hover:ring-${borderColor.tailwindColor}';
  }

  /// Recent swatch inline styles — width / height + the inline corner
  /// radius + the resting-boundary border width (`recentSwatchBorderWidth`
  /// unselected, `recentSwatchSelectedBorderWidth` selected — always
  /// inline via `strokeWidthCss`, same as every other border in this
  /// resolver), shared by both states. A raw (token-less) border colour
  /// rides here too (`borderColorEmit.inline`) since the className path
  /// only emits the colour class for a design-system token. Background
  /// colour is merged in at the call site by `co_color_picker`. When
  /// [selectedRingBoxShadow] is set (raw selected-ring override on the
  /// selected swatch), the persistent selection ring paints as an inline
  /// `box-shadow` here (a token ring rides `ring-2 ring-<token>` classes
  /// instead).
  Styles buildRecentSwatchInlineStyles({
    required double borderWidth,
    String? selectedRingBoxShadow,
  }) => .new(
    raw: {
      'transition-duration': transitionDurationCss,
      'width': '${recentSwatchSize / kRemDivisor}rem',
      'height': '${recentSwatchSize / kRemDivisor}rem',
      'border-radius': recentSwatchBorderRadius,
      'border-width': strokeWidthCss(borderWidth),
      ...?borderColorEmit.inline,
      'box-shadow': ?selectedRingBoxShadow,
    },
  );

  /// Saturation/value area `<div>` className. The area draws no border;
  /// the gradient background is clipped by the inline corner radius, and
  /// overflow stays visible so the handle can sit on the edge.
  String buildSaturationValueAreaClassName() =>
      '${WebLayout.relative} ${WebLayout.wFull} ${WebLayout.aspectSquare} '
      'cursor-crosshair';

  /// Inline CSS for the saturation/value area — the inline corner radius.
  /// The dynamic gradient background is merged at the call site.
  Styles buildSaturationValueAreaInlineStyles() =>
      .new(raw: {'border-radius': saturationValueBorderRadius});

  /// Hue slider hit-box `<div>` className — as tall as the handle, the
  /// bar ([buildHueTrackInlineStyles]) is centred inside it.
  String buildHueSliderClassName() =>
      '${WebLayout.relative} ${WebLayout.wFull} cursor-ew-resize';

  /// Inline CSS for the hue slider hit box — the handle's height.
  Styles buildHueSliderInlineStyles() => .new(
    raw: {
      'height': '${math.max(pickMarkerSize, sliderHeight) / kRemDivisor}rem',
    },
  );

  /// Hue bar `<div>` className — centred in the hit box.
  String buildHueTrackClassName() => 'pointer-events-none';

  /// Inline CSS for the hue bar — the 8px track and its corner radius
  /// (the bar draws no border). The gradient is merged at the call site.
  Styles buildHueTrackInlineStyles() => .new(
    raw: {
      'position': 'absolute',
      'left': '0',
      'right': '0',
      'top': '50%',
      'transform': 'translateY(-50%)',
      'box-sizing': 'border-box',
      'height': '${sliderHeight / kRemDivisor}rem',
      'border-radius': sliderBorderRadius,
    },
  );

  /// Picked-point handle `<div>` className — a ring around a disc.
  String buildHandleClassName() =>
      '${WebLayout.absolute} border ${handleBorderEmit.className} '
      'pointer-events-none';

  /// Inline CSS for the handle — `pickMarkerSize` disc centred on its
  /// `left` / `top` (merged at the call site); the disc colour is merged
  /// there too.
  Styles buildHandleInlineStyles() => .new(
    raw: {
      'width': '${pickMarkerSize / kRemDivisor}rem',
      'height': '${pickMarkerSize / kRemDivisor}rem',
      'box-sizing': 'border-box',
      'border-radius': '9999px',
      'border-width': pickMarkerBorderWidthCss,
      'transform': 'translate(-50%, -50%)',
      'box-shadow': pickMarkerShadowCss,
      ...?handleBorderEmit.inline,
    },
  );

  /// Hue-bar handle className — a bordered disc; the white fill rides the
  /// background class (a raw override rides the inline bundle).
  String buildHueHandleClassName() => [
    WebLayout.absolute,
    'border',
    hueHandleBorderEmit.className,
    'pointer-events-none',
  ].where((c) => c.isNotEmpty).join(' ');

  /// Inline CSS for the hue-bar handle — same disc geometry as
  /// [buildHandleInlineStyles] with its own ring and shadow.
  Styles buildHueHandleInlineStyles() => .new(
    raw: {
      'width': '${pickMarkerSize / kRemDivisor}rem',
      'height': '${pickMarkerSize / kRemDivisor}rem',
      'box-sizing': 'border-box',
      'border-radius': '9999px',
      'border-width': hueMarkerBorderWidthCss,
      'transform': 'translate(-50%, -50%)',
      'box-shadow': pickMarkerShadowCss,
      ...?hueHandleBorderEmit.inline,
    },
  );

  /// Alpha slider `<div>` className. The corner radius is emitted inline
  /// (see [buildAlphaSliderInlineStyles]).
  String buildAlphaSliderClassName() =>
      '${WebLayout.wFull} ${WebLayout.overflowHidden}';

  /// Inline CSS for the alpha slider — track height + the inline corner
  /// radius plus a raw border-colour override (token colours ride the
  /// `border-<token>` class instead). The per-instance `background`
  /// gradient is merged at the call site since it tracks the live draft
  /// hex.
  Styles buildAlphaSliderInlineStyles() => .new(
    raw: {
      'height': '${sliderHeight / kRemDivisor}rem',
      'border-radius': sliderBorderRadius,
    },
  );

  /// Action row className — Cancel / Save bottom row.
  String buildActionRowClassName() => WebLayout.flexItemsCenterFull;

  /// Action row spacer className — pushes Cancel / Save to the right.
  String buildActionRowSpacerClassName() => WebLayout.flex1;

  // ─── Compose paint-ready chrome ───────────────────────
  final recentSwatchBase = buildRecentSwatchBaseClassName();
  final recentSwatchInline = buildRecentSwatchInlineStyles(
    borderWidth: recentSwatchBorderWidth,
  );
  // Selected-swatch persistent ring. A design-system token rides the
  // ring-2 utility classes, while a raw override paints as an inline
  // box-shadow on the selected swatch chrome instead. The ring is two
  // logical pixels wide, emitted as an outset box-shadow so it mirrors the
  // Tailwind ring utility it replaces.
  final selectedRingClass = selectedRingRaw
      ? ''
      : ' ring-2 ring-${selectedRingColor.tailwindColor}';
  final recentSwatchSelectedInline = buildRecentSwatchInlineStyles(
    borderWidth: recentSwatchSelectedBorderWidth,
    selectedRingBoxShadow: selectedRingRaw
        ? '0 0 0 ${2 / kRemDivisor}rem ${selectedRingColor.toValue()}'
        : null,
  );
  return ResolvedColorPicker(
    root: WebElementChrome(className: buildRootClassName()),
    triggerRow: WebElementChrome(className: buildTriggerRowClassName()),
    swatchEmpty: WebElementChrome(
      className: buildSwatchEmptyClassName(),
      inlineStyles: buildSwatchEmptyInlineStyles(),
    ),
    swatchDashOverlay: WebElementChrome(
      className: dashedOverlaySvgClassName(),
      inlineStyles: dashedOverlaySvgStyles(),
    ),
    swatchDashRect: WebElementChrome(
      className: '',
      inlineStyles: dashedOverlayRectStyles(
        strokeWidth: borderWidthCss,
        dashLength: emptyDashLength,
        dashGap: emptyDashSpacing,
        radius: swatchDashRadius,
      ),
    ),
    swatch: WebElementChrome(
      className: buildSwatchClassName(),
      inlineStyles: buildSwatchInlineStyles(),
    ),
    hexInputWrap: WebElementChrome(
      className: '',
      inlineStyles: buildHexInputWrapInlineStyles(),
    ),
    popoverContent: WebElementChrome(
      className: buildPopoverContentClassName(),
      inlineStyles: buildPopoverContentInlineStyles(),
    ),
    modeInputsRow: WebElementChrome(
      className: buildModeInputsRowClassName(),
      inlineStyles: buildModeInputsRowInlineStyles(),
    ),
    modeInputCell: WebElementChrome(
      className: buildModeInputCellClassName(),
    ),
    modeInputCellInner: WebElementChrome(
      className: buildModeInputCellInnerClassName(),
    ),
    modeInputLabel: WebElementChrome(
      className: buildModeInputLabelClassName(),
    ),
    modeInputLabelText: WebElementChrome(
      className: modeInputLabelEmit.className,
      inlineStyles: modeInputLabelEmit.inline == null
          ? null
          : .new(raw: modeInputLabelEmit.inline),
    ),
    recentColorsGrid: WebElementChrome(
      className: buildRecentColorsGridClassName(),
      inlineStyles: buildRecentColorsGridInlineStyles(),
    ),
    recentSwatchUnselected: WebElementChrome(
      className: recentSwatchBase,
      inlineStyles: recentSwatchInline,
    ),
    recentSwatchSelected: WebElementChrome(
      className: '$recentSwatchBase$selectedRingClass',
      inlineStyles: recentSwatchSelectedInline,
    ),
    saturationValueArea: WebElementChrome(
      className: buildSaturationValueAreaClassName(),
      inlineStyles: buildSaturationValueAreaInlineStyles(),
    ),
    hueSlider: WebElementChrome(
      className: buildHueSliderClassName(),
      inlineStyles: buildHueSliderInlineStyles(),
    ),
    hueTrack: WebElementChrome(
      className: buildHueTrackClassName(),
      inlineStyles: buildHueTrackInlineStyles(),
    ),
    handle: WebElementChrome(
      className: buildHandleClassName(),
      inlineStyles: buildHandleInlineStyles(),
    ),
    hueHandle: WebElementChrome(
      className: buildHueHandleClassName(),
      inlineStyles: buildHueHandleInlineStyles(),
    ),
    alphaSlider: WebElementChrome(
      className: buildAlphaSliderClassName(),
      inlineStyles: buildAlphaSliderInlineStyles(),
    ),
    actionRow: WebElementChrome(className: buildActionRowClassName()),
    actionRowSpacer: WebElementChrome(
      className: buildActionRowSpacerClassName(),
    ),
    swatchGapStyle: swatchGapStyle,
    modeInputLabelGapStyle: modeInputLabelGapStyle,
    actionRowGapStyle: actionRowGapStyle,
    eyeDropperIconStyle: eyeDropperIconStyle,
    popoverStyle: resolvedPopoverStyle,
    dialogStyle: merged.dialogStyle,
    swatchButtonStyle: merged.swatchButtonStyle,
    recentSwatchClickableStyle: recentSwatchClickableStyle,
    hexInputStyle: hexInputStyle,
    triggerField: WebElementChrome(
      className: buildTriggerFieldClassName(),
      inlineStyles: buildTriggerFieldInlineStyles(),
    ),
    triggerValue: WebElementChrome(
      className: buildTriggerTextClassName(triggerValueEmit),
      inlineStyles: triggerValueEmit.inline == null
          ? null
          : .new(raw: triggerValueEmit.inline),
    ),
    triggerPlaceholder: WebElementChrome(
      className: buildTriggerTextClassName(triggerPlaceholderEmit),
      inlineStyles: triggerPlaceholderEmit.inline == null
          ? null
          : .new(raw: triggerPlaceholderEmit.inline),
    ),
    modeHexInputCell: WebElementChrome(
      className: '',
      inlineStyles: .new(raw: {'flex': '$modeHexInputFlex 1 0%'}),
    ),
    recentSection: WebElementChrome(className: buildRecentSectionClassName()),
    recentTitle: WebElementChrome(
      className: recentTitleEmit.className,
      inlineStyles: recentTitleEmit.inline == null
          ? null
          : .new(raw: recentTitleEmit.inline),
    ),
    compareCell: WebElementChrome(
      className: buildCompareCellClassName(),
      inlineStyles: buildCompareCellInlineStyles(),
    ),
    compareSwatch: WebElementChrome(
      className: WebLayout.shrinkZero,
      inlineStyles: buildCompareSwatchInlineStyles(),
    ),
    inlineInert: const WebElementChrome(className: 'pointer-events-none'),
    triggerChevronIconStyle: triggerChevronIconStyle,
    recentTitleGapStyle: recentTitleGapStyle,
    inlinePanelStyle: inlinePanelStyle,
    modeTabsStyle: modeTabsStyle,
    // The three text slots never had an effect and are deprecated; they
    // are still carried as is until they are removed.
    // ignore: deprecated_member_use
    labelStyle: merged.labelStyle,
    // Deprecated, carried as is — see labelStyle.
    // ignore: deprecated_member_use
    descriptionStyle: merged.descriptionStyle,
    // Deprecated, carried as is — see labelStyle.
    // ignore: deprecated_member_use
    errorStyle: merged.errorStyle,
  );
}

/// Resolves the scoped `<style>` rules for a `ColorPicker` whose raw
/// (token-less) `borderColor` override moves the recent-swatch hover ring
/// off the Tailwind `ring-*` scale — see [ResolvedColorPickerRules].
/// Returns empty CSS on the default path (`resolveColorPicker` keeps the
/// `hover:ring-1 hover:ring-*` utility classes: class XOR rule).
///
/// The merge chain mirrors [resolveColorPicker] exactly so the class-drop
/// condition and the scoped rule always see the same resolved border
/// colour.
ResolvedColorPickerRules resolveColorPickerRules(
  BuildContext context, {
  required String scopeId,
  CoreColorPickerStyle? colorPickerStyle,
}) {
  final colorPickerTheme = context.theme.coreComponentTheme?.colorPicker;
  final merged = resolveStyleChain(const CoreColorPickerStyle(), [
    colorPickerTheme?.style,
    colorPickerStyle,
  ]);

  final buffer = StringBuffer();

  // Recent-swatch hover ring — a raw (token-less) border colour cannot
  // ride `hover:ring-1 hover:ring-<token>`, so it paints via the scoped
  // `.co-color-picker-sw-<id>:hover` box-shadow rule (all swatches share
  // the one colour). `ring-1` = 1px, emitted as an outset box-shadow to
  // mirror Tailwind's `ring` utility (matching the class path it replaces).
  final borderColor =
      merged.borderColor ?? CoreColorPickerStyle.defaultBorderColor;
  if (borderColor.token == null) {
    buffer.write(
      '.co-color-picker-sw-$scopeId:hover'
      '{box-shadow: 0 0 0 ${1 / kRemDivisor}rem ${borderColor.toValue()};}',
    );
  }

  return ResolvedColorPickerRules(css: buffer.toString());
}
