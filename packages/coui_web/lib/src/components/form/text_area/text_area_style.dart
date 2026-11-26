import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/internal/input_focus_border_paint.dart';
import 'package:coui_web/src/internal/text_area_border_paint.dart';
import 'package:coui_web/src/internal/text_area_boundary_paint.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `TextArea`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)
///   ├─ FormLabel (<label>)               // co_text_area renders only when label != null
///   │    │                               // host chrome ← labelHost (cursor)
///   │    │                               // typography ← formLabelStyle (raw-forwarded)
///   │    ├─ label text                   // bare Text — inherits FormLabel's own typography
///   │    └─ (required `*` + its gap are drawn by FormLabel itself)
///   ├─ Gap (labelGapStyle)             // co_text_area renders only when label != null
///   ├─ framedBody                        // wrapped in FocusOutline
///   │    ├─ (no footer)
///   │    │    affixWrapper (<div>)         // the box: border / fill; always rendered
///   │    │       ├─ prefix (<span>)        // optional
///   │    │       ├─ textarea (<textarea>)
///   │    │       ├─ suffix (<span>)        // optional
///   │    │       └─ resizeHandle (<div>)  // co_text_area renders only when expandable
///   │    └─ (footer)                     // co_text_area renders only when footer != null
///   │         frame (<div>)              // the box: border / fill / padding
///   │            ├─ textRow (<div>)
///   │            │    ├─ prefix (<span>)        // optional
///   │            │    ├─ textarea (<textarea>)
///   │            │    ├─ suffix (<span>)        // optional
///   │            │    └─ resizeHandle (<div>)   // only when expandable
///   │            ├─ Gap (footerGapStyle)
///   │            └─ footer (<div>)
///   │                 └─ footer content          // caller-supplied
///   ├─ Gap (descriptionGapStyle)       // co_text_area renders only when description != null || error != null
///   ├─ description (<p>)                 // co_text_area renders only when description != null && error == null
///   └─ error (<p>)                       // co_text_area renders only when errorText != null
/// ```
///
/// Per Epic #1603 (옵션 B 최종, single inline signature) every chrome
/// value (background / border colour / border radius / padding / gap /
/// dimensional size) is emitted **inline** through
/// `(merged.X ?? CoreTextAreaStyle.defaultX).toValue()` /
/// `'${(merged.X ?? default) / kRemDivisor}rem'` — no class-drop branch
/// decides between a Tailwind utility and an inline rule. Only colour /
/// typography token classes, pseudo-state (`hover:` / `focus:` /
/// `focus-within:` / `placeholder:` / `disabled:`) classes and
/// structural (`grid` / `flex` / `w-full` / `resize-*`) classes remain
/// on the className surface.
///
/// The resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — the nested [CoreFocusOutlineStyle] slot forwarded straight
///   to the surrounding `FocusOutline(focusOutlineStyle: …)` by
///   `co_text_area`.
///
/// No scalar metadata (size / hasError / etc.) is exposed — the
/// semantic identifiers stay on the widget prop and are passed to the
/// resolver as arguments.
class ResolvedTextArea implements WebResolvedChrome {
  /// Creates a [ResolvedTextArea].
  const ResolvedTextArea({
    required this.root,
    required this.formLabelStyle,
    required this.labelHost,
    required this.textarea,
    required this.affixWrapper,
    required this.affixSlot,
    required this.frame,
    required this.textRow,
    required this.footer,
    required this.resizeHandle,
    required this.description,
    required this.error,
    required this.helperRow,
    required this.counter,
    required this.focusOutlineStyle,
    required this.labelGapStyle,
    required this.descriptionGapStyle,
    required this.footerGapStyle,
    required this.counterGapStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` element.
  @override
  final WebElementChrome root;

  /// Nested [CoreFormLabelStyle] slot raw-forwarded to the composed
  /// `FormLabel(formLabelStyle: …)` — carries this field's per-instance
  /// [CoreTextAreaStyle.labelStyle] override, its disabled-label tint
  /// ([CoreTextAreaStyle.labelDisabledColor]) and the required-asterisk
  /// colour. The enabled label colour is `FormLabel`'s own default.
  ///
  /// **`FormLabel` owns the actual per-size typography default** (its own
  /// `defaultsBySize`: the 13px rung on `xs`/`sm`/`md`, the 14px rung on
  /// `lg`/`xl`/`xl2`); this field states only the parts `TextArea` itself
  /// overrides. The Flutter twin forwards the same slot to the same
  /// composed component, and `TextField` on both platforms already did.
  final CoreFormLabelStyle formLabelStyle;

  /// Paint-ready host chrome forwarded to the composed `FormLabel` —
  /// the cursor the disabled field puts on its own label. The 1-off
  /// spacer below it is a `Gap` (raw-forwarded [labelGapStyle]), not a
  /// margin here.
  final WebElementChrome labelHost;

  /// Paint-ready chrome for the `<textarea>` element.
  final WebElementChrome textarea;

  /// Paint-ready chrome for the wrapper `<div>` that is the box of an area
  /// without a footer — the element that draws the border and the fill and
  /// holds the optional prefix / suffix around the `<textarea>`. It is always
  /// rendered: a native `<textarea>` is a replaced element and cannot carry
  /// the box's pseudo-element layers (the edge band of a glass surface), so
  /// the box is never the `<textarea>` itself.
  final WebElementChrome affixWrapper;

  /// Paint-ready chrome for prefix / suffix `<span>` slots.
  final WebElementChrome affixSlot;

  /// Paint-ready chrome for the box `<div>` of an area with a footer — the
  /// element that draws the border, the fill and the padding around the
  /// text row and the footer together, so the footer sits inside the box.
  /// It takes the box's dimensions too, so a resize and `initialHeight`
  /// speak of the whole box, the way the Flutter twin's `SizedBox` does.
  /// Without a footer [affixWrapper] is the box and this element is not
  /// rendered.
  final WebElementChrome frame;

  /// Paint-ready chrome for the row `<div>` inside [frame] that holds the
  /// prefix / `<textarea>` / suffix. It takes the height the footer leaves,
  /// and it is the corner the resize-handle indicator anchors to: the
  /// `<textarea>`'s, where the native grip sits — not the box's, where the
  /// footer's trailing action sits.
  final WebElementChrome textRow;

  /// Paint-ready chrome for the footer `<div>` inside [frame] — a block
  /// across the box's content width that holds the caller's footer content
  /// and leaves its layout to it (the Flutter twin hands the footer the same
  /// width, start-aligned). It sits outside the `<textarea>`, so the footer
  /// is not part of the editing surface.
  final WebElementChrome footer;

  /// Paint-ready chrome for the bottom-right resize-handle indicator
  /// `<div>` — a decorative affordance overlay that mirrors the Flutter
  /// painted drag handle. `co_text_area` renders it only when the field
  /// is expandable; the native CSS `resize` grip drives the interaction
  /// underneath (`pointer-events: none`).
  final WebElementChrome resizeHandle;

  /// Paint-ready chrome for the description `<p>`.
  final WebElementChrome description;

  /// Paint-ready chrome for the error `<p>`.
  final WebElementChrome error;

  /// Paint-ready chrome for the helper row `<div>` while `showCounter` is on
  /// (#5747) — the helper line and the count side by side.
  final WebElementChrome helperRow;

  /// Paint-ready chrome for the character-count `<span>` (#5747).
  final WebElementChrome counter;

  /// Nested [CoreFocusOutlineStyle] slot — forwarded straight to
  /// `FocusOutline(focusOutlineStyle: …)` by `text_area`. The per-instance
  /// `focusOutlineStyle` override merged onto
  /// `CoreTextAreaStyle.defaultFocusOutlineStyle`, with the box's resolved
  /// corners and the variant's ring colour baked under the caller's slot,
  /// so a caller override (radius / colour / width) actually reaches the
  /// rendered ring.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Nested [CoreGapStyle] slot — forwarded straight to
  /// `Gap(gapStyle: …)` by `co_text_area` as a 1-off spacer between
  /// the label and the field (rendered only when `label != null`).
  /// `Gap`'s own resolver folds in scaling and design defaults — the
  /// text-area's design-system default slot is pre-merged onto the
  /// per-instance override here.
  final CoreGapStyle labelGapStyle;

  /// Nested [CoreGapStyle] slot — forwarded straight to
  /// `Gap(gapStyle: …)` by `co_text_area` as a 1-off spacer between
  /// the field and the description / error helper text (rendered only
  /// when `description != null || errorText != null`). The text-area's
  /// design-system default slot is pre-merged onto the per-instance
  /// override here.
  final CoreGapStyle descriptionGapStyle;

  /// Nested [CoreGapStyle] slot — forwarded straight to
  /// `Gap(gapStyle: …)` by `co_text_area` as a 1-off spacer between the
  /// text row and the footer inside [frame] (rendered only when
  /// `footer != null`). The text-area's design-system default slot is
  /// pre-merged onto the per-instance override here.
  final CoreGapStyle footerGapStyle;

  /// Spacer between the helper line and the character count —
  /// raw-forwarded to `Gap(gapStyle:)`.
  final CoreGapStyle counterGapStyle;
}

/// Scoped CSS text for `<style>` block in `TextArea`.
///
/// Non-empty only when the text-selection tint (`selectionColor`)
/// override moves off the design-system token scale (a raw, token-less
/// colour). The `::selection` pseudo-element has no inline-CSS surface,
/// so a token colour rides the `selection:bg-<token>/20` Tailwind class
/// while a raw override is dropped from the class list (by `resolveTextArea`
/// in the same `token != null` condition) and painted via a scoped
/// `#scopeId::selection{background-color: …}` rule instead (class XOR
/// rule). The `<textarea>` carries `id=scopeId` only when this CSS is
/// non-empty.
class ResolvedTextAreaRules {
  /// Creates a [ResolvedTextAreaRules].
  const ResolvedTextAreaRules({required this.css});

  /// Raw CSS rule text — empty on the default / token path (the
  /// selection tint rides the `selection:bg-*` Tailwind class).
  final String css;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedTextArea] for a `TextArea`.
///
/// Merge chain:
///
/// ```text
/// design system default for variant
///   → theme.coreComponentTheme.textArea.style
///   → theme.coreComponentTheme.textArea.variantStyles[showsError]
///   → widget.textAreaStyle
/// ```
///
/// [expandableHeight] / [expandableWidth] drive the CSS `resize-*`
/// affordance; [hasError] mirrors the `co_text_field` input. `showsError` is
/// [CoreTextFieldVariant.showsErrorChrome] — [hasError] and [enabled]
/// (`disabled > error`). That gate is box chrome
/// only: the error message style of a disabled area with an error still
/// reads the `true` entry of the Theme `variantStyles`.
///
/// The box is never the `<textarea>`: it is [ResolvedTextArea.affixWrapper],
/// or — with [hasFooter] — [ResolvedTextArea.frame], which holds the text row
/// and the footer so the footer sits inside the box without becoming part of
/// the editing surface.
///
/// [obscureText] / [obscuringCharacter] and [showCursor] are per-render
/// behaviour inputs (not chrome slots) — the browser states both as CSS on
/// the editable element, so the emission lives here rather than in the
/// widget, which stays render-only.
ResolvedTextArea resolveTextArea(
  BuildContext context, {
  required CoreComponentSize size,
  required bool expandableHeight,
  required bool expandableWidth,
  required bool hasError,
  required bool obscureText,
  required String obscuringCharacter,
  bool hasFooter = false,
  bool enabled = true,
  CoreTextAreaVariant? variant,
  bool? showCursor,
  CoreEdgeInsets scrollPadding = CoreTextAreaContract.defaultScrollPadding,
  CoreTextAreaStyle? textAreaStyle,
}) {
  final areaTheme = context.theme.coreComponentTheme?.textArea;

  // `disabled > error`, asked of the Core single source
  // (`CoreTextFieldVariant.showsErrorChrome`) rather than spelled here. On
  // Web the order matters past the variant rows' agreeing disabled tokens:
  // `disabled:*` never reaches the affix wrapper's `border-*` class, and a
  // Theme `variantStyles[true]` / `errorBorderColor` override would paint
  // past it.
  final showsError = CoreTextFieldVariant.showsErrorChrome(
    hasError: hasError,
    enabled: enabled,
  );

  // The error message is content, not box chrome: the widget shows it
  // whenever `errorText` is set, disabled or not. So a disabled area with
  // an error steps its chrome off the Theme `true` row, but the message
  // keeps reading that row — only the row's two message fields join the
  // chain, above the chrome row and below the instance override. Enabled,
  // the whole row is already in the chain as `showsError`.
  final errorMessageRow = hasError && !showsError
      ? (areaTheme?.variantStyles?[true])
      : null;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreTextAreaStyle(), [
    areaTheme?.style,
    areaTheme?.variantStyles?[showsError],
    if (errorMessageRow != null)
      CoreTextAreaStyle(
        errorStyle: errorMessageRow.errorStyle,
        errorTextColor: errorMessageRow.errorTextColor,
      ),
    textAreaStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  // Variant chrome selected via the contract's `defaultsByVariant` holder
  // (single subscript — no ternary over the two named constants).
  final vs =
      CoreTextAreaStyle.defaultsByVariant[CoreTextAreaVariant.of(
        hasError: hasError,
        enabled: enabled,
        variant: variant,
      )]!;
  final ss = resolveSizeRow(CoreTextAreaStyle.defaultsBySize, size);
  // A retiring size renders as before; a run with asserts on logs it once
  // (asserts stripped: nothing), so the caller hears before the step goes.
  noticeRetiringSize(
    component: 'TextArea',
    size: size,
    retiring: CoreTextAreaContract.retiringSizes,
  );

  // ─── Resolved chrome values (single inline signature) ──
  // Every dimensional value below is `(merged.X ?? <size|default>)` and
  // is emitted inline via `.toValue()` / rem — no class-drop branch.
  // Kept as the Core value too: the focus ring below takes the box's
  // corners, and it needs them before they become a CSS string.
  // Area corner — the per-instance override wins, else the size row's
  // corner (the `TextField` corner of the same size step; the area's own
  // height is set by its rows, not by the control ladder).
  final borderRadiusCore = merged.borderRadius ?? ss.borderRadius!;
  final borderRadius = borderRadiusCore.toValue();
  final padding = (merged.padding ?? ss.padding!).toValue();
  // Nested CoreIconStyle slot — design-system per-size default merged
  // with the per-instance override. Used to drive the affix `font-size`
  // inline CSS so prefix / suffix glyphs match the size token.
  final iconStyleSlot = ss.iconStyle!.merge(merged.iconStyle);
  final iconSize = iconStyleSlot.size!;
  // Icon → input gap — mirrors Flutter `Row(spacing:)`.
  final rowSpacing = merged.rowSpacing ?? CoreTextAreaStyle.defaultRowSpacing;
  final rowSpacingCss = spaceCss(rowSpacing);
  // Nested CoreGapStyle slots — design-system default merged with the
  // per-instance override so a caller override (size / colour /
  // crossAxisExtent) reaches the rendered gap while unset fields fall
  // back to the default. Raw forward to `Gap` (no parent-side
  // scaling, no inline margin-* emission).
  // The `lg` rung and above state their own helper gaps (#5747).
  final labelGapStyle = CoreTextAreaStyle.defaultLabelGapStyle
      .merge(ss.labelGapStyle)
      .merge(merged.labelGapStyle);
  final descriptionGapStyle = CoreTextAreaStyle.defaultDescriptionGapStyle
      .merge(ss.descriptionGapStyle)
      .merge(merged.descriptionGapStyle);
  final footerGapStyle = CoreTextAreaStyle.defaultFooterGapStyle.merge(
    merged.footerGapStyle,
  );
  final counterGapStyle = CoreTextAreaStyle.defaultCounterGapStyle.merge(
    merged.counterGapStyle,
  );
  final cursorWidth =
      merged.cursorWidth ?? CoreTextAreaStyle.defaultCursorWidth;
  final cursorRadius =
      (merged.cursorRadius ?? CoreTextAreaStyle.defaultCursorRadius).toValue();
  // Resize drag-handle geometry (mirrors the Flutter painted handle).
  final dragHandleSize =
      merged.dragHandleSize ?? CoreTextAreaStyle.defaultDragHandleSize;
  final dragHandleOffset =
      merged.dragHandleOffset ?? CoreTextAreaStyle.defaultDragHandleOffset;
  final dragHandlePadding =
      merged.dragHandlePadding ?? CoreTextAreaStyle.defaultDragHandlePadding;
  final dragHandleColor =
      merged.dragHandleColor ?? CoreTextAreaStyle.defaultDragHandleColor;
  // Dimensional constraints. `initialWidth` / `maxHeight` / `maxWidth`
  // all default to the unbounded `double.infinity` sentinel —
  // `_remOrNull` drops a non-finite extent exactly as it drops `null`,
  // so the property is emitted only when a finite override asks for it
  // and the element otherwise fills / is unbounded.
  final initialHeight =
      merged.initialHeight ??
      ss.initialHeight ??
      CoreTextAreaStyle.defaultInitialHeight;
  final initialWidth =
      merged.initialWidth ?? CoreTextAreaStyle.defaultInitialWidth;
  final minHeight = merged.minHeight ?? CoreTextAreaStyle.defaultMinHeight;
  final minWidth = merged.minWidth ?? CoreTextAreaStyle.defaultMinWidth;
  final maxHeight = merged.maxHeight ?? CoreTextAreaStyle.defaultMaxHeight;
  final maxWidth = merged.maxWidth ?? CoreTextAreaStyle.defaultMaxWidth;
  final textAlign = merged.textAlign ?? CoreTextAreaStyle.defaultTextAlign;
  final textAlignVertical =
      merged.textAlignVertical ?? CoreTextAreaStyle.defaultTextAlignVertical;

  // Border colour — idle / error. In the error variant the caller may
  // pin the border via `errorBorderColor`; otherwise the variant's own
  // `borderColor` token applies. The idle override is `borderColor`.
  final borderColor = showsError
      ? (merged.errorBorderColor ?? merged.borderColor ?? vs.borderColor)
      : (merged.borderColor ?? vs.borderColor);
  // The native state ladder drops the idle override under the pointer.
  // Disabled uses its dedicated hover border even when a caller supplied
  // the idle colour; an explicit raw/transparent hover colour is enabled-only.
  final hoverBorderCore = enabled
      ? merged.hoverBorderColor ?? vs.hoverBorderColor ?? vs.borderColor
      : vs.disabledBorderColor;
  final hoverBorderEmit = emitColor(hoverBorderCore, vs.borderColor, .border);

  // Only token colours enter the pseudo-class emitter. Raw hover values
  // use the same-box variable reader below, so no scoped rule is discarded.
  PseudoEmit? tokenHover(WebPseudo pseudo) {
    if (hoverBorderCore.token == null ||
        (!enabled && merged.borderColor == null)) {
      return null;
    }
    final emitted = emitPseudoColor(
      hoverBorderCore,
      vs.borderColor,
      .border,
      pseudo: pseudo,
      scopeSelector: '',
    );
    assert(
      emitted.rule.isEmpty,
      'Token hover must have an empty scoped rule.',
    );
    return emitted;
  }

  final hoverToken = tokenHover(.hover);
  final hoverWithinToken = tokenHover(.hoverUnlessFocusWithin);
  final hoverFrameToken = enabled && hoverToken != null
      ? _textAreaFrameHover(hoverToken)
      : null;
  final hoverBorderClass = hoverToken?.className ?? '';
  final hoverBorderWithinClass = hoverWithinToken?.className ?? '';
  // surface:content — the area draws its own box on the wrapper `<div>`
  // (or the footer frame) rather than composing `OutlinedContainer`, so the
  // marker is restated on whichever element actually paints the fill. The
  // design default always states a solid `surface` token, so the pair applies
  // unconditionally unless the caller explicitly opted out with a raw
  // transparent override — same gate every other content-role surface on this
  // axis uses.
  final containerFillCore =
      merged.backgroundColor ??
      (enabled ? vs.backgroundColor : vs.disabledBackgroundColor);
  // The frame of a footed area is a `<div>`, which never matches
  // `:disabled`, so it states the disabled fill and border itself — the
  // whole box, as the Flutter twin tints it, rather than a disabled
  // `<textarea>` block inside a rest-coloured padding and footer. An idle
  // border override rests here but yields to the disabled token on hover.
  final frameFillCore = containerFillCore;
  final frameBorderColor = enabled
      ? borderColor
      : (merged.borderColor ?? vs.disabledBorderColor);
  final boxBorderEmit = emitColor(frameBorderColor, vs.borderColor, .border);
  // A raw idle value cannot sit inline: it would block focus and hover.
  // Token idle classes remain unchanged even beside a raw hover reader,
  // whose state specificity outranks the resting class.
  final stateBorderPath = frameBorderColor.token == null;
  final restBorderCss = stateBorderPath
      ? boxBorderEmit.inline!['border-color']
      : null;
  final hoverBorderCss = enabled && hoverBorderCore.token == null
      ? hoverBorderEmit.inline!['border-color']
      : null;

  // `showCursor == false` hides the caret (parity with Flutter
  // `EditableText.showCursor: false`), and the colour override goes with
  // it — the `caret-transparent` class emitted below already wins, so an
  // inline `caret-color` would only be a rule nothing can see.
  final cursorColor = showCursor == false
      ? null
      : merged.cursorColor?.toValue();
  // Masked rendering. `-webkit-text-security` is the browser's only
  // surface for obscuring a multi-line control, and it takes a *shape*
  // rather than a glyph — so the resolved character picks the nearest one
  // (Flutter paints the character itself).
  final textSecurity = obscureText
      ? _textSecurityCss(obscuringCharacter)
      : null;
  // Idle (floating) cursor colour — a Flutter `EditableText` concern the
  // browser has no surface for (a native `<textarea>` has no floating
  // cursor). Surfaced only when the caller overrides it, as a
  // `--coui-caret-background-color` custom property, so the resolved
  // intent reaches the DOM for tooling / Flutter parity while the browser
  // ignores it exactly like `--coui-caret-width` / `--coui-caret-radius`.
  // Theme-free value so dark mode tracks at runtime; the default path
  // emits nothing so the default output stays unchanged.
  final backgroundCursorColorCss = merged.backgroundCursorColor?.toValue();
  final focusBorderColor = merged.focusBorderColor?.toValue();
  // The wrapper/frame paints the stroke; the textarea itself is borderless.
  // Preserve token classes and route raw/transparent overrides through the
  // same box's existing variable, independently of the added boundary layer.
  final rawFocusBorder =
      merged.focusBorderColor != null && merged.focusBorderColor!.token == null;
  final focusBorderToken = merged.focusBorderColor?.token != null
      ? merged.focusBorderColor!.tailwindColor
      : '${vs.focusRingColor}';
  // Active boundary (focus / error) — the part of the active width beyond the
  // resting border, drawn as an inset shadow so the text does not move. The
  // resting `border` stays in the layout (and keeps a forced-colours boundary
  // alive: a shadow is not drawn in that mode, a border is). The error
  // variant is a build-time state, so its shadow rides the element inline;
  // the focus half is a pseudo-state, so the box publishes its layer on
  // `kActiveBoundaryVar` and carries the marker the shared `ThemeConfig`
  // rule reads on focus. Same rule as the `TextField` twin.
  final activeInsetCss = activeBoundaryInsetCss(
    rest: merged.borderWidth ?? CoreTextAreaStyle.defaultBorderWidth,
    active:
        merged.activeBorderWidth ?? CoreTextAreaStyle.defaultActiveBorderWidth,
  );
  // The error variant's active boundary as the inset layer it is drawn with.
  // Absent while the area does not wear the error variant, the active width
  // adds nothing, or the boundary is transparent.
  // An error edge rests at the resting width (#5747) and widens only while
  // focused, through the focused layer below.
  const String? errorBoundaryShadow = null;
  // The focused boundary, as the inset layer the shared rule paints on
  // focus. Absent while disabled (it cannot take focus), when the active
  // width adds nothing, and when the focus colour paints nothing. Error
  // chrome keeps its existing focused variant colour through this path.
  final focusBoundaryShadow = !enabled
      ? null
      : activeBoundaryLayerCss(
          inset: activeInsetCss,
          color: merged.focusBorderColor ?? vs.focusRingColor,
        );
  final transitionDurationMs =
      (merged.transitionDuration ?? CoreTextAreaStyle.defaultTransitionDuration)
          .inMilliseconds;

  // Slot forwarded to `FocusOutline(focusOutlineStyle: …)` by
  // `text_area` — the text area's one ring. The design-default slot is
  // the base the per-instance override merges onto, so the ring's
  // geometry is this component's, the same as the Flutter twin and the
  // text field.
  //
  // Two fields are then baked on: `borderRadius` follows the box's own
  // corners (a `textAreaStyle.borderRadius` override rounds the ring
  // too), and `borderColor` falls back to the variant's focus-ring
  // token so an invalid field rings error-toned.
  //
  // Both are written *under* the caller's slot, and the guards read the
  // *pre-merge* `merged.focusOutlineStyle`, not the merged slot:
  // `defaultFocusOutlineStyle` already states a non-null colour, so a
  // post-merge read is never null — the variant tone below it would
  // become unreachable. (It states no radius: the ring's corner is the
  // box's, per size.)
  //
  // A token colour survives the trip: `FocusOutline`'s resolver emits
  // `var(--coui-<token>)` for a tagged token rather than resolving it at
  // build time, and `scaleAlpha` carries the token through, so the ring
  // still tracks dark mode.
  final forwardedFocusOutlineStyle = CoreTextAreaStyle.defaultFocusOutlineStyle
      .merge(merged.focusOutlineStyle)
      .copyWith(
        borderRadius:
            merged.focusOutlineStyle?.borderRadius ?? borderRadiusCore,
        borderColor:
            merged.focusOutlineStyle?.borderColor ??
            merged.focusBorderColor ??
            vs.focusRingColor,
      );

  // Placeholder colour token — the slot override wins when it carries a
  // design-token colour (Web `::placeholder` only accepts a class), else
  // the variant placeholder token.
  final placeholderStyle = merged.placeholderStyle;
  final placeholderColorToken = placeholderStyle?.color?.token != null
      ? placeholderStyle!.color!.tailwindColor
      : '${vs.placeholderColor}';
  final valueStyle = merged.valueStyle;

  // Text-selection tint — mirrors the Flutter resolver's `.withValues
  // (alpha: CoreOpacity.opacity20)` treatment via `scaleAlpha` so both
  // platforms paint the same 20%-alpha highlight. Emitted as a
  // `selection:` pseudo-element class below — inline CSS cannot target
  // `::selection`.
  final selectionColor =
      (merged.selectionColor ?? CoreTextAreaStyle.defaultSelectionColor)
          .scaleAlpha(CoreOpacity.opacity20);

  // Typography role classes (+ explicit scalar overlay inline) flow
  // through the single canonical `emitTypography` entry point — role
  // class on the className surface, any per-instance fontSize / weight /
  // raw colour overlay inline. The base editable role uses the per-size
  // `baseTextStyle` token as its fallback default.
  final baseTypography = emitTypography(
    merged.baseTextStyle,
    ss.baseTextStyle!,
  );
  // The label's ROLE is not stated here. `FormLabel` owns the per-size
  // ladder (`CoreFormLabelStyle.defaultsBySize`) and this component
  // composes it, so restating a role would be the container reaching into
  // the child's defaults. A flat label role stated here would hold one role
  // on every rung, and a role derived from the per-size value-text base
  // would be the BODY role; either splits the same label across Flutter,
  // Web and the canvas, and only `lg` and up make it visible.
  //
  // The label's COLOUR is not stated here either: the enabled colour is
  // `FormLabel`'s own default, so a label reads the same beside a
  // `TextField`, and the variant's value-text `foregroundColor` does not
  // reach it. What TextArea does state travels as the
  // caller's `labelStyle` (raw-forwarded whole, so any role / colour /
  // weight the caller wrote wins over the child's rung), the disabled
  // tint and the required mark — the same shape the `TextField` resolver
  // forwards, and the Flutter twin.
  final formLabelStyle = CoreFormLabelStyle(
    labelStyle: merged.labelStyle,
    disabledColor:
        merged.labelDisabledColor ??
        CoreTextAreaStyle.defaultLabelDisabledColor,
    requiredColor:
        merged.requiredMarkColor ?? CoreTextAreaStyle.defaultRequiredMarkColor,
  );
  // The helper role steps up on the `lg` rung and above (#5747).
  final helperRole =
      ss.descriptionStyle ?? CoreTextAreaStyle.defaultDescriptionStyle;
  final descriptionTypography = emitTypography(
    merged.descriptionStyle,
    helperRole,
  );
  final errorTypography = emitTypography(merged.errorStyle, helperRole);
  // Character count (#5747) — the counter default's colour on the helper
  // role, the instance override on top.
  final counterTypography = emitTypography(
    merged.counterStyle,
    helperRole.copyWith(color: CoreTextAreaStyle.defaultCounterStyle.color),
  );
  // Muted helper text colour, prefix / suffix glyph colour, and the error
  // / required colours — routed through `emitColor` so the className
  // carries the design-system token class (no direct `cs.<token>` reach).
  // The helper and the affix are two slots with two defaults (the Flutter
  // twin reads the same pair), so overriding one never moves the other.
  final helperTextColor = emitColor(
    merged.helperTextColor,
    CoreTextAreaStyle.defaultHelperTextColor,
    .text,
  );
  final affixColor = emitColor(
    merged.affixColor,
    CoreTextAreaStyle.defaultAffixColor,
    .text,
  );
  final errorTextColor = emitColor(
    merged.errorTextColor,
    CoreTextAreaStyle.defaultErrorTextColor,
    .text,
  );
  // The box's dimensions — stated on whichever element is the box: the
  // `<textarea>`, or the frame once a footer shares the box with it.
  final boxDimensions = <String, String>{
    'height': '${initialHeight / kRemDivisor}rem',
    'min-height': '${minHeight / kRemDivisor}rem',
    'min-width': '${minWidth / kRemDivisor}rem',
    'width': ?_remOrNull(initialWidth),
    'max-height': ?_remOrNull(maxHeight),
    'max-width': ?_remOrNull(maxWidth),
  };

  // ─── Local builders ───────────────────────────────────

  /// The box's border width as CSS — a stroke variable when it is on the
  /// scale, so a designer override and a preset's floor reach it.
  final borderWidthCss = strokeWidthCss(
    merged.borderWidth ?? CoreTextAreaStyle.defaultBorderWidth,
  );

  /// Composes the root `<div>` Tailwind className — flex column for
  /// the label / 1-off spacer / framed body / 1-off spacer / helper
  /// text stack. Inter-row spacing is rendered by interleaved `Gap`
  /// spacers (raw-forwarded `labelGapStyle` / `descriptionGapStyle`)
  /// so the gap component owns its own resolver + scaling — matches
  /// the Flutter `Column` + `Gap` layout.
  String buildRootClassName() => WebLayout.flexColFull;

  /// Composes the className forwarded to the composed `FormLabel` as its
  /// host chrome — the cursor a disabled field puts on its own label,
  /// driven by the sibling `<textarea>`'s own `:disabled` through `peer-`
  /// rather than by a Dart branch (state DETECTION is the browser's here).
  ///
  /// Typography is not in this className, and neither is the disabled
  /// tone: `FormLabel` resolves the role from its own per-size ladder and
  /// dims itself from the `enabled` it is handed, so restating either
  /// here would be this component overruling the child it composes.
  String buildLabelHostClassName() => 'peer-disabled:cursor-not-allowed';

  /// Composes the `<textarea>` element Tailwind className — structural,
  /// pseudo-state and colour / typography token classes only. Radius /
  /// padding / dimensional chrome live inline (single inline signature).
  String buildTextareaClassName() {
    final resizeClass = switch ((expandableHeight, expandableWidth)) {
      (true, true) => 'resize',
      (true, false) => 'resize-y',
      (false, true) => 'resize-x',
      _ => 'resize-none',
    };
    final classList = [
      WebLayout.flexFull,
      // Editable text role — canonical `emitTypography` role class
      // (per-instance scalar overlays go inline via the textarea inline
      // bundle below). The `caret-*` colour routes through the Core
      // single-source default (no direct `cs.primary` reach).
      baseTypography.className,
      'transition-colors',
      // A hidden caret is a transparent caret — the element still takes
      // input and still shows a selection, which is what Flutter's
      // `showCursor: false` does.
      if (showCursor == false)
        'caret-transparent'
      else
        'caret-${CoreTextAreaStyle.defaultCursorColor.tailwindColor}',
      // Placeholder colour — the `placeholderStyle` slot override wins
      // (token colour → `placeholder:text-*` pseudo-state class, the only
      // surface CSS exposes for `::placeholder`), else the variant token.
      'placeholder:text-$placeholderColorToken',
      // Text-selection tint — pseudo-element class on the token path
      // (byte-identical to before). The `::selection` pseudo-element has
      // no inline-CSS surface, so a raw (token-less) override colour has
      // no `selection:bg-*` class; it is dropped here in the same
      // `token != null` condition and painted via the scoped
      // `#scopeId::selection{…}` rule from `resolveTextAreaRules` instead
      // (class XOR rule — the two resolvers share `selectionColor`).
      if (selectionColor.token != null)
        'selection:bg-${selectionColor.tailwindColor}',
      'text-${vs.foregroundColor}',
      // The wrapper (or the frame) paints the fill, so the `<textarea>` is
      // clear at rest — the browser's own field fill would otherwise show
      // white inside a dark box. The frame of a footed area also paints the
      // disabled fill. The actual disabled instance keeps its textarea
      // clear too, rather than tinting a block inside the box. The enabled
      // path retains its existing classes.
      'bg-transparent',
      if (!hasFooter && enabled) 'disabled:bg-${vs.disabledBackgroundColor}',
      'disabled:text-${vs.disabledForegroundColor}',
      // A disabled placeholder takes the disabled foreground too (#5747) —
      // unless the caller states a placeholder colour, which wins in every
      // state.
      if (placeholderStyle?.color == null)
        'disabled:placeholder:text-${vs.disabledForegroundColor}',
      // The filled variant steps its fill under the pointer (#5747). The
      // fill rides inline, so the hover tone states its precedence.
      if (!hasFooter && vs.hoverBackgroundColor?.token != null)
        'hover:!bg-${vs.hoverBackgroundColor}',
      // Base border colour as a Tailwind class (not inline) so the
      // `focus-visible:border-*` tint below can cascade over it — an
      // inline `border-color` would win and the focus border would never
      // change (#2126). Mirrors text_field's class-based border.
      if (borderColor.token != null) 'border-$borderColor',
      // The focus ring is drawn by the surrounding FocusOutline; we
      // only suppress the browser's default outline and tint the border
      // on focus for parity with the legacy look.
      'outline-none',
      'focus-visible:border-${vs.focusRingColor}',
      hoverBorderClass,
      'disabled:border-${vs.disabledBorderColor}',
      // #3469 — no `disabled:opacity-50`. Dedicated `disabled:bg-*` /
      // `disabled:text-*` / `disabled:border-*` tokens above already
      // carry the state (mirrors text_field's identical fix).
      'disabled:cursor-not-allowed disabled:pointer-events-none',
      '!h-auto',
      resizeClass,
      // Forward `textAlign` only when it differs from the design-system
      // default — `CoreTextAlign.toValue()` doubles as the Tailwind
      // utility key (`center` / `end` / …). The unset path keeps the
      // browser's native start alignment.
      if (textAlign != CoreTextAreaStyle.defaultTextAlign)
        'text-${textAlign.toValue()}',
      // In the text row of a footed area the textarea fills the row's
      // height — the share of the box the footer leaves.
      if (hasFooter) WebLayout.selfStretch,
    ];
    return classList.where((cls) => cls.isNotEmpty).join(' ');
  }

  /// Composes the `<textarea>` inline-CSS bundle — radius / padding /
  /// border / dimensional chrome (all inline, single signature), the
  /// optional background / caret colour overrides, the scroll padding,
  /// the cursor geometry CSS variables (Flutter parity), plus the
  /// per-instance `valueStyle` overrides applied to the editable text.
  ///
  /// The border / background live on the wrapper or the frame, so the
  /// textarea drops its own border and grows to fill the row. Footed, the
  /// frame also takes the padding and the box dimensions, so the textarea
  /// states neither.
  Styles buildTextareaInlineStyles() {
    return .new(
      raw: {
        'transition-duration': durationMsCss(transitionDurationMs),
        'border-radius': borderRadius,
        'padding': hasFooter ? '0' : padding,
        // The box is the wrapper (or the frame): the `<textarea>` draws no
        // border or fill of its own and grows to fill the row.
        'border-width': '0',
        WebLayout.flex: '1',
        'caret-color': ?cursorColor,
        // Obscured rendering — absent on the plain path, so a text area
        // that was never asked to mask emits exactly what it did before.
        '-webkit-text-security': ?textSecurity,
        'scroll-padding': scrollPadding.toValue(),
        // The browser caret exposes only `caret-color` — its thickness and
        // corner rounding are not stylable. The resolved cursor geometry is
        // surfaced as custom properties so Flutter parity is preserved and
        // tooling can read the intended values.
        '--coui-caret-width': '${cursorWidth / kRemDivisor}rem',
        '--coui-caret-radius': cursorRadius,
        '--coui-caret-background-color': ?backgroundCursorColorCss,
        // Initial / min height; the textarea fills its width by default.
        // Footed, the frame is the box and states these instead.
        if (!hasFooter) ...boxDimensions,
        // Vertical alignment of multi-line content within the box.
        'align-content': _verticalAlignCss(textAlignVertical),
        // Explicit scalar overlay on the editable role (font-size / weight
        // when a caller overrides `baseTextStyle`) — the `emitTypography`
        // inline half. The role itself stays on the className.
        ...?baseTypography.inline,
        ...?valueStyle?.toInlineCss(),
      },
    );
  }

  /// The classes of a box that wraps the `<textarea>` — the affix wrapper,
  /// or the frame of a footed area. Shared so the two boxes cannot drift:
  /// they differ only in the state that counts as the box's focus
  /// ([focusTint] / [hoverClass] / [boundaryClass]) and in the disabled
  /// stroke and [fill] the frame states itself.
  List<String> buildWrappingBoxClasses({
    required String restMarker,
    required String hoverMarker,
    required String focusTint,
    required String hoverClass,
    required String boundaryClass,
    required CoreColor fill,
  }) => [
    // Token idle colour stays a class. Raw state values are read on this
    // box so no inline border defeats focus or hover.
    if (stateBorderPath) restMarker else 'border-$frameBorderColor',
    focusTint,
    // The wrapper is the box once framed, so the hover step lands here
    // too (mirrors text_field's identical wrapper hover class).
    hoverClass,
    if (hoverBorderCss != null) hoverMarker,
    // The wrapper is the framed box once the area carries a prefix /
    // suffix or a footer — the marker moves here from `textarea` (see its
    // className builder) rather than doubling up, since only one element
    // is ever rendered as the box.
    if (!fill.isTransparent) ...webSurfaceMarkerFor(.content),
    // The wrapper draws the boundary once framed, while the focused element
    // is the `<textarea>` inside it.
    boundaryClass,
  ];

  /// The inline chrome of a box that wraps the `<textarea>` — radius /
  /// border / [fill] and the boundary layers, shared by the affix wrapper
  /// and the frame of a footed area.
  Map<String, String> buildWrappingBoxInlineStyles(CoreColor fill) => {
    'border-radius': borderRadius,
    'border-style': 'solid',
    'border-width': borderWidthCss,
    // The box's own line width, so a material's edge band reaches the
    // outside of the border instead of one border inside it.
    ...surfaceBleedVar(borderWidthCss),
    // Raw idle/hover colours are read only in their own state, rather than
    // an inline border defeating focus and hover. Token idle paths retain
    // the existing class output even when hover is raw.
    kTextAreaRestBorderVar: ?restBorderCss,
    kTextAreaHoverBorderVar: ?hoverBorderCss,
    'background-color': fill.toValue(),
    // The error boundary's added width, on the element that draws it.
    'box-shadow': ?errorBoundaryShadow,
    // The focused boundary's layer, read by the box's focus class.
    kActiveBoundaryVar: ?focusBoundaryShadow,
    // The marker's other half, moved here alongside the class (see
    // [buildWrappingBoxClasses]).
    if (!fill.isTransparent) ...surfaceFillVar(fill),
  };

  /// Composes the affix wrapper `<div>` Tailwind className — structural
  /// + pseudo-state classes only. Border colour / radius / width /
  /// background / gap chrome live inline (single inline signature); only
  /// the focus-within border tint stays as a pseudo-state class.
  ///
  /// The wrapper draws no ring. The composed `FocusOutline` is its
  /// ancestor and rings the same box, so a `focus-within:ring-*` set
  /// here painted a second ring over the first and, being a class, could
  /// only carry integer scale steps and no offset-band colour.
  /// `focus-within:border-*` is a border tint, not a ring, and stays: it
  /// is this element's CSS-native focus affordance.
  String buildAffixWrapperClassName() => <String>[
    WebLayout.flexItemsCenter,
    ...buildWrappingBoxClasses(
      restMarker: enabled
          ? kTextAreaRestWithinMarker
          : kTextAreaRestDisabledMarker,
      hoverMarker: kTextAreaHoverWithinMarker,
      focusTint: enabled
          ? (rawFocusBorder
                ? kInputFocusBorderWithinMarker
                : 'focus-within:border-$focusBorderToken')
          : '',
      hoverClass: enabled ? hoverBorderWithinClass : hoverBorderClass,
      // The focused element is the `<textarea>` inside the wrapper — so the
      // `:focus-within` marker.
      boundaryClass: focusBoundaryShadow != null
          ? kActiveBoundaryWithinMarker
          : '',
      fill: containerFillCore,
    ),
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the affix wrapper inline-CSS bundle — radius / border /
  /// gap chrome (always inline), the background (override or variant
  /// default) and the `--focus-border-color` CSS variable when a
  /// focus-border override is supplied.
  Styles buildAffixWrapperInlineStyles() => .new(
    raw: {
      ...buildWrappingBoxInlineStyles(containerFillCore),
      'gap': rowSpacingCss,
      kInputFocusBorderVar: ?focusBorderColor,
    },
  );

  /// Composes the frame `<div>` Tailwind className — a column holding the
  /// text row, the gap and the footer, with the wrapping box's classes.
  /// `!h-auto` keeps the height rule the `<textarea>` follows when it is
  /// the box: the content sets the height and `min-height` floors it.
  ///
  /// The frame's focus is its `<textarea>`'s ([_kFrameTextFocus]), not
  /// `:focus-within`: a control in the footer takes focus inside the same
  /// box (tab from the text to the send button), and the box then returns
  /// to rest, as the Flutter twin's does — its focused state follows the
  /// text's focus node alone. Disabled, focus is absent and an explicit
  /// idle border yields to the disabled token on physical hover. It carries the
  /// not-allowed cursor the twin's box shows, over the padding, the gap and
  /// the footer's empty space. The `<textarea>`'s own
  /// `disabled:cursor-not-allowed` never shows: the same element takes no
  /// pointer events while disabled, so the pointer reads the frame's cursor
  /// there too.
  String buildFrameClassName() => <String>[
    WebLayout.flex,
    WebLayout.flexCol,
    ...buildWrappingBoxClasses(
      restMarker: enabled
          ? kTextAreaRestFrameMarker
          : kTextAreaRestDisabledMarker,
      hoverMarker: kTextAreaHoverFrameMarker,
      focusTint: enabled
          ? (rawFocusBorder
                ? kTextAreaFrameFocusBorderMarker
                : '[&$_kFrameTextFocus]:border-$focusBorderToken')
          : '',
      hoverClass: enabled
          ? (hoverFrameToken?.className ?? '')
          : hoverBorderClass,
      // The focused boundary's layer, painted while the frame's own focus
      // holds — the shared `:focus-within` marker would also paint it for a
      // footer control.
      boundaryClass: focusBoundaryShadow != null
          ? kTextAreaFrameBoundaryMarker
          : '',
      fill: frameFillCore,
    ),
    if (!enabled) 'cursor-not-allowed',
    '!h-auto',
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the frame inline-CSS bundle — the wrapping box's chrome plus
  /// the padding and the box dimensions, which leave the `<textarea>` for
  /// the frame: the footer sits inside the same padding as the text, and a
  /// resize or `initialHeight` speaks of the whole box (the Flutter twin
  /// pads the column of text row and footer, inside its sized box).
  Styles buildFrameInlineStyles() => .new(
    raw: {
      ...buildWrappingBoxInlineStyles(frameFillCore),
      'padding': padding,
      kInputFocusBorderVar: ?focusBorderColor,
      ...boxDimensions,
    },
  );

  /// Composes the text row `<div>` Tailwind className — the prefix /
  /// textarea / suffix row, growing into the height the footer leaves, and
  /// the positioning context of the resize-handle indicator. The affixes
  /// sit at the row's top, the way the Flutter twin's row starts its
  /// children.
  String buildTextRowClassName() => [
    WebLayout.flex,
    WebLayout.itemsStart,
    WebLayout.grow,
    WebLayout.relative,
  ].join(' ');

  /// Composes the text row inline-CSS — the row gap between prefix /
  /// textarea / suffix (mirrors Flutter `Row(spacing:)`).
  Styles buildTextRowInlineStyles() => .new(raw: {'gap': rowSpacingCss});

  /// Composes the footer `<div>` Tailwind className — a block across the
  /// box's content width; the footer content lays itself out.
  String buildFooterClassName() => WebLayout.wFull;

  /// Composes the prefix / suffix `<span>` Tailwind className. The muted
  /// glyph colour routes through the Core single-source affix default
  /// (no direct `cs.onSurfaceSubtle`), the same in every state.
  String buildAffixSlotClassName() =>
      '${WebLayout.flex} ${WebLayout.itemsCenter} ${affixColor.className}';

  /// Composes the prefix / suffix inline-CSS — forwards the resolved
  /// icon size so prefix / suffix glyphs match the size token, and the
  /// glyph colour when a raw (token-less) `affixColor` override took the
  /// inline route instead of a class.
  Styles buildAffixSlotInlineStyles() => .new(
    raw: {
      'font-size': '${iconSize / kRemDivisor}rem',
      ...?affixColor.inline,
    },
  );

  /// Composes the resize-handle indicator `<div>` Tailwind className —
  /// absolutely positioned, non-interactive (the native CSS `resize`
  /// grip handles the drag underneath).
  String buildResizeHandleClassName() =>
      '${WebLayout.absolute} ${WebLayout.pointerEventsNone}';

  /// Composes the resize-handle inline-CSS bundle — bottom-right offset
  /// / square size / inner padding (all inline), drawn as two diagonal
  /// lines via a repeating linear-gradient to mirror the Flutter painted
  /// handle.
  Styles buildResizeHandleInlineStyles() => .new(
    raw: {
      'right': '${dragHandleOffset / kRemDivisor}rem',
      'bottom': '${dragHandleOffset / kRemDivisor}rem',
      'width': '${dragHandleSize / kRemDivisor}rem',
      'height': '${dragHandleSize / kRemDivisor}rem',
      'padding': dragHandlePadding.toValue(),
      // Diagonal grip lines — the handle colour comes from the Core
      // single source (override or the `onSurface` default), emitted
      // theme-free as a `rgb(var(--coui-X))` value so dark mode tracks
      // at runtime.
      'background':
          'linear-gradient(135deg, transparent 0, transparent 50%, '
          '${dragHandleColor.toValue()} 50%, '
          'transparent 60%)',
    },
  );

  /// Composes the description `<p>` Tailwind className — the canonical
  /// `emitTypography` role class (merged slot → design-system helper
  /// default) plus the Core single-source muted helper-text colour.
  String buildDescriptionClassName() =>
      '${descriptionTypography.className} ${helperTextColor.className}';

  /// Composes the description `<p>` inline-CSS bundle — the explicit
  /// typography overlay (font-size / weight / raw colour) the
  /// `emitTypography` decision routed inline, under which a raw
  /// `helperTextColor` override (no class for it) sits: the description
  /// slot's own colour outranks the helper colour, as it does on Flutter.
  /// The 1-off spacer above the description is rendered by `co_text_area`
  /// via `Gap` (raw-forwarded `descriptionGapStyle`), not by an inline
  /// `margin-top` here.
  Styles? buildDescriptionInlineStyles() {
    final inline = <String, String>{
      ...?helperTextColor.inline,
      ...?descriptionTypography.inline,
    };
    if (inline.isEmpty) return null;
    return .new(raw: inline);
  }

  /// Composes the error `<p>` Tailwind className — the canonical
  /// `emitTypography` role class (merged slot → shared helper default)
  /// plus the Core single-source error colour.
  String buildErrorClassName() =>
      '${errorTypography.className} ${errorTextColor.className}';

  /// Composes the error `<p>` inline-CSS bundle — the explicit
  /// typography overlay the `emitTypography` decision routed inline.
  /// The 1-off spacer above the error is rendered by `co_text_area`
  /// via `Gap` (raw-forwarded `descriptionGapStyle`), not by an
  /// inline `margin-top` here.
  Styles? buildErrorInlineStyles() {
    final inline = errorTypography.inline;
    if (inline == null || inline.isEmpty) return null;
    return .new(raw: {...inline});
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedTextArea(
    root: WebElementChrome(className: buildRootClassName()),
    formLabelStyle: formLabelStyle,
    labelHost: WebElementChrome(className: buildLabelHostClassName()),
    textarea: WebElementChrome(
      className: buildTextareaClassName(),
      inlineStyles: buildTextareaInlineStyles(),
    ),
    affixWrapper: WebElementChrome(
      className: buildAffixWrapperClassName(),
      inlineStyles: buildAffixWrapperInlineStyles(),
    ),
    affixSlot: WebElementChrome(
      className: buildAffixSlotClassName(),
      inlineStyles: buildAffixSlotInlineStyles(),
    ),
    frame: WebElementChrome(
      className: buildFrameClassName(),
      inlineStyles: buildFrameInlineStyles(),
    ),
    textRow: WebElementChrome(
      className: buildTextRowClassName(),
      inlineStyles: buildTextRowInlineStyles(),
    ),
    footer: WebElementChrome(className: buildFooterClassName()),
    resizeHandle: WebElementChrome(
      className: buildResizeHandleClassName(),
      inlineStyles: buildResizeHandleInlineStyles(),
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: buildDescriptionInlineStyles(),
    ),
    error: WebElementChrome(
      className: buildErrorClassName(),
      inlineStyles: buildErrorInlineStyles(),
    ),
    helperRow: const WebElementChrome(
      className:
          '${WebLayout.flex} ${WebLayout.itemsStart} '
          '${WebLayout.justifyBetween} w-full',
    ),
    counter: WebElementChrome(
      className: '${counterTypography.className} ${WebLayout.shrinkZero}',
      inlineStyles: switch (counterTypography.inline) {
        null => null,
        final inline => Styles(raw: inline),
      },
    ),
    focusOutlineStyle: forwardedFocusOutlineStyle,
    labelGapStyle: labelGapStyle,
    descriptionGapStyle: descriptionGapStyle,
    footerGapStyle: footerGapStyle,
    counterGapStyle: counterGapStyle,
  );
}

/// Resolves the scoped `::selection` rule for a `TextArea` whose
/// selection tint (`selectionColor`) override is a raw, token-less
/// colour. Returns empty CSS on the default / token path — `resolveTextArea`
/// keeps the `selection:bg-*` class in that case (class XOR rule).
///
/// The merge chain mirrors [resolveTextArea] exactly ([hasError] threads
/// through so a `variantStyles[hasError].selectionColor` override is
/// honoured), so the class-drop condition and the scoped rule always see
/// the same resolved selection colour. The 20%-alpha treatment matches
/// the class path (`scaleAlpha(CoreOpacity.opacity20)`) and the Flutter
/// resolver so both platforms paint the same highlight.
ResolvedTextAreaRules resolveTextAreaRules(
  BuildContext context, {
  required String scopeId,
  required bool hasError,
  bool enabled = true,
  CoreTextAreaStyle? textAreaStyle,
}) {
  final areaTheme = context.theme.coreComponentTheme?.textArea;

  // ─── Merge chain (mirrors resolveTextArea) ────────────
  // Same `disabled > error` gate as `resolveTextArea`, so a disabled area
  // reads the same Theme row here as there.
  final merged = resolveStyleChain(const CoreTextAreaStyle(), [
    areaTheme?.style,
    areaTheme?.variantStyles?[CoreTextFieldVariant.showsErrorChrome(
      hasError: hasError,
      enabled: enabled,
    )],
    textAreaStyle,
  ]);

  // ─── Accumulate scoped rules ──────────────────────────
  final buffer = StringBuffer();

  // Selection tint — token colour rides the `selection:bg-*` class in
  // `resolveTextArea`; a raw override has no `::selection` class surface
  // and produces a `#scopeId::selection{background-color: …}` rule here.
  final selectionEmit = emitPseudoColor(
    merged.selectionColor?.scaleAlpha(CoreOpacity.opacity20),
    CoreTextAreaStyle.defaultSelectionColor.scaleAlpha(CoreOpacity.opacity20),
    .background,
    pseudo: .selection,
    scopeSelector: '#$scopeId',
  );
  buffer.write(selectionEmit.rule);

  return ResolvedTextAreaRules(css: buffer.toString());
}

// ═══════════════════════════════════════════════════
// File-private helpers
// ═══════════════════════════════════════════════════

/// The focus of a footed area's frame — its `<textarea>`'s, reached through
/// the text row (the frame's first child) so a `<textarea>` the caller puts
/// in the footer does not count. `:focus-visible` is the pseudo the bare
/// `<textarea>` keys its own focus tint on, and a text control matches it on
/// any focus, pointer or keyboard.
const String _kFrameTextFocus = kTextAreaFrameFocusSelector;

/// Keeps the frame's existing main-textarea focus exclusion, while the
/// canonical emitter owns the token colour class and its opacity suffix.
PseudoEmit _textAreaFrameHover(PseudoEmit hover) {
  final className = hover.className;
  assert(
    hover.rule.isEmpty,
    'The frame adapter requires token-only hover emission.',
  );
  assert(
    className.startsWith(WebPseudo.hover.classPrefix),
    'The frame adapter requires the canonical hover prefix.',
  );
  assert(
    !className.contains(' '),
    'The frame adapter requires one canonical hover class.',
  );
  return (
    className:
        '[&:hover:not($_kFrameTextFocus)]:'
        '${className.substring(WebPseudo.hover.classPrefix.length)}',
    rule: hover.rule,
  );
}

/// Returns `'${px / kRemDivisor}rem'` for a finite override, or `null`
/// for an unset / infinite value (so the inline-CSS map drops the
/// property and the element defers to its natural fill / unbounded
/// size).
String? _remOrNull(double? px) {
  if (px == null || !px.isFinite) return null;
  return '${px / kRemDivisor}rem';
}

/// Maps an obscuring character to the `-webkit-text-security` shape that
/// draws it.
///
/// The property takes one of three shapes rather than a glyph, so a
/// character outside the mapped set falls back to `disc` — the round dot
/// [CoreTextAreaContract.defaultObscuringCharacter] states, which is what
/// a caller asking to mask a field almost always means. Naming the
/// fallback here rather than throwing keeps an unmappable character a
/// masked area instead of an unmasked one.
String _textSecurityCss(String character) => switch (character) {
  '◦' || '○' || '◯' => 'circle',
  '▪' || '■' || '□' => 'square',
  _ => 'disc',
};

/// Maps a [CoreVerticalAlign] to the CSS `align-content` keyword used to
/// vertically position multi-line content inside the resizable box.
String _verticalAlignCss(CoreVerticalAlign align) => switch (align) {
  .top => 'flex-start',
  .center => 'center',
  .bottom => 'flex-end',
};
