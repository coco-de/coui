/// Style-slot single entry point for the Web `Toast`.
///
/// Holds the merge chain (`resolveToast`), the CSS-ready resolver
/// output (`ResolvedToast`), and the per-element [WebElementChrome]
/// slots. No `Styling` marker interface — Flutter/Web share the same
/// single typed `toastStyle: CoreToastStyle?` field.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ════════════════════════════════════════════════════════════════
// ResolvedToast — paint-ready chrome (full element slots)
// ════════════════════════════════════════════════════════════════

/// Paint-ready chrome for Web `Toast`.
///
/// DOM shape:
///
/// ```text
/// root (<div role="status">)                      // toast container
///   ├─ content (<div flex column>)                 // content column
///   │    ├─ message (<div>)                        // message text
///   │    ├─ Gap (messageDescriptionGapStyle)     // co_toast renders only when description != null
///   │    └─ description (<div>)                    // co_toast renders only when description != null
///   ├─ Gap (contentActionGapStyle)               // co_toast renders only when action != null
///   ├─ action (caller-supplied Component)          // co_toast renders only when action != null
///   └─ closeWrapper (<div absolute>)               // co_toast renders only when onDismiss != null
///        └─ Button.plain (closeButtonStyle)       // dismiss affordance
///             └─ Icon(closeButtonStyle.leadingIconStyle)
/// ```
///
/// All slot chromes are non-null — `co_toast` decides whether to
/// render each optional slot based on instance state.
///
/// Per Epic #1603 (옵션 B 최종, single inline signature) every
/// dimensional chrome value (border radius / padding / border width /
/// close inset) is emitted **inline** through
/// `(merged.X ?? CoreToastStyle.defaultX)` — no class-drop branch
/// decides between a Tailwind utility and an inline rule. Only colour /
/// typography token classes (`bg-` / `text-` / `border-` / `font-`),
/// pseudo-state (`hover:` / `focus:`) and structural (`flex` /
/// `absolute` / `transition-*`) classes remain on the className
/// surface.
///
/// The resolver carries only:
/// * Cat 1 — `WebElementChrome` slots (paint-ready chrome).
/// * Cat 2 — nested `CoreXxxStyle` slots passed to child unified
///   widgets. [messageDescriptionGapStyle] and [contentActionGapStyle]
///   are forwarded to `Gap(gapStyle: …)`; [closeButtonStyle] is
///   raw-forwarded to `Button(variant: .plain, buttonStyle: …)` for
///   the dismiss affordance; [actionButtonStyle] is forwarded to the
///   action when it is a `Button`.
///
/// No scalar metadata (variant / typography / dismissible / icon size)
/// is exposed — semantic identifiers stay on the widget prop.
class ResolvedToast implements WebResolvedChrome {
  /// Creates a [ResolvedToast].
  const ResolvedToast({
    required this.root,
    required this.content,
    required this.message,
    required this.description,
    required this.closeWrapper,
    required this.messageDescriptionGapStyle,
    required this.contentActionGapStyle,
    required this.iconStyle,
    required this.iconContentGapStyle,
    required this.closeButtonStyle,
    required this.actionButtonStyle,
    required this.plainActionButtonStyle,
  });

  /// Paint-ready chrome for the outermost `<div role="status">` toast
  /// container.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the content-column `<div>` hosting the
  /// message + description stack.
  final WebElementChrome content;

  /// Paint-ready chrome for the message text `<div>`.
  final WebElementChrome message;

  /// Paint-ready chrome for the description text `<div>` — `co_toast`
  /// skips this element when `description == null`.
  final WebElementChrome description;

  /// Paint-ready chrome for the absolutely-positioned dismiss-button
  /// wrapper `<div>` — places the `Button(variant: .plain)` at the trailing
  /// inset, centred on the block axis, via the resolved
  /// [CoreToastStyle.closeInset].
  /// `co_toast` skips this element when `onDismiss == null`. This wrapper
  /// is panel-layout chrome only; the button's own chrome lives in
  /// [closeButtonStyle].
  final WebElementChrome closeWrapper;

  /// Nested [CoreGapStyle] slot — forwarded to `Gap(gapStyle: …)`
  /// between message and description. `co_toast` only renders this
  /// spacer when `description != null`.
  final CoreGapStyle messageDescriptionGapStyle;

