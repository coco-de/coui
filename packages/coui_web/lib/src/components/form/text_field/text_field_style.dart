import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/internal/input_focus_border_paint.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `TextField`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)
///   ├─ FormLabel (<label>)               // co_text_field renders only when label != null
///   │    │                               // host chrome ← labelHost (margin / cursor)
///   │    │                               // typography ← formLabelStyle (raw-forwarded)
///   │    ├─ label text                   // bare Text — inherits FormLabel's own typography
///   │    └─ (required `*` + its gap are drawn by FormLabel itself)
///   ├─ framedBody                        // wrapped in FocusOutline(focusOutlineStyle)
///   │    affixWrapper (<div>)            // the field's box; padding: vertical + slotted sides
///   │      ├─ leadingSlot (<span>)       // co_text_field renders only when prefix != null
///   │      ├─ input (<input>)
///   │      └─ trailingSlot (<span>)      // co_text_field renders only when suffix != null
///   ├─ description (<p>)                 // co_text_field renders only when description != null && error == null
///   └─ error (<p>)                       // co_text_field renders only when errorText != null
/// ```
///
/// Per Epic #1603 (옵션 B 최종, single inline signature) every chrome
/// value (border radius / padding / row spacing / label bottom padding /
/// description top padding / dimensional constraints / cursor /
/// alignment) is emitted **inline** through
/// `(merged.X ?? CoreTextFieldStyle.defaultX).toValue()` / rem —
/// no class-drop branch decides between a Tailwind utility and an inline
/// rule. Only colour / typography token classes (suppressed → inline
/// when the matching slot field is overridden) and pseudo-state /
/// structural classes remain on the className surface.
///
/// All `WebElementChrome` slots are paint-ready — `co_text_field` reads
/// `resolved.<slot>.className` / `resolved.<slot>.inlineStyles` straight
/// off. The nested [leadingIconStyle] / [trailingIconStyle] /
/// [focusOutlineStyle] slots are forwarded to the child unified widgets
/// (`Icon` / `FocusOutline`). Runtime state (size / expands / hasError)
/// is consumed by the resolver as arguments; the widget re-invokes the
/// resolver every build.
///
/// [affixWrapper] is the field's box: it carries the `surface:content`
/// marker + published fill (`webSurfaceMarkerFor` / `surfaceFillVar`),
/// gated on the same `CoreColor` that decides `background-color` (a raw
/// transparent override drops the pair). The [input] inside paints no box
/// of its own — a native `<input>` is a replaced element and draws no
/// `::after`, so a material's edge band could not land on it.
class ResolvedTextField implements WebResolvedChrome {
  /// Creates a [ResolvedTextField].
  const ResolvedTextField({
    required this.root,
    required this.formLabelStyle,
    required this.labelHost,
    required this.input,
    required this.affixWrapper,
    required this.leadingSlot,
    required this.trailingSlot,
    required this.description,
    required this.error,
    required this.leadingIconStyle,
    required this.trailingIconStyle,
    required this.featureButtonStyle,
    required this.focusOutlineStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` element.
  @override
  final WebElementChrome root;

  /// Nested [CoreFormLabelStyle] slot raw-forwarded to the composed
  /// `FormLabel(formLabelStyle: …)` — carries this field's own
  /// per-instance [CoreTextFieldStyle.labelStyle] override and disabled
  /// tint ([CoreTextFieldStyle.labelDisabledColor]). `FormLabel` owns the
  /// actual per-size typography default (its own `defaultsBySize`); this
  /// field states only the parts `TextField` itself overrides. The
  /// Flutter twin forwards the same slot to its composed `FormLabel`.
  final CoreFormLabelStyle formLabelStyle;

  /// Paint-ready host chrome forwarded to the composed `FormLabel` —
  /// the label→field spacing and the disabled cursor affordance. Both
  /// are layout/behaviour rather than colour, and the Flutter twin
  /// mirrors the spacing half with a `Padding` around its `FormLabel`.
  ///
  /// The required `*` has no slot here on purpose: `FormLabel` draws it,
  /// so a `requiredMark` slot would be a second source for a colour
  /// (`error`) that `CoreFormLabelStyle.defaultRequiredColor` already
  /// owns.
  final WebElementChrome labelHost;

  /// Paint-ready chrome for the `<input>` element (className + inline
  /// padding / caret / cursor / dimensional constraints).
  final WebElementChrome input;

  /// Paint-ready chrome for the wrapper `<div>` that is the field's box —
  /// border, fill, material and the row holding the prefix / input /
  /// suffix.
  final WebElementChrome affixWrapper;

  /// Paint-ready chrome for the prefix `<span>` slot — carries the
  /// resolved leading-icon size / colour inline.
  final WebElementChrome leadingSlot;

  /// Paint-ready chrome for the suffix `<span>` slot — carries the
  /// resolved trailing-icon size / colour inline.
  final WebElementChrome trailingSlot;

  /// Paint-ready chrome for the description `<p>`.
  final WebElementChrome description;

  /// Paint-ready chrome for the error `<p>`.
  final WebElementChrome error;

  /// Nested `CoreIconStyle` slot — forwarded to `Icon(iconStyle: …)`
  /// when the prefix is a `Icon`. Carries the resolved icon size and
  /// (when overridden) colour.
  final CoreIconStyle leadingIconStyle;

  /// Nested `CoreIconStyle` slot — forwarded to `Icon(iconStyle: …)`
  /// when the suffix is a `Icon`. Carries the resolved icon size and
  /// (when overridden) colour.
  final CoreIconStyle trailingIconStyle;

  /// Nested `CoreButtonStyle` slot for the input-feature affordance
  /// buttons (clear / password toggle) — design default merged with the
  /// per-instance override, raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)`. `Button` resolves
  /// its own chrome (theme-free — no `scheme.resolve`).
  final CoreButtonStyle featureButtonStyle;

  /// Nested `CoreFocusOutlineStyle` slot — forwarded straight to
  /// `FocusOutline(focusOutlineStyle: …)`. Carries the resolved ring
  /// colour / width / offset / offset-background.
  final CoreFocusOutlineStyle focusOutlineStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry points
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTextField] for a `TextField` (Web).
///
/// Merge chain:
///
/// ```text
/// design system default for variant
///   → theme.coreComponentTheme.textField.style
///   → theme.coreComponentTheme.textField.variantStyles[variant]
///   → widget.textFieldStyle
/// ```
///
/// [expands] / [hasError] are per-render inputs from
/// `co_text_field.build`. [hasError] selects the
/// [CoreTextFieldVariant] (idle vs error variant chrome) keying
/// [CoreTextFieldStyle.defaultsByVariant] and the Theme `variantStyles`
/// override — only while [enabled] (`disabled > error`, asked of
/// [CoreTextFieldVariant.of]); the rest drive the input's per-instance
/// flex / border suppression. The gate is box chrome only: the error
/// message style of a disabled field with an error still reads the Theme
/// `variantStyles[error]` row.
///
/// [leadingAffixed] / [trailingAffixed] say whether the box's row has a
/// slot (prefix / suffix / feature button) on that side. The field's inset
/// is the row's, as on Flutter, whose padding wraps prefix + input +
/// suffix: a side that carries a slot takes its inset on the wrapper so
/// the slot sits inside it, a side without one keeps it on the `<input>`
/// (the text lands in the same place and the inset stays clickable).
ResolvedTextField resolveTextField(
  BuildContext context, {
  required CoreComponentSize size,
  required bool expands,
  required bool hasError,
  required bool enabled,
  required String scopeId,
  bool leadingAffixed = false,
  bool trailingAffixed = false,
  bool numeric = false,
  CoreTextFieldVariant? variant,
  bool? showCursor,
  CoreEdgeInsets scrollPadding = CoreTextFieldContract.defaultScrollPadding,
  CoreTextFieldStyle? textFieldStyle,
}) {
  final fieldTheme = context.theme.coreComponentTheme?.textField;

  // Error axis → semantic variant, with `disabled > error` asked of the
  // Core single source (`CoreTextFieldVariant.showsErrorChrome`) rather
  // than spelled here. On Web the order matters past the variant rows'
  // agreeing disabled tokens: `disabled:*` only reaches the `<input>`,
  // while the affix wrapper's `border-*` class and an inline
  // `errorBorderColor` / Theme `variantStyles[error]` override would
  // paint past it.
  final showsError = CoreTextFieldVariant.showsErrorChrome(
    hasError: hasError,
    enabled: enabled,
  );
  final effectiveVariant = CoreTextFieldVariant.of(
    hasError: hasError,
    enabled: enabled,
    variant: variant,
  );

  // The error message is content, not box chrome: the widget shows it
  // whenever `errorText` is set, disabled or not. So a disabled field with
  // an error steps its chrome off the Theme `error` row, but the message
  // keeps reading that row — only the row's two message fields join the
  // chain, above the chrome row and below the instance override. Enabled,
  // the whole row is already in the chain as `effectiveVariant`.
  final errorMessageRow = hasError && !showsError
      ? (fieldTheme?.variantStyles?[CoreTextFieldVariant.error])
      : null;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTextFieldStyle(), [
    fieldTheme?.style,
    fieldTheme?.variantStyles?[effectiveVariant],
    if (errorMessageRow != null)
      CoreTextFieldStyle(
        errorStyle: errorMessageRow.errorStyle,
        errorColor: errorMessageRow.errorColor,
      ),
    textFieldStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final vs = CoreTextFieldStyle.defaultsByVariant[effectiveVariant]!;
  final ss = resolveSizeRow(CoreTextFieldStyle.defaultsBySize, size);
  // A retiring size renders as before; a run with asserts on logs it once
  // (asserts stripped: nothing), so the caller hears before the step goes.
  noticeRetiringSize(
    component: 'TextField',
    size: size,
    retiring: CoreTextFieldContract.retiringSizes,
  );

  // ─── Resolved chrome values (single inline signature) ──
  // Every dimensional / radius / spacing value below is
  // `(merged.X ?? <size|default>)` and is emitted inline via
  // `.toValue()` / rem — no class-drop branch.
  // Height mirrors Flutter: a stated `height` fixes the box; otherwise
  // padding + line box size it (a one-line field holds no vertical
  // padding, `CoreTextFieldStyle.contentPadding`), floored at the size row's
  // control height
  // (`CoreTextFieldStyle.boxMinHeight`, the same rule Flutter reads).
  // Chromeless compositions (the ChipInput entry, the PhoneInput number
  // field) state `minHeight: 0`, so the floor never pins them at a full
  // field.
  final inputHeight = merged.height;
  final boxMinHeight = CoreTextFieldStyle.boxMinHeight(
    height: merged.height,
    minHeight: merged.minHeight,
    maxHeight: merged.maxHeight,
    sizeFloor: ss.minHeight,
  );
  // The floor goes on the element that draws the boundary — the wrapper
  // (the input inside is borderless, so a floor on it would land the
  // wrapper two border widths above the Flutter box, whose constraint
  // includes its border).
  //
  // With no stated height or minimum the floor is the size row's control
  // height, a row of the control ladder: it goes out as the row variable so
  // a density moves it, and a stated maximum caps it in CSS `min()` — the
  // moved floor capped, which is what Flutter computes. A caller's own
  // minimum stays as stated.
  final fromRow = merged.minHeight == null && merged.height == null;
  final rowFloorCss = ss.minHeight == null
      ? null
      : controlHeightCss(ss.minHeight!);
  final boxMinHeightCss = boxMinHeight == null || boxMinHeight <= 0
      ? null
      : !fromRow || rowFloorCss == null
      ? '${boxMinHeight / kRemDivisor}rem'
      : merged.maxHeight == null
      ? rowFloorCss
      : 'min($rowFloorCss, ${merged.maxHeight! / kRemDivisor}rem)';
  // The variant's own horizontal inset — `null` on the boxed variants
  // (they keep the size table's inset), `0` on `plain` (no box of its
  // own, so the text starts flush like the label above it). Applied
  // only when the caller states no explicit `padding` override.
  // A one-line field on its row is held at the row's height with the line
  // centred, so the row's vertical padding does not size it
  // (`CoreTextFieldStyle.contentPadding`, shared with Flutter). The Web
  // field is always an `<input>`; only `expands` lets it grow.
  final sizePaddingCore = CoreTextFieldStyle.contentPadding(
    statedPadding: merged.padding,
    rowPadding: ss.padding!,
    singleLine: !expands,
    height: merged.height,
    minHeight: merged.minHeight,
  );
  final paddingCore = merged.padding == null && vs.horizontalPadding != null
      ? sizePaddingCore.copyWith(
          left: vs.horizontalPadding,
          right: vs.horizontalPadding,
        )
      : sizePaddingCore;
  // Where the inset lands. Flutter wraps the whole row (prefix + input +
  // suffix) in it, so a slot sits inside the inset, not on the border.
  // The wrapper is the box: it takes the vertical inset and the inset of
  // each side that carries a slot; the `<input>` keeps the inset of a side
  // without one, which puts the text in the same place and keeps that strip
  // a click target of the input.
  final wrapperPaddingCore = paddingCore.copyWith(
    left: leadingAffixed ? paddingCore.left : 0,
    right: trailingAffixed ? paddingCore.right : 0,
  );
  final inputPaddingCore = paddingCore.copyWith(
    top: 0,
    bottom: 0,
    left: leadingAffixed ? 0 : paddingCore.left,
    right: trailingAffixed ? 0 : paddingCore.right,
  );
  final inputPadding = inputPaddingCore.toValue();
  final wrapperPadding = wrapperPaddingCore.toValue();
  final inputBaseTextStyle = merged.baseTextStyle ?? ss.baseTextStyle!;
  // Field corner — the per-instance override wins, else the size row's
  // corner (the control height × 0.25, the same value a `Button` of this
  // size takes).
  final borderRadiusCore = merged.borderRadius ?? ss.borderRadius!;
  final borderRadius = borderRadiusCore.toValue();
  // The `lg` rung and above state their own label / helper gaps (#5747).
  final labelPaddingCore =
      merged.labelPadding ??
      ss.labelPadding ??
      CoreTextFieldStyle.defaultLabelPadding;
  final labelPaddingCss = labelPaddingCore.toValue();
  final descriptionPaddingCore =
      merged.descriptionPadding ??
      ss.descriptionPadding ??
      CoreTextFieldStyle.defaultDescriptionPadding;
  final descriptionPaddingCss = descriptionPaddingCore.toValue();
  final rowSpacingCss = spaceCss(
    merged.rowSpacing ?? CoreTextFieldStyle.defaultRowSpacing,
  );
  // Behaviour value in, CSS out: the scroll-into-view inset arrives from
  // `TextField.scrollPadding` (Web uses CSS px 1:1, so the only step is
  // the shorthand emit).
  final scrollPaddingCss = scrollPadding.toValue();
  final cursorWidth =
      merged.cursorWidth ?? CoreTextFieldStyle.defaultCursorWidth;
  final cursorWidthRem = '${cursorWidth / kRemDivisor}rem';
  // Cursor corner radius — uniform caret, emitted as a single rem
  // value (`uniformRem` reads the top-left corner in the adapter, not
  // here, so the resolver stays reach-in-free).
  final cursorRadiusRem =
      (merged.cursorRadius ?? CoreTextFieldStyle.defaultCursorRadius)
          .uniformRem;
  // Field border stroke — the boundary's own width, not the focus ring's.
  // Inline via `strokeWidthCss` so a token width routes through
  // `--coui-stroke-width-N` and a stroke-bending preset reaches it; the
  // bare `border` class the variant table adds carries the border *style*
  // and is what an off-token width overrides.
  final borderWidthCss = strokeWidthCss(
    merged.borderWidth ?? CoreTextFieldStyle.defaultBorderWidth,
  );
  // Active boundary (focus / error) — the part of the active width beyond the
  // resting border, drawn as an inset shadow so the content does not move.
  // The resting `border` stays in the layout (and keeps a forced-colours
  // boundary alive: a shadow is not drawn in that mode, a border is). The
  // error variant is a build-time state, so its shadow rides the element
  // inline; the focus half is a pseudo-state, so the box publishes its layer
  // on `kActiveBoundaryVar` and carries the marker the shared `ThemeConfig`
  // rule reads on focus. Both read the one width rule below.
  final activeInsetCss = _activeBoundaryInset(
    variant: effectiveVariant,
    rest: merged.borderWidth ?? CoreTextFieldStyle.defaultBorderWidth,
    active:
        merged.activeBorderWidth ?? CoreTextFieldStyle.defaultActiveBorderWidth,
  );

  // Icon size — leading / trailing per-site slot size wins, else the
  // shared `iconStyle` slot, else the per-size default. Mirrors the
  // Flutter resolver's icon-size resolution order.
  final iconSize =
      merged.leadingIconStyle?.size ??
      merged.trailingIconStyle?.size ??
      merged.iconStyle?.size ??
      ss.iconStyle!.size!;
  // Nested icon-style slots — design-default size merged with the
  // per-instance override, forwarded to `Icon(iconStyle: …)`.
  final leadingIconStyle = CoreIconStyle(
    size: iconSize,
  ).merge(merged.leadingIconStyle);
  final trailingIconStyle = CoreIconStyle(
    size: iconSize,
  ).merge(merged.trailingIconStyle);

  // Feature affordance (clear / password toggle) button chrome — design
  // default, then the size row's own slot (the row's corner, so the
  // affordance is never rounder than the field around it), then the
  // per-instance override; raw-forwarded to
  // `Button(variant: .plain, buttonStyle: …)`. `Button` resolves its
  // own chrome (theme-free — no `scheme.resolve`).
  final featureButtonStyle = CoreTextFieldStyle.defaultFeatureButtonStyle
      .merge(ss.featureButtonStyle)
      .merge(merged.featureButtonStyle);

  // Per-instance chrome colours — emitted inline (single inline
  // signature). Stage2 EMIT (Web, theme-free) — `.toValue()` emits the
  // token's `var(--coui-X)` (or raw rgba); no `scheme.resolve` (a no-op
  // on Web). `errorBorderColor` wins over `borderColor` when the field
  // is in error state (mirrors the contract's error-border slot).
  final filled = merged.backgroundColor != null;
  final backgroundOverride = merged.backgroundColor?.toValue();
  // surface:content — the field draws its own box on the wrapper rather
  // than composing `OutlinedContainer`, so the marker is restated on the
  // element that actually paints the fill. The design default always
  // states a solid `surface` token, so the pair applies unconditionally
  // unless the caller explicitly opted out with a raw transparent override
  // — same gate every other content-role surface on this axis uses.
  final containerFillCore = merged.backgroundColor ?? vs.backgroundColor;
  final effectiveBorderColor = showsError
      ? (merged.errorBorderColor ?? merged.borderColor)
      : merged.borderColor;
  final borderOverride = effectiveBorderColor?.toValue();
  // The error variant's active boundary, as the inset layer it is drawn with.
  // Absent while the field does not wear the error variant, the active width
  // adds nothing, or the boundary is transparent (a chromeless composition
  // states a transparent border and has no boundary to widen).
  // An error edge rests at the resting width (#5747) and widens only while
  // focused — the focused layer below carries it, in the error variant's own
  // focus colour — so the inline error layer is gone.
  // The focused boundary, as the inset layer the shared rule paints on
  // focus. Absent while the field shows the error chrome (its boundary is
  // already the inline one above), while it is disabled (it cannot take
  // focus), when the active width adds nothing, and when the focus colour
  // paints nothing. The gate is the Core question the inline shadow asks
  // (`showsErrorChrome`), not the row's name: a caller who states
  // `variant: error` without an error still takes the focused boundary, as
  // the Flutter twin's does.
  final focusBoundaryShadow = !enabled
      ? null
      : activeBoundaryLayerCss(
          inset: activeInsetCss,
          color: merged.focusBorderColor ?? vs.focusRingColor,
        );
  // Focus wins over a stated resting/error edge, as in the Flutter state
  // ladder. That edge is inline on this same box, so only this path needs
  // the shared important reader. Ordinary raw focus colours use its normal
  // counterpart; neither path depends on an added shadow width.
  final focusBorderInlineCompetition = enabled && borderOverride != null;
  final rawFocusBorder =
      enabled &&
      merged.focusBorderColor != null &&
      merged.focusBorderColor!.token == null;
  final focusBorderColor =
      (merged.focusBorderColor ??
              (focusBorderInlineCompetition ? vs.focusRingColor : null))
          ?.toValue();
  final cursorColor = merged.cursorColor?.toValue();
  // Idle (floating) cursor colour — a Flutter `EditableText` concern the
  // browser has no surface for (a native `<input>` has no floating
  // cursor). Surfaced only when the caller overrides it, as a
  // `--coui-caret-background-color` custom property, so the resolved
  // intent reaches the DOM for tooling / Flutter parity while the browser
  // ignores it exactly like `--coui-caret-width` / `--coui-caret-radius`.
  // Theme-free value so dark mode tracks at runtime; the default path
  // emits nothing so the default output stays unchanged.
  final backgroundCursorColorCss = merged.backgroundCursorColor?.toValue();
  // Token colours keep their existing class path unless an inline resting
  // edge competes. Raw colours, including transparent, tint the actual
  // wrapper through its marker and existing instance variable.
  final focusWithinBorderClass = focusBorderInlineCompetition
      ? kInputFocusBorderInlineMarker
      : rawFocusBorder
      ? kInputFocusBorderWithinMarker
      : switch (merged.focusBorderColor) {
          null when vs.focusRingColor.isTransparent => '',
          null => 'focus-within:border-${vs.focusRingColor}',
          final override when override.isTransparent => '',
          final override when override.token != null =>
            'focus-within:border-${override.tailwindColor}',
          _ => '',
        };
  // Hover border — the same shape as the focus tint above: the variant's
  // hover step (`outline` → `on-surface`; `error` restates `error`)
  // or the per-instance override when it is a token. A variant that
  // states no hover border (`plain`) keeps its resting border, and a raw
  // override has no class to ride, so it emits nothing rather than a
  // wrong token. `hover:` sits below `disabled:` in the cascade and
  // `disabled:pointer-events-none` keeps the pointer off anyway, so the
  // disabled trio outranks it — `disabled > error > hover`.
  //
  // The wrapper takes focus through `focus-within:`, which Tailwind emits
  // BEFORE `hover:` — at the same specificity a plain `hover:` class would
  // beat the focus tint while the pointer sits over a focused field. The
  // hover step therefore excludes focus in the selector itself
  // (cascade-order independent), which is the Flutter ladder:
  // `focus > hover > rest`.
  final hoverBorderWithinClass = switch (merged.hoverBorderColor) {
    null when vs.hoverBorderColor == null => '',
    null =>
      '${WebPseudo.hoverUnlessFocusWithin.classPrefix}border-'
          '${vs.hoverBorderColor!.tailwindColor}',
    final override when override.isTransparent => '',
    final override when override.token != null =>
      '${WebPseudo.hoverUnlessFocusWithin.classPrefix}border-'
          '${override.tailwindColor}',
    _ => '',
  };

  // Focus outline — design-default slot merged with the per-instance
  // override, then the field border radius + the variant's focus-ring
  // colour token baked on (Flutter twin's bake — the error variant's
  // ring goes error-toned instead of staying on the default ring
  // colour). Forwarded whole to `FocusOutline(focusOutlineStyle: …)`,
  // which is the field's one ring: it paints the ring inline (an
  // `outline`, plus a gap-band `box-shadow` only when a band is stated),
  // which takes fractional widths and raw colours — neither of which a
  // Tailwind utility step can carry.
  //
  // Both baked fields are written *under* the caller's slot. `copyWith`
  // passes any non-null argument through, and neither argument here can
  // be null on its own (`focusRingColor` is a non-nullable variant field,
  // `borderRadiusCore` ends in `?? default`) — so stating them unguarded
  // overwrote whatever the merge above had just carried in, and a
  // `focusOutlineStyle.borderColor` / `.borderRadius` the caller wrote
  // never reached the ring. The Web `text_area` twin already states its
  // two the same way round.
  //
  // The guards read the *pre-merge* `merged.focusOutlineStyle`, not the
  // merged slot: `defaultFocusOutlineStyle` already states a non-null
  // `borderColor`, so a post-merge read is never null and the variant
  // tone below it would become unreachable — an invalid field would stop
  // ringing error.
  final focusOutlineStyle = CoreTextFieldStyle.defaultFocusOutlineStyle
      .merge(merged.focusOutlineStyle)
      .copyWith(
        borderRadius:
            merged.focusOutlineStyle?.borderRadius ?? borderRadiusCore,
        borderColor:
            merged.focusOutlineStyle?.borderColor ??
            merged.focusBorderColor ??
            vs.focusRingColor,
      );

  // Transition + file-label weight — flat instance fields override the
  // design defaults.
  final transitionDurationMs =
      (merged.transitionDuration ??
              CoreTextFieldStyle.defaultTransitionDuration)
          .inMilliseconds;
  final fileLabelFontWeight =
      merged.fileLabelFontWeight ??
      CoreTextFieldStyle.defaultFileLabelFontWeight;

  // Horizontal text alignment — `text-align` keyword; emitted inline.
  final textAlignCss = (merged.textAlign ?? CoreTextFieldStyle.defaultTextAlign)
      .toValue();
  // Vertical alignment of the prefix / input / suffix row → CSS
  // `align-items` keyword. Vertical alignment of the text within the
  // input → `vertical-align` keyword. Both emitted inline.
  final crossAxisAlignCss =
      (merged.crossAxisAlignment ??
              CoreTextFieldStyle.defaultCrossAxisAlignment)
          .alignItemsValue;
  final textAlignVerticalCss =
      (merged.textAlignVertical ?? CoreTextFieldStyle.defaultTextAlignVertical)
          .verticalAlignValue;

  // Slot text styles — every slot shares the size-table `baseTextStyle`
  // token then layers its own override, matching the Flutter resolver
  // 1:1 (Flutter-first: all slots use the size-aware base rather than a
  // per-slot role). `emitTypography` emits the role class + any explicit
  // overlay inline in one decision (no hand-rolled `.token!.name` class).
  //
  // `inputBaseTextStyle` itself — not a `CoreTextStyle.token(...)`
  // reconstructed from just its `.token` field. That constructor zeroes
  // every overlay field (`text_style_token.dart`'s token-only ctor), so
  // rebuilding from `.token!` alone silently drops whatever overlay the
  // size table's `baseTextStyle` already carries (e.g. `md`'s
  // `lineHeight` overlay, tighter than the role's own reading leading)
  // — the base level renders at the role default instead, independent
  // of `merged.valueStyle`. `copyWith` preserves
  // `.token` through overlays, so passing the already-composed style
  // straight through keeps both the token (for the role class) and its
  // overlay (for the inline emit) — matching the Flutter resolver's
  // `baseTextStyle.merge(merged.valueStyle)`, which merges onto the
  // composed style rather than a reconstructed bare token.
  final baseCore = inputBaseTextStyle;

  // Stage2 EMIT — role class + explicit-overlay inline, theme-free.
  // `emitTypography(override, baseCore)` resolves `baseCore.merge
  // (override)`, emitting the size-base role class plus any explicit
  // scalar / raw-colour overlay inline (matching the Flutter resolver's
  // per-slot merge 1:1).
  final valueEmit = _emitInputTypography(merged.valueStyle, baseCore);
  final placeholderTypography = _placeholderTypography(merged, size);
  // Label typography is NOT derived from `baseCore` — a composed
  // `FormLabel` owns the label's own per-size ladder (its own
  // `defaultsBySize`, split at a different rung than the value ladder
  // above). `labelStyle` / `labelDisabledColor` are raw-forwarded whole
  // into `FormLabel`'s nested style slot (child-component-composition)
  // rather than merged in here.
  final labelDisabledColor =
      merged.labelDisabledColor ?? CoreTextFieldStyle.defaultLabelDisabledColor;
  final formLabelStyle = CoreFormLabelStyle(
    labelStyle: merged.labelStyle,
    disabledColor: labelDisabledColor,
  );
  // Description / error are size-INVARIANT (`bodyXs`, the canvas
  // states the same 12px on every rung) — merged onto their own flat
  // defaults, not `baseCore`, so they stop drifting with the value ladder
  // above them.
  // The helper role steps up on the `lg` rung and above (#5747): the size
  // row's role is the default the instance override lands on.
  final descriptionEmit = emitTypography(
    merged.descriptionStyle,
    ss.descriptionStyle ?? CoreTextFieldStyle.defaultDescriptionStyle,
  );
  final errorEmit = emitTypography(
    merged.errorStyle,
    ss.errorStyle ?? CoreTextFieldStyle.defaultErrorStyle,
  );
  // Affix text — the size base with no per-slot override (there is no
  // `affixStyle`; the slot's colour is `affixColor`, emitted as its own
  // class below).
  final affixEmit = emitTypography(null, baseCore);

  // Placeholder colour — slot override or variant default. `::placeholder`
  // is a pseudo-element, so no inline style can reach it: a token rides the
  // `placeholder:text-*` class, and a raw (token-less) colour — a composing
  // parent such as `PhoneInput` forwards whatever its caller wrote — has no
  // class and paints through a scoped rule keyed on the input's scope class
  // instead (see [resolveTextFieldRules]). Class XOR rule.
  final placeholderPseudo = emitPseudoColor(
    merged.placeholderStyle?.color,
    vs.placeholderColor,
    .text,
    pseudo: .placeholder,
    scopeSelector: '.${_placeholderScopeClass(scopeId)}',
  );

  // Slot colour fallbacks (single source — `CoreTextFieldStyle.defaultX`
  // tokens / variant table) used when no per-slot colour override is set.
  final descriptionColor =
      merged.descriptionStyle?.color ??
      merged.descriptionColor ??
      CoreTextFieldStyle.defaultDescriptionColor;
  final affixColor = merged.affixColor ?? CoreTextFieldStyle.defaultAffixColor;
  final errorColor =
      merged.errorStyle?.color ??
      merged.errorColor ??
      CoreTextFieldStyle.defaultErrorColor;
  // Non-null only when the caller set an explicit override (via either
  // slot) — mirrors `hasColorOverride` in `buildErrorClassName()` so the
  // inline value only ships when the class was suppressed.
  final errorColorOverride = (merged.errorStyle?.color ?? merged.errorColor)
      ?.toValue();
  const caretColor = CoreTextFieldStyle.defaultCursorColor;
  // A token rides the selection utility; raw colors need a scoped rule.
  final selectionPseudo = emitPseudoColor(
    merged.selectionColor?.scaleAlpha(CoreOpacity.opacity20),
    CoreTextFieldStyle.defaultSelectionColor.scaleAlpha(CoreOpacity.opacity20),
    .background,
    pseudo: .selection,
    scopeSelector: '.${_selectionScopeClass(scopeId)}',
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the root `<div>` Tailwind className — grid layout for the
  /// label / framed body / description / error stack. Structural only;
  /// the `gap` lives inline (single inline signature).
  String buildRootClassName() => WebLayout.gridFull;

  /// Composes the root `<div>` inline-CSS bundle — emits the always-on
  /// `border-radius`. No `gap` here: the vertical rhythm of the
  /// label / field / helper stack comes from `labelPadding` (bottom)
  /// and `descriptionPadding` (top) alone, matching the Flutter twin's
  /// spacing-less root Column — `rowSpacing` belongs only to the
  /// prefix / input / suffix row inside the framed body.
  Styles buildRootInlineStyles() => .new(
    raw: {
      'border-radius': borderRadius,
    },
  );

  /// Composes the className forwarded to the composed `FormLabel`.
  ///
  /// Disabled affordance — the field is disabled when `!enabled` (a
  /// build-time semantic state). The disabled label colour is
  /// `FormLabel`'s own concern (its `enabled` param, fed
  /// [formLabelStyle]'s `disabledColor`); here only the `not-allowed`
  /// cursor is added. This replaces the vestigial `peer-disabled:*`
  /// classes, which never fired: no element carries the `peer` class and
  /// the label precedes the input, so `.peer:disabled ~ label` could not
  /// match.
  String buildLabelHostClassName() =>
      <String>[if (!enabled) 'cursor-not-allowed'].join(' ');

  /// Composes the inline-CSS bundle forwarded to the composed
  /// `FormLabel` — `labelPadding` (encoded as bottom-only
  /// `CoreEdgeInsets`) emitted as `margin` shorthand. This is the
  /// label→field spacing, which the Flutter twin states as a `Padding`
  /// wrapped around its own `FormLabel`.
  Styles buildLabelHostInlineStyles() => .new(
    raw: {
      'margin': labelPaddingCss,
    },
  );

  /// Composes the `<input>` element Tailwind className. Layers shared
  /// variant / size chrome with per-instance fill / expand rules. The
  /// value-typography token / colour classes are suppressed when the
  /// matching `valueStyle` override field is set so the inline rule wins.
  String buildInputClassName() {
    final classList = [
      WebLayout.flexFull,
      'transition-colors',
      'file:border-0 file:bg-transparent',
      'file:font-${fileLabelFontWeight.tailwindFontWeight}',
      // `showCursor == false` hides the caret (parity with Flutter
      // `EditableText.showCursor: false`); otherwise the token caret.
      if (showCursor == false)
        'caret-transparent'
      else
        'caret-${caretColor.tailwindColor}',
      // The focus ring is drawn by the surrounding FocusOutline and the
      // border tint by the wrapper; the input only suppresses the
      // browser's default outline.
      'outline-none',
      // #3469 — no `disabled:opacity-50`. The dedicated disabled tokens
      // on `_buildVariantClasses` (`disabled:text-*`) already carry the
      // state; a multiplier on top would only make its contrast depend on
      // whatever surface the field sits on, and forced-colours mode
      // doesn't touch opacity at all (the colour swap does the work there
      // too).
      'disabled:cursor-not-allowed disabled:pointer-events-none',
      // Value typography role class plus token colour via the emit
      // family; explicit overlays ride the inline bundle.
      valueEmit.className,
      // Placeholder colour — a token class, or (raw) the scope class the
      // scoped `::placeholder` rule selects.
      placeholderPseudo.className,
      placeholderTypography.className,
      if (placeholderPseudo.className.isEmpty) _placeholderScopeClass(scopeId),
      // Text-selection tint — pseudo-element class, same reason.
      selectionPseudo.className,
      if (selectionPseudo.className.isEmpty) _selectionScopeClass(scopeId),
      // A number input's native spinner is dropped by the scoped rule
      // [resolveTextFieldRules] writes for this class.
      if (numeric) kTextFieldNumberClass,
      ..._buildVariantClasses(
        vs,
        placeholderOverridden: merged.placeholderStyle?.color != null,
      ),
      // The wrapper is the box — border, fill, material — so the input
      // carries none of them and takes the row's remaining width. A width
      // set inline here would beat `border-0` and draw a second box inside
      // the first.
      'border-0',
      WebLayout.flex1,
      if (expands) WebLayout.hFull,
    ];

    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the `<input>` inline-CSS bundle — every chrome value
  /// inline (single inline signature): border radius, content padding,
  /// scroll padding, text alignment, caret / cursor overrides, plus
  /// value-typography overlays. The box's own dimensions (height, floor,
  /// cap) are the wrapper's.
  Styles buildInputInlineStyles() {
    final raw = {
      'transition-duration': durationMsCss(transitionDurationMs),
      'border-radius': borderRadius,
      'padding': inputPadding,
      'scroll-padding': scrollPaddingCss,
      'text-align': textAlignCss,
      'vertical-align': textAlignVerticalCss,
      // Caret colour renders natively; width / radius are surfaced as
      // CSS custom properties (the painted element carries the override
      // for parity with the Flutter caret, even though the native caret
      // is browser-drawn).
      '--coui-caret-width': cursorWidthRem,
      // Native HTML input carets are browser-drawn; expose this optional
      // value for tooling without replacing native selection or IME behavior.
      if (merged.cursorHeight != null)
        '--coui-caret-height': '${merged.cursorHeight! / kRemDivisor}rem',
      '--coui-caret-radius': cursorRadiusRem,
      '--coui-caret-background-color': ?backgroundCursorColorCss,
    };
    // Skip the caret-colour override when the caret is hidden
    // (`caret-transparent` class already wins); otherwise honour the
    // cursor-colour slot override.
    if (showCursor != false && cursorColor != null) {
      raw['caret-color'] = cursorColor;
    }
    // Value typography overlay — explicit font / weight / raw colour
    // (the role + token colour stay on the class via [valueEmit]).
    final valueInline = valueEmit.inline;
    if (valueInline != null) raw.addAll(valueInline);
    raw.addAll(placeholderTypography.inline ?? const {});
    return Styles(raw: raw);
  }

  /// Composes the box `<div>` Tailwind className — structural
  /// + variant / pseudo-state classes only. Border radius / gap / row
  /// alignment live inline (single inline signature).
  ///
  /// The wrapper draws no ring. Its parent is the composed
  /// `FocusOutline` — the same box, one element out — so a
  /// `focus-within:ring-*` set here painted a second ring over the first
  /// and, being a class, could only carry integer scale steps and no
  /// offset-band colour. `focus-within:border-*` is a border tint, not a
  /// ring, and stays: it is this element's CSS-native focus affordance.
  String buildAffixWrapperClassName() {
    // The wrapper is the box, so it carries the whole fill — the disabled
    // one included, which a `<div>` cannot take from a `:disabled` pseudo.
    // The `<input>` inside paints none (see `_buildVariantClasses`).
    final disabledFill = vs.disabledBackgroundColor;
    final bgClass = filled
        ? 'bg-transparent'
        : !enabled && disabledFill.token != null
        ? 'bg-$disabledFill'
        : vs.backgroundColor.isTransparent
        ? 'bg-transparent'
        : 'bg-${vs.backgroundColor}';
    // The disabled edge is build-time state here too: a `<div>` cannot take
    // it from a `:disabled` pseudo, so it is chosen the way the fill is.
    final borderColor = !enabled && !vs.disabledBorderColor.isTransparent
        ? vs.disabledBorderColor
        : vs.borderColor;
    return <String>[
      WebLayout.flex,
      if (!borderColor.isTransparent)
        'border border-$borderColor'
      else
        // `plain` states a transparent border: no box, so no `border`
        // colour class. The inline `border-width` is still emitted, though,
        // and with preflight off the border falls back to the browser's
        // own grey — which draws that 1px. Stating the style and a
        // transparent colour keeps the pixel (the Flutter box takes a
        // transparent 1px border too) and keeps it invisible.
        'border-solid border-transparent',
      bgClass,
      // Not while disabled: the hover fill would cover the disabled one.
      if (enabled && !filled && vs.hoverBackgroundColor?.token != null)
        'hover:bg-${vs.hoverBackgroundColor}',
      focusWithinBorderClass,
      hoverBorderWithinClass,
      // The wrapper is the box: it carries the `surface:content` marker
      // and published fill, never the `<input>` inside it.
      if (!containerFillCore.isTransparent) ...webSurfaceMarkerFor(.content),
      // The wrapper draws the boundary and the focused element is the
      // `<input>` inside it — so the `:focus-within` marker.
      if (focusBoundaryShadow != null) kActiveBoundaryWithinMarker,
      if (expands) WebLayout.hFull,
    ].join(' ');
  }

  /// Composes the box `<div>` inline-CSS bundle — every chrome value
  /// inline: border radius, native flex `gap` (sourced from
  /// `rowSpacing` — the prefix / input / suffix row spacing token, same
  /// semantics as Flutter `Row.spacing`), vertical alignment of the row,
  /// the box's own dimensions (a stated `height`, the `min-height` floor,
  /// a `max-height` cap — all border-box, as Flutter's constraints are),
  /// the row's inset on the slotted sides, the boundary width the material's
  /// edge band reaches over, plus the fill / border overrides.
  Styles buildAffixWrapperInlineStyles() {
    final raw = {
      'border-radius': borderRadius,
      'border-width': borderWidthCss,
      // A material that lights its own edge draws it over the border box,
      // not inside it; the border stays in layout (transparent) so a style
      // swap changes paint alone.
      ...surfaceBleedVar(borderWidthCss),
      'gap': rowSpacingCss,
      // The row's inset — the sides that carry a slot plus the vertical
      // inset (see `wrapperPaddingCore`).
      'padding': wrapperPadding,
      'align-items': crossAxisAlignCss,
      if (inputHeight != null) 'height': '${inputHeight / kRemDivisor}rem',
      'min-height': ?boxMinHeightCss,
      if (merged.maxHeight != null)
        'max-height': '${merged.maxHeight! / kRemDivisor}rem',
    };
    if (backgroundOverride != null) {
      raw['background-color'] = backgroundOverride;
    }
    if (borderOverride != null) raw['border-color'] = borderOverride;
    // The focused boundary's layer, read by the wrapper's marker on focus.
    if (focusBoundaryShadow != null) {
      raw[kActiveBoundaryVar] = focusBoundaryShadow;
    }
    // The marker's other half (see [buildAffixWrapperClassName]).
    if (!containerFillCore.isTransparent) {
      raw.addAll(surfaceFillVar(containerFillCore));
    }
    if (focusBorderColor != null) {
      raw[kInputFocusBorderVar] = focusBorderColor;
    }
    return Styles(raw: raw);
  }

  /// Composes a prefix / suffix `<span>` Tailwind className — the size
  /// row's base typography role in the affix colour, so words in the slot
  /// (a unit, a count, a timer) wear what every other text in the field
  /// wears. An `Icon` in the slot is unaffected: it sizes itself
  /// (`iconElementChrome`), which is also why the span no longer pins
  /// `font-size` to the icon size — that pin only ever reached TEXT, and
  /// made a `Text` suffix render at 20px in a 14px field.
  String buildAffixSlotClassName() =>
      '${WebLayout.flex} ${WebLayout.itemsCenter} ${affixEmit.className} '
      'text-${affixColor.tailwindColor}';

  /// Composes a prefix / suffix `<span>` inline-CSS bundle — the slot
  /// icon colour override, when the caller stated one.
  Styles? buildAffixSlotInlineStyles(CoreIconStyle slotStyle) {
    final slotColor = slotStyle.color?.toValue();
    if (slotColor == null) return null;
    return Styles(raw: {'color': slotColor});
  }

  /// Composes the description `<p>` Tailwind className. The typography
  /// token / colour classes are suppressed when the matching
  /// `descriptionStyle` override field is set so the inline rule wins.
  String buildDescriptionClassName() {
    // Role class (+ token colour) via the emit family; when no per-slot
    // colour override is set the helper-text default token rides a class.
    final hasColorOverride = merged.descriptionStyle?.color != null;
    return <String>[
      descriptionEmit.className,
      if (!hasColorOverride) 'text-${descriptionColor.tailwindColor}',
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the description `<p>` inline-CSS bundle — the
  /// `descriptionPadding` (encoded as top-only `CoreEdgeInsets`) emitted
  /// as `margin` shorthand inline, plus the [emitTypography] overlay
  /// fragment (explicit font / weight / raw-colour overrides).
  Styles buildDescriptionInlineStyles() => .new(
    raw: {
      'margin': descriptionPaddingCss,
      ...?descriptionEmit.inline,
    },
  );

  /// Composes the error `<p>` Tailwind className. [emitTypography] emits
  /// the role class; the `destructive` colour rides a class when no
  /// per-slot colour override is set.
  String buildErrorClassName() {
    final hasColorOverride =
        merged.errorStyle?.color != null || merged.errorColor != null;
    return <String>[
      errorEmit.className,
      if (!hasColorOverride) 'text-${errorColor.tailwindColor}',
    ].where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the error `<p>` inline-CSS bundle — the
  /// `descriptionPadding` (top margin, reused for parity with the
  /// description slot) emitted as `margin` shorthand inline, plus the
  /// [emitTypography] overlay fragment.
  Styles buildErrorInlineStyles() => .new(
    raw: {
      'margin': descriptionPaddingCss,
      'color': ?errorColorOverride,
      ...?errorEmit.inline,
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedTextField(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    formLabelStyle: formLabelStyle,
    labelHost: WebElementChrome(
      className: buildLabelHostClassName(),
      inlineStyles: buildLabelHostInlineStyles(),
    ),
    input: WebElementChrome(
      className: buildInputClassName(),
      inlineStyles: buildInputInlineStyles(),
    ),
    affixWrapper: WebElementChrome(
      className: buildAffixWrapperClassName(),
      inlineStyles: buildAffixWrapperInlineStyles(),
    ),
    leadingSlot: WebElementChrome(
      className: buildAffixSlotClassName(),
      inlineStyles: buildAffixSlotInlineStyles(leadingIconStyle),
    ),
    trailingSlot: WebElementChrome(
      className: buildAffixSlotClassName(),
      inlineStyles: buildAffixSlotInlineStyles(trailingIconStyle),
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    error: WebElementChrome(
      className: buildErrorClassName(),
      inlineStyles: buildErrorInlineStyles(),
    ),
    leadingIconStyle: leadingIconStyle,
    trailingIconStyle: trailingIconStyle,
    featureButtonStyle: featureButtonStyle,
    focusOutlineStyle: focusOutlineStyle,
  );
}

// ═══════════════════════════════════════════════════
// File-private helpers (small pure functions, short signatures)
// ═══════════════════════════════════════════════════

/// Builds the `<input>`'s own Tailwind classes — the foreground and its
/// disabled overlays — from a [CoreTextFieldVariantStyle] table entry pulled
/// from [CoreTextFieldStyle.defaultsByVariant] (idle vs error). The box
/// chrome (fill, border, hover step) belongs to the wrapper
/// (`buildAffixWrapperClassName`), so the input is always see-through:
/// painting a fill on it too would cover the wrapper's pressed wash and
/// leave a strip of the wrong fill across the input's rows alone.
List<String> _buildVariantClasses(
  CoreTextFieldVariantStyle entry, {
  bool placeholderOverridden = false,
}) {
  final classes = <String>[
    'bg-transparent',
    'text-${entry.foregroundColor}',
    'disabled:text-${entry.disabledForegroundColor}',
  ];
  // A disabled placeholder takes the disabled foreground too (#5747) — unless
  // the caller states a placeholder colour, which wins in every state (the
  // class XOR scoped-rule path owns it).
  if (!placeholderOverridden) {
    classes.add('disabled:placeholder:text-${entry.disabledForegroundColor}');
  }

  return classes;
}

/// The width the active boundary adds beyond the resting border, as a CSS
/// length — or `null` when it adds nothing.
///
/// One rule for the inline error shadow and the focused boundary's layer, so
/// the two cannot disagree. Nothing is added to the bare `plain` variant (it
/// keeps its resting boundary in every state) nor when the active width is no
/// wider than the resting one (a caller who states only a thicker
/// `borderWidth` is not thinned on focus) — the latter is
/// [activeBoundaryInsetCss]'s rule, shared with the `TextArea` twin.
String? _activeBoundaryInset({
  required CoreTextFieldVariant variant,
  required double rest,
  required double active,
}) => variant == CoreTextFieldVariant.plain
    ? null
    : activeBoundaryInsetCss(rest: rest, active: active);

// ═══════════════════════════════════════════════════
// Scoped pseudo-state rules
// ═══════════════════════════════════════════════════

/// Scoped CSS text for the `<style>` block in `text_field.dart`.
///
/// Carries two kinds of rule, each empty on the default path:
///
///  * **a raw placeholder colour** — `::placeholder` has no inline form,
///    so a token-less `placeholderStyle.color` paints through
///    `.co-text-field-ph-<id>::placeholder` on the `<input>` (the class
///    path drops its `placeholder:text-*` utility — class XOR rule);
///  * **the state layer**, described below.
///
/// The state layer is the field's own foreground laid over its fill at one
/// of three weights, which no Tailwind utility can express: it is a blend,
/// not a token swap, so there is no preset class for the result. Button
/// reached the same conclusion and emits the same `color-mix` shape.
///
/// Empty — and the widget then renders no `<style>` and stays id-less — on
/// two paths that must not wash:
///
///  * **the variant states no ramp**, and
///  * **the fill has no token to mix against.** Seven in-repo compositions
///    hand `TextField` a transparent fill; `color-mix` needs a CSS variable
///    name for the base, and a fill with no token has none. The OTP hidden
///    buffer is the case that makes this non-negotiable — invisible and
///    permanently focused while typing, so the focus rung would paint a
///    slab across the visible cell row.
class ResolvedTextFieldRules {
  /// Creates a [ResolvedTextFieldRules].
  const ResolvedTextFieldRules({required this.css});

  /// Scoped CSS for pseudo-element colours and the optional box state layer.
  final String css;
}

/// Resolves the scoped rules for one field instance — the raw placeholder
/// colour and the state layer.
///
/// Re-walks the same merge chain as [resolveTextField] on purpose: the
/// class-drop decision and these rules have to see the same resolved
/// values, or the field emits a class and a rule for the same property and
/// the two fight.
///
/// [scopeId] is the instance scope [resolveTextField] also received (the
/// placeholder rule's class); [stateLayerId] is the id of the element the
/// state layer washes — the `<input>` when bare, the affix wrapper once
/// there is one.
ResolvedTextFieldRules resolveTextFieldRules(
  BuildContext context, {
  required String scopeId,
  required String stateLayerId,
  required bool hasError,
  required bool enabled,
  bool numeric = false,
  CoreTextFieldVariant? variant,
  CoreTextFieldStyle? textFieldStyle,
}) {
  final fieldTheme = context.theme.coreComponentTheme?.textField;
  // Same Core question as `resolveTextField`, so the rules and the chrome
  // read the same row.
  final effectiveVariant = CoreTextFieldVariant.of(
    hasError: hasError,
    enabled: enabled,
    variant: variant,
  );
  final merged = resolveStyleChain(const CoreTextFieldStyle(), [
    fieldTheme?.style,
    fieldTheme?.variantStyles?[effectiveVariant],
    textFieldStyle,
  ]);
  final vs = CoreTextFieldStyle.defaultsByVariant[effectiveVariant]!;

  // Placeholder — empty on the token path, where the class carries it.
  // Written whether or not the field is enabled: the disabled row states
  // its own placeholder colour and the class path honours it too.
  final buffer = StringBuffer()
    ..write(
      emitPseudoColor(
        merged.placeholderStyle?.color,
        vs.placeholderColor,
        .text,
        pseudo: .placeholder,
        scopeSelector: '.${_placeholderScopeClass(scopeId)}',
      ).rule,
    )
    ..write(
      emitPseudoColor(
        merged.selectionColor?.scaleAlpha(CoreOpacity.opacity20),
        CoreTextFieldStyle.defaultSelectionColor.scaleAlpha(
          CoreOpacity.opacity20,
        ),
        .background,
        pseudo: .selection,
        scopeSelector: '.${_selectionScopeClass(scopeId)}',
      ).rule,
    );
  if (numeric) buffer.write(kTextFieldNumberRule);

  // A disabled field says so with its own three tokens; layering a hover
  // wash on top would say the pointer did something to a control that
  // ignores it. The per-instance ramp outranks the variant's — a composing
  // parent (Select) states a pressed-only wash through this slot.
  final layer = enabled ? merged.stateLayer ?? vs.stateLayer : null;
  if (layer == null) return ResolvedTextFieldRules(css: buffer.toString());

  final fill = merged.backgroundColor ?? vs.backgroundColor;
  final fillToken = fill.token?.name;
  final fgToken = vs.foregroundColor.token?.name;
  if (fillToken == null || fgToken == null) {
    return ResolvedTextFieldRules(css: buffer.toString());
  }

  final fillPct = (fill.opacity * 100).round();
  final base = 'rgb(var(--coui-$fillToken) / $fillPct%)';
  final selector = '#$stateLayerId';

  String wash(double weight) =>
      'color-mix(in srgb, rgb(var(--coui-$fgToken)) '
      '${(weight * 100).round()}%, $base)';

  // Written hover → focus → pressed so equal-specificity ties resolve to
  // the later rule. That order is load-bearing: a focused field that is
  // then hovered must not step DOWN to the hover weight, and a field held
  // down must outrank both. Flutter states the same precedence as an
  // if-chain; here the cascade states it.
  //
  // `:focus-within`, not `:focus-visible` — the state-layer decision
  // record spells Text Field's focus rung that way, and it is the correct
  // one for a box whose focusable child is the `<input>` inside it.
  //
  // A rung at 0 writes no rule: a `color-mix` at 0% is the resting fill,
  // and a hover rule that paints the resting fill would still read as
  // "hover paints" to anyone auditing the sheet. A ramp with a 0 rung
  // (Select's trigger — hover is a border step, focus is the ring) is a
  // ramp that says nothing there.
  if (layer.hover > 0) {
    buffer.write('$selector:hover{background-color:${wash(layer.hover)};}');
  }
  if (layer.focus > 0) {
    buffer.write(
      '$selector:focus-within{background-color:${wash(layer.focus)};}',
    );
  }
  if (layer.pressed > 0) {
    buffer.write('$selector:active{background-color:${wash(layer.pressed)};}');
  }

  return ResolvedTextFieldRules(css: buffer.toString());
}

/// The class a number input carries so [kTextFieldNumberRule] reaches it.
const kTextFieldNumberClass = 'co-text-field-number';

/// Drops the browser's native spinner from a number input.
///
/// Chrome puts a ~15px up/down control inside `<input type="number">` and
/// keeps that space reserved when the control is not shown, so the value is
/// centred in the area *left over* — about 7px left of the middle of a field
/// whose input is exactly the width between its two affixes (a `NumberInput`'s
/// `−` / `+`). The Flutter twin has no such control. `NumberInput` steps with
/// its own buttons, and a plain numeric field has no use for a second
/// stepper that no other platform draws. A pseudo-element has no inline
/// form, so it is a rule on the marker class rather than a style.
const kTextFieldNumberRule =
    '.$kTextFieldNumberClass{appearance:textfield;-moz-appearance:textfield;}'
    '.$kTextFieldNumberClass::-webkit-inner-spin-button,'
    '.$kTextFieldNumberClass::-webkit-outer-spin-button'
    '{-webkit-appearance:none;margin:0;}';

/// The class a raw placeholder colour's scoped rule selects on the
/// `<input>` — one per field instance.
String _placeholderScopeClass(String scopeId) => 'co-text-field-ph-$scopeId';

/// The hint has its own slot, merged onto the size base rather than onto
/// the value slot. ObjectInput deliberately uses a body hint over a code
/// value; inheriting the input's value typography loses that distinction.
Emit _placeholderTypography(
  CoreTextFieldStyle merged,
  CoreComponentSize size,
) {
  final base =
      merged.baseTextStyle ??
      resolveSizeRow(CoreTextFieldStyle.defaultsBySize, size).baseTextStyle!;
  final hint = base.merge(merged.placeholderStyle);
  final value = base.merge(merged.valueStyle);
  final hintCss = hint.toInlineCss(includeColor: false);
  final valueCss = value.toInlineCss(includeColor: false);
  if (hint.token == value.token &&
      hintCss.length == valueCss.length &&
      hintCss.entries.every((entry) => valueCss[entry.key] == entry.value)) {
    return (className: '', inline: null);
  }
  final emitted = _emitInputTypography(
    merged.placeholderStyle,
    base,
    includeColor: false,
  );
  final inline = emitted.inline!;
  // Role utilities still react to theme changes. Explicit scalar overlays
  // and the face ride per-input variables; private placeholder rules read
  // only the properties this instance states, leaving the role intact.
  return (
    className: [
      'co-text-field-hint',
      for (final name in emitted.className.split(' '))
        if (name.isNotEmpty) 'placeholder:$name',
      for (final property in inline.keys) 'co-text-field-hint-$property',
    ].join(' '),
    inline: {
      for (final entry in inline.entries)
        '--co-text-field-hint-${entry.key}': entry.value,
    },
  );
}

/// Native input resets outrank the zero-specificity role-family selector.
/// Complete the shared emitter locally, without extending its public API.
Emit _emitInputTypography(
  CoreTextStyle? value,
  CoreTextStyle base, {
  bool includeColor = true,
}) {
  final resolved = base.merge(value);
  final emitted = emitTypography(value, base);
  final inline = {
    'font-family': resolved.token == null
        ? CssVariableGenerator.fontFamilyCss(CoreFontFamily.sans)
        : 'var(--coui-text-${resolved.token!.name}-family, '
              'var(--coui-font-family-sans))',
    ...?emitted.inline,
  };
  if (!includeColor) inline.remove('color');
  return (
    className: includeColor
        ? emitted.className
        : resolved.token == null
        ? ''
        : 'text-${resolved.token!.name}',
    inline: inline,
  );
}

/// The input class scoped to a raw selection colour.
String _selectionScopeClass(String scopeId) =>
    'co-text-field-selection-$scopeId';