  /// Nested [CoreGapStyle] slot — forwarded to `Gap(gapStyle: …)`
  /// between the content column and the action. `co_toast` only renders
  /// this spacer when `action != null`.
  final CoreGapStyle contentActionGapStyle;

  /// Nested [CoreIconStyle] for the leading glyph, or `null` on the
  /// variant that draws none.
  ///
  /// The variant row's colour (the message colour) merged onto the shared
  /// size. All three variants fill with the same inverse surface, so the
  /// glyph's shape tells them apart — `null` means no glyph and no gap,
  /// not an invisible one.
  final CoreIconStyle? iconStyle;

  /// Nested [CoreGapStyle] for the glyph → content spacer.
  final CoreGapStyle iconContentGapStyle;

  /// Nested [CoreButtonStyle] slot for the dismiss affordance —
  /// raw-forwarded to `Button(variant: .plain, buttonStyle: …)`. The
  /// `plain` variant owns the resting-opacity / hover-fade / foreground
  /// semantics; this chained-and-tinted slot adds the tap-target
  /// padding, the close glyph (`leadingIconStyle`), the hover transition
  /// (`animationDuration`), the focus-ring width
  /// (`focusOutlineStyle.borderWidth`), and the variant foreground
  /// (`foregroundColor` / `hoverForegroundColor`). `Button` resolves
  /// its own internals.
  final CoreButtonStyle closeButtonStyle;

  /// Nested [CoreButtonStyle] slot — forwarded to the action when it is
  /// a `Button`. Never null: it always carries at least the variant
  /// foreground, so a caller's page-surface button reads on the slab.
  final CoreButtonStyle actionButtonStyle;

  /// [actionButtonStyle] plus the inline inset a `plain` action needs —
  /// the bundle the widget forwards when the action is a `plain` `Button`.
  final CoreButtonStyle plainActionButtonStyle;
}

// ════════════════════════════════════════════════════════════════
// resolveToast — single entry point
// ════════════════════════════════════════════════════════════════

/// Resolves [ResolvedToast] for the given Web [context].
///
/// Walks the merge chain plus `CoreToastStyle.defaultsByVariant`
/// fallback once — `co_toast.dart` reads `resolved.X.className /
/// inlineStyles` only and never touches `theme.coreComponentTheme`
/// directly.
///
/// ```text
/// design system default for variant
///   → theme.coreComponentTheme.toast.style
///   → theme.coreComponentTheme.toast.variantStyles[variant]
///   → widget.toastStyle
/// ```
///
/// The semantic [variant] is a widget prop — it threads through to
/// pick the variant token table here. The theme cannot override it
/// (Epic #1603 옵션 B 최종).
ResolvedToast resolveToast(
  BuildContext context, {
  required CoreToastVariant variant,
  required bool dismissible,
  CoreToastStyle? toastStyle,
}) {
  final toastTheme = context.theme.coreComponentTheme?.toast;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreToastStyle(), [
    toastTheme?.style,
    toastTheme?.variantStyles?[variant],
    toastStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  final variantStyle = CoreToastStyle.defaultsByVariant[variant]!;
  final descriptionColor =
      variantStyle.descriptionForeground ?? variantStyle.foregroundColor;

  // ─── Colour emit (token → class, raw override → inline) ─
  // EMIT (Web, theme-free) — `emitColor(override, default, target)` is
  // the single canonical colour path: a token value (variant default or
  // token override) emits a `bg-/text-/border-{token}` class that the
  // browser resolves at runtime (dark-mode reactive); a raw override
  // emits inline. No `scheme.resolve` (a no-op on Web).
  final backgroundEmit = emitColor(
    merged.panelBackgroundColor,
    variantStyle.backgroundColor,
    .background,
  );
  final foregroundEmit = emitColor(null, variantStyle.foregroundColor, .text);
  final borderEmit = emitColor(
    merged.panelBorderColor,
    variantStyle.borderColor,
    .border,
  );
  final descriptionColorEmit = emitColor(null, descriptionColor, .text);

  // ─── Resolved chrome values (single inline signature) ──
  // Every dimensional value below is `(merged.X ?? default)` and is
  // emitted inline via `.toValue()` / rem — no class-drop branch.

  // Panel radius / padding / border width — always inline. The
  // dismiss-aware padding selects `panelPaddingWithDismiss` (else
  // `panelPadding`) so both override slots stay reachable (Epic #1603
  // coverage gate).
  final borderRadius =
      (merged.panelBorderRadius ?? CoreToastStyle.defaultPanelBorderRadius)
          .toValue();
  // Logical longhands: the dismissible variant reserves room for the
  // close affordance, which sits at the end — the right in English and
  // the left in Arabic. A physical shorthand reserved it on the wrong
  // side there, with the button overlapping the text.
  final padding =
      (dismissible
              ? (merged.panelPaddingWithDismiss ??
                    CoreToastStyle.defaultPanelPaddingWithDismiss)
              : (merged.panelPadding ?? CoreToastStyle.defaultPanelPadding))
          .toLogicalDeclarations('padding');
  final minHeight = merged.minHeight ?? CoreToastStyle.defaultMinHeight;
  final borderWidth =
      merged.panelBorderWidth ?? CoreToastStyle.defaultPanelBorderWidth;

  // Nested [CoreGapStyle] slots — design-system default merged with the
  // per-instance override, forwarded *raw* to `Gap(gapStyle: …)` in
  // the widget (Epic #1603 옵션 B nested-slot pattern). `Gap` owns
  // its own layout, so no inline `gap` CSS is emitted on the parent
  // containers.
  final contentActionGapStyle = CoreToastStyle.defaultContentActionGapStyle
      .merge(merged.contentActionGapStyle);
  final iconContentGapStyle = CoreToastStyle.defaultIconContentGapStyle.merge(
    merged.iconContentGapStyle,
  );
  // The variant's glyph colour folded onto the shared size. `null` when the
  // variant states no colour — that variant draws no glyph, so there is
  // nothing to style and nothing to space.
  final iconStyle = variantStyle.iconColor == null
      ? null
      : CoreToastStyle.defaultIconStyle
            .merge(merged.iconStyle)
            .merge(CoreIconStyle(color: variantStyle.iconColor));
  final messageDescriptionGapStyle = CoreToastStyle
      .defaultMessageDescriptionGapStyle
      .merge(
        merged.messageDescriptionGapStyle,
      );

  // Dismiss-button wrapper inset — a four-sided `CoreEdgeInsets` so
  // callers can shift the dismiss button on any axis; the wrapper
  // inline-CSS builder reads `top` / `right` (default
  // `CoreEdgeInsets.all(8)` so the same value lands on every side). This
  // is panel layout (it positions the dismiss button), not button
  // chrome.
  final closeInset = merged.closeInset ?? CoreToastStyle.defaultCloseInset;
  // Dismiss-button chrome — chained `defaultCloseButtonStyle` (zero-pad
  // tap target + 16-px close glyph + 150 ms hover + 2-px focus ring),
  // tinted with the per-variant close colours (`inverseOnSurface` at
  // 70 % resting → full on hover, so the glyph reads on the inverse fill
  // the `plain` default was not chosen for), then the
  // per-instance override on top. Raw-forwarded to
  // `Button(variant: .plain, buttonStyle: …)` — the button resolves its
  // own padding / icon / hover-fade / focus-ring (mirrors the chip
  // remove button).
  final closeButtonStyle = CoreToastStyle.defaultCloseButtonStyle
      .merge(
        CoreButtonStyle(
          foregroundColor: variantStyle.closeForeground,
          hoverForegroundColor: variantStyle.closeHoverForeground,
        ),
      )
      .merge(merged.closeButtonStyle);
  // Action chrome — the variant foreground injected UNDER the caller's
  // slot, for the reason the close button above injects its own: a
  // `Button` action is built against the page surface, and the toast
  // states what legible means on its own slab. Merge order keeps the
  // caller's slot — and, in the widget, the action's own `buttonStyle` —
  // winning. Raw-forwarded.
  //
  // Underneath it all sits `defaultActionButtonStyle`, whose opaque
  // focus-ring gap band keeps the ring readable on the slab — a
  // transparent gap would put the slab colour between the action and its
  // ring, and the ring would read as part of the slab rather than as a
  // mark on the control.
  // The banner/toast foreground every action wears — shared by the two
  // bundles below so the plain one cannot drift from the other.
  final actionForegroundStyle = CoreButtonStyle(
    foregroundColor: variantStyle.foregroundColor,
    hoverForegroundColor: variantStyle.foregroundColor,
  );
  final actionButtonStyle = CoreToastStyle.defaultActionButtonStyle
      .merge(actionForegroundStyle)
      .merge(merged.actionButtonStyle);
  // A `plain` action gets the inline inset its variant lacks — and only
  // it; every other variant keeps its own size row's inset. The caller's
  // `actionButtonStyle` still wins over that default, the plain slot over
  // both. The widget picks between the two by the action's variant.
  final plainActionButtonStyle = CoreToastStyle.defaultActionButtonStyle
      .merge(CoreToastStyle.defaultPlainActionButtonStyle)
      .merge(actionForegroundStyle)
      .merge(merged.actionButtonStyle)
      .merge(merged.plainActionButtonStyle);

  // Panel chrome transition — duration class carries the merged ms.
  final transitionDurationMs =
      (merged.transitionDuration ?? CoreToastStyle.defaultTransitionDuration)
          .inMilliseconds;

  // Shadow — merged-or-default layers, tinted by the palette's `shadow`
  // token exactly as the Flutter twin tints them, and routed through
  // `emitShadow` so a scale step reads `var(--shadow-<step>)`: the active
  // surface style's bend and the dark scope's shadow strength reach it
  // the way they reach every other routed panel.
  final shadowLayers =
      merged.panelBoxShadow ?? CoreToastStyle.defaultPanelBoxShadow;
  final boxShadowCss = emitShadow(shadowLayers, base: kShadowVariableBase);

  // ─── Slot typography (single canonical emit) ──────────
  // `emitTypography(override, default)` emits the role on a `text-{role}`
  // class (dark-mode / accessibility-scale reactive, inherited by the
  // inner `Text`) AND any explicit scalar overlay (font-size / weight /
  // spacing) inline. The message default = `labelLarge` with its
  // bold weight emitted inline; the description role default = `bodySmall`. No
  // hand-rolled `text-${...token!.name}` role class.
  final messageEmit = emitTypography(
    merged.messageStyle,
    CoreToastStyle.defaultMessageStyle,
  );
  final descriptionEmit = emitTypography(
    merged.descriptionStyle,
    CoreToastStyle.defaultDescriptionStyle,
  );
  // An explicitly authored description color owns this text face rather
  // than competing with the variant's fallback color class.
  final descriptionOverridesColor = merged.descriptionStyle?.color != null;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer toast container `<div>` Tailwind className —
  /// structural + colour token classes only. Chrome dimensions
  /// (radius / padding / border width / gap / shadow / transition
  /// duration) all live inline.
  String buildRootClassName() => <String>[
    // A toast floats over the page and then leaves; what is behind it is
    // whatever the user was already reading. Paired with the fill
    // published below — the marker alone resolves a preset's restated
    // colour to nothing and the panel loses its background.
    ...webSurfaceMarkerFor(CoreSurfaceRole.functional),
    'group pointer-events-auto',
    WebLayout.relative,
    WebLayout.flex,
    WebLayout.itemsCenter,
    WebLayout.wFull,
    '${WebLayout.itemsCenter} ${WebLayout.justifyBetween}',
    WebLayout.overflowHidden,
    'border',
    'transition-all',
    backgroundEmit.className,
    foregroundEmit.className,
    borderEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the outer toast container inline-CSS bundle — every
  /// chrome dimension (single inline signature) plus the colour
  /// overrides (when set) and the chrome transition duration. The
  /// content-column ↔ action spacer is no longer an inline `gap` here:
  /// `co_toast.dart` interleaves a `Gap(gapStyle:
  /// resolved.contentActionGapStyle)` between the content column and
  /// the action so the spacer goes through the unified gap widget
  /// (Epic #1603 옵션 B nested-slot pattern).
  Styles buildRootInlineStyles() => .new(
    raw: {
      // Drop shadow parity with Flutter Toast (token-driven), with the
      // rim appended: now that this panel carries the surface marker, a
      // material whose one defining statement is an inset rim would
      // otherwise never reach its shadow.
      'box-shadow': '$boxShadowCss, $kSurfaceRimVar',
      'border-radius': borderRadius,
      ...padding,
      // The panel floor — a one-line toast is shorter than this on
      // padding alone, and the row's `items-center` centres the content
      // in what the floor leaves (Flutter: `ConstrainedBox(minHeight:)`
      // over a centre-aligned Row).
      'min-height': '${minHeight / kRemDivisor}rem',
      'border-width': strokeWidthCss(borderWidth),
      'transition-duration': '${transitionDurationMs}ms',
      // Emit-family inline fragments — only a raw (non-token) colour
      // override contributes here; a token value stays on the class above.
      ...?backgroundEmit.inline,
      ...?borderEmit.inline,
      // The marker's other half: a preset restates this fill at a lower
      // alpha and cannot know which token the variant chose, so the
      // panel publishes the triplet itself.
      ...surfaceFillVar(
        merged.panelBackgroundColor ?? variantStyle.backgroundColor,
      ),
    },
  );

  /// Composes the content-column `<div>` Tailwind className —
  /// structural only; the message ↔ description spacer is rendered as
  /// a nested `Gap(gapStyle: resolved.messageDescriptionGapStyle)`
  /// (Epic #1603 옵션 B nested-slot pattern), so no inline `gap` lives
  /// here.
  String buildContentClassName() =>
      '${WebLayout.flex} ${WebLayout.flexCol} '
      '${WebLayout.flex1} ${WebLayout.minWZero}';

  /// Composes the message slot `<div>` Tailwind className — the message
  /// typography role class ([messageEmit], inherited by the inner
  /// `Text`); a per-instance scalar overlay emits inline.
  String buildMessageClassName() => messageEmit.className;

  /// Composes the description slot `<div>` Tailwind className — the
  /// description typography role class ([descriptionEmit]) plus the
  /// variant description colour class ([descriptionColorEmit]).
  String buildDescriptionClassName() => <String>[
    descriptionEmit.className,
    if (!descriptionOverridesColor) descriptionColorEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the absolutely-positioned dismiss-button wrapper `<div>`
  /// Tailwind className — structural only (`absolute` + a flex row that
  /// centres its one child on the block axis). The button's own chrome
  /// (hover-fade / focus-ring / cursor / circle) is owned by the
  /// `Button(variant: .plain, shape: .square)` inside it; this wrapper only
  /// places it — at the trailing inset, centred in the band the block
  /// insets leave (the Flutter twin's `Position` + `Align`).
  String buildCloseWrapperClassName() =>
      '${WebLayout.absolute} ${WebLayout.flex} ${WebLayout.itemsCenter}';

  /// Composes the dismiss-button wrapper inline-CSS bundle — the
  /// per-side inset only. Reads `closeInset.top` / `closeInset.bottom` /
  /// `closeInset.right` (default 8 at the trailing edge, 0 on the block
  /// axis, so the band is the panel's whole height). The sides ride
  /// `spaceCss` — the Flutter twin converts the same `CoreEdgeInsets`
  /// through the theme geometry, so a density moves the button there, and
  /// with it the panel padding that leaves the button its room.
  Styles buildCloseWrapperInlineStyles() => .new(
    raw: {
      'right': spaceCss(closeInset.right),
      'top': spaceCss(closeInset.top),
      'bottom': spaceCss(closeInset.bottom),
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedToast(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    content: WebElementChrome(
      className: buildContentClassName(),
    ),
    message: WebElementChrome(
      className: buildMessageClassName(),
      inlineStyles: messageEmit.inline == null
          ? null
          : Styles(raw: messageEmit.inline),
    ),
    description: WebElementChrome(
      className: buildDescriptionClassName(),
      inlineStyles: descriptionEmit.inline == null
          ? null
          : Styles(raw: descriptionEmit.inline),
    ),
    closeWrapper: WebElementChrome(
      className: buildCloseWrapperClassName(),
      inlineStyles: buildCloseWrapperInlineStyles(),
    ),
    messageDescriptionGapStyle: messageDescriptionGapStyle,
    contentActionGapStyle: contentActionGapStyle,
    iconStyle: iconStyle,
    iconContentGapStyle: iconContentGapStyle,
    closeButtonStyle: closeButtonStyle,
    actionButtonStyle: actionButtonStyle,
    plainActionButtonStyle: plainActionButtonStyle,
  );
}
