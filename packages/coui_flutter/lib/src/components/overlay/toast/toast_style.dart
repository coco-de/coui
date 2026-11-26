import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `Toast`.
///
/// Widget tree (`toast.dart` decides which optional branches render):
///
/// ```text
/// optional InjectedCast (shadow) >                   // rendered only when castOutsideBox
/// optional SurfaceBlur (surfaceBlur / surfaceSheen) > // rendered only when a blur or a sheen is set
/// InsetShadow (insetBoxShadow — the style's rim, over the panel)
///   └─ DecoratedBox (background / border / borderRadius / shadow unless castOutsideBox)
///        └─ Padding (padding)
///             └─ Stacks
///                  ├─ Row
///                  │    ├─ Expanded > Column
///                  │    │    ├─ DefaultTextStyle (messageStyle)
///                  │    │    │    └─ Text (message)
///                  │    │    ├─ Gap (messageDescriptionGapStyle)  // when description != null
///                  │    │    └─ DefaultTextStyle (descriptionStyle)
///                  │    │         └─ Text (description)   // rendered only when description != null
///                  │    ├─ Gap (contentActionGapStyle)  // when action != null
///                  │    └─ action                         // rendered only when action != null
///                  └─ Position > Button.plain         // rendered only when onDismiss != null
///                       └─ Icon (closeButtonStyle.leadingIconStyle)
/// ```
///
/// Every field is paint-ready: Flutter framework widgets receive their
/// native type (`Color`, `BorderRadius`, `EdgeInsets`, `TextStyle`,
/// `List<BoxShadow>`); the dismiss affordance is a unified
/// `Button(variant: .plain)` that receives its [closeButtonStyle]
/// nested `CoreButtonStyle` slot *raw* (the button resolves its own
/// padding / close glyph / hover-fade / focus-ring); the inter-slot
/// spacers receive nested [CoreGapStyle] slots forwarded straight to
/// `Gap(gapStyle: …)` (Epic #1603 옵션 B — `Gap` / `Button`
/// self-scale, so those slots are forwarded *raw*, no `* scaling`).
/// Scaling is pre-applied on the flat chrome values ([borderRadius] /
/// [padding] / [closeInset]).
class ResolvedToast {
  /// Creates a [ResolvedToast].
  const ResolvedToast({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
    required this.minHeight,
    required this.messageDescriptionGapStyle,
    required this.contentActionGapStyle,
    required this.iconStyle,
    required this.iconContentGapStyle,
    required this.closeInset,
    required this.closeButtonStyle,
    required this.transitionDuration,
    required this.shadow,
    required this.messageStyle,
    required this.descriptionStyle,
    required this.actionButtonStyle,
    required this.plainActionButtonStyle,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
    required this.insetBoxShadow,
    this.castOutsideBox = false,
  });

  /// Backdrop blur sigma for the toast panel, `null` when the active
  /// theme states no material or the panel states no fill to blur
  /// behind.
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  ///
  /// Rides the same backdrop pass as [surfaceSaturation].
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  // ── Chrome (token-fallback applied) ───────────

  /// Effective panel background colour.
  final Color backgroundColor;

  /// Effective panel border colour.
  final Color borderColor;

  /// Effective panel border stroke width (logical px). Border width is
  /// a physical hairline, deliberately left unscaled.
  final double borderWidth;

  /// Effective panel border radius (scaling pre-applied).
  final BorderRadius borderRadius;

  /// Effective panel content padding (scaling pre-applied).
  final EdgeInsetsGeometry padding;

  /// Panel minimum height (scaled) — the floor that keeps a one-line
  /// toast the same height as one carrying an action.
  final double minHeight;

  // ── Nested [CoreGapStyle] slots (forwarded to Gap raw) ─

  /// Nested [CoreGapStyle] for the message → description spacer —
  /// forwarded straight to `Gap(gapStyle: …)` between the two text
  /// rows. `Gap` self-applies `theme.scaling`, so this slot is the
  /// merged default-or-override *raw* (no `* scaling` here).
  final CoreGapStyle messageDescriptionGapStyle;

  /// Nested [CoreIconStyle] for the leading glyph, or `null` on the
  /// variant that draws none.
  ///
  /// Carries the variant row's colour (the message colour) merged onto the
  /// shared size — the glyph's shape is what tells the three variants
  /// apart, since all three fill with the same inverse surface. `null`
  /// means no glyph and no gap, not an invisible one.
  final CoreIconStyle? iconStyle;

  /// Nested [CoreGapStyle] for the glyph → content spacer. Forwarded raw
  /// (see [messageDescriptionGapStyle]).
  final CoreGapStyle iconContentGapStyle;

  /// Nested [CoreGapStyle] for the content-column → action spacer —
  /// forwarded straight to `Gap(gapStyle: …)` between the content
  /// column and the action widget. Forwarded raw (see
  /// [messageDescriptionGapStyle]).
  final CoreGapStyle contentActionGapStyle;

  // ── Dimensional (scaling pre-applied) ─────────

  /// Close button inset from the panel edges (paint-ready [EdgeInsets],
  /// scaling pre-applied) — `co_toast` reads `top` / `right` to anchor
  /// the dismiss `Button` inside the padding region, but callers can
  /// override any axis. This is panel-layout chrome (it positions the
  /// dismiss button), not button chrome — the button's own chrome lives
  /// in [closeButtonStyle].
  final EdgeInsets closeInset;

  // ── Nested dismiss-button slot (forwarded to Button raw) ─

  /// Nested [CoreButtonStyle] for the dismiss affordance — raw-forwarded
  /// to `Button(variant: .plain, buttonStyle: …)`. The `plain` variant
  /// owns the resting-opacity / hover-fade / foreground semantics; this
  /// chained-and-tinted slot adds the tap-target padding, the close glyph
  /// (`leadingIconStyle`), the hover transition (`animationDuration`),
  /// the focus-ring width (`focusOutlineStyle.borderWidth`), and the
  /// variant foreground (`foregroundColor` / `hoverForegroundColor` so
  /// the glyph tracks the toast variant). `Button` self-applies
  /// `theme.scaling`, so this slot is forwarded *raw* (no `* scaling`).
  final CoreButtonStyle closeButtonStyle;

  /// Container chrome transition duration — drives the panel's open /
  /// close animation envelope.
  final Duration transitionDuration;

  /// Drop-shadow stack under the panel (scaling pre-applied, tinted).
  /// Consumed by the panel's `BoxDecoration.boxShadow`, or by
  /// `InjectedCast` where [castOutsideBox].
  final List<BoxShadow> shadow;

  /// Whether [shadow] is painted outside the box (`InjectedCast`) rather
  /// than by the panel's `BoxDecoration`.
  ///
  /// True where [backgroundColor] is not opaque. A decoration's shadow is a
  /// filled shape behind the box, so it shows through a translucent fill —
  /// on Flutter only, because CSS paints an outer shadow outside the border
  /// box. An opaque fill hides it, and the panel keeps the plain tree.
  final bool castOutsideBox;

  /// The active style's inset rim, drawn over the panel — empty under
  /// every style that states none.
  ///
  /// A toast casts (`panelBoxShadow` is a real stack), and a rim decorates
  /// a surface that casts — `resolveSurfaceRim` gates on that stack, the
  /// same gate every panel that reads the rim goes through. The Web twin
  /// appends `kSurfaceRimVar` to the same panel's `box-shadow`; without
  /// this the rim reached the toast on one platform only.
  final List<BoxShadow> insetBoxShadow;

  // ── Resolved slot text styles ─────────────────

  /// Fully-resolved message (primary text) style.
  final TextStyle messageStyle;

  /// Fully-resolved description (secondary text) style.
  final TextStyle descriptionStyle;

  /// Nested [CoreButtonStyle] slot — forwarded to the action when it is
  /// a `Button`. Never null: it always carries at least the variant
  /// foreground, so a caller's page-surface button reads on the slab.
  final CoreButtonStyle actionButtonStyle;

  /// [actionButtonStyle] plus the inline inset a `plain` action needs —
  /// the bundle the widget forwards when the action is a `plain` `Button`.
  final CoreButtonStyle plainActionButtonStyle;
}

// ═══════════════════════════════════════════════════
// resolveToast — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedToast] for the given [context] and [variant].
///
/// Single entry point — reads [CoreToastTheme] from
/// `Theme.of(context).coreComponentTheme` itself so callers never touch
/// `coreComponentTheme` directly. Walks the nested-merge chain plus
/// `CoreToastStyle.defaultX` / `defaultsByVariant` fallback in one pass:
///
/// ```text
/// CoreToastStyle.defaultX / defaultsByVariant
///   → theme.coreComponentTheme.toast.style
///   → theme.coreComponentTheme.toast.variantStyles[variant]
///   → widget.toastStyle
/// ```
ResolvedToast resolveToast(
  BuildContext context, {
  required CoreToastVariant variant,
  required bool dismissible,
  CoreToastStyle? toastStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final toastTheme = theme.coreComponentTheme?.toast;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreToastStyle(), [
    toastTheme?.style,
    toastTheme?.variantStyles?[variant],
    toastStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  // Variant chrome — single source of truth.
  final chrome = CoreToastStyle.defaultsByVariant[variant]!;

  // ─── Resolved chrome (scheme.resolve(token).toValue() — C7) ─
  // Both halves of the material come off the theme: translucency
  // without a blur is a lighter panel, and a blur behind an opaque fill
  // is painted and then covered.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다 — 역할을 안 쓰는
  // 프리셋에게 이 축은 공짜다.
  final material = theme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = material?.opacityIn(theme);
  final backgroundCore = merged.panelBackgroundColor ?? chrome.backgroundColor;
  final backgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? backgroundCore
            : backgroundCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  // Gated on the fill — a panel that states none has nothing to blur
  // behind and nothing to light the edge of, and handing it a material
  // draws a squared band around a box that is not there.
  final hasFill = backgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill
      ? resolveSurfaceSheen(theme, role: CoreSurfaceRole.functional)
      : null;
  final foregroundColor = scheme.resolve(chrome.foregroundColor).toValue();
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border, and a surface that skips this keeps a border its siblings
  // have dropped.
  final borderColor = resolveSurfaceStroke(
    theme,
    scheme.resolve(merged.panelBorderColor ?? chrome.borderColor).toValue(),
    role: CoreSurfaceRole.functional,
  );
  final descriptionColor = scheme
      .resolve(chrome.descriptionForeground ?? chrome.foregroundColor)
      .toValue();

  // ─── Dimensional (merged override wins, else static const default) ─
  // Paint-ready conversion only — `* scaling` is applied in the return
  // literal (CLAUDE.md Anti-Pattern B — single resolver signature).
  final borderRadius =
      ((merged.panelBorderRadius ?? CoreToastStyle.defaultPanelBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  // Border width is the only chrome left in pre-scaling units: a stroke
  // width is a physical hairline, not a layout dimension, so it must not
  // grow with `theme.scaling` (matches the alert resolver, Epic #1603 C12).
  final borderWidth = theme.geometry.stroke(
    merged.panelBorderWidth ?? CoreToastStyle.defaultPanelBorderWidth,
  );
  // Dismiss-aware padding — the dismissible state selects
  // `panelPaddingWithDismiss` (else `panelPadding`) so both override
  // slots stay reachable (matches the Web resolver, Epic #1603 1:1:1:1).
  final padding =
      ((dismissible
              ? (merged.panelPaddingWithDismiss ??
                    CoreToastStyle.defaultPanelPaddingWithDismiss)
              : (merged.panelPadding ?? CoreToastStyle.defaultPanelPadding))
          .toGeometry(geometry: theme.geometry)) *
      scaling;
  final minHeight =
      (merged.minHeight ?? CoreToastStyle.defaultMinHeight) * scaling;
  // Nested [CoreGapStyle] slots — merge the design-system default with
  // the per-instance override and forward *raw* to `Gap(gapStyle: …)`.
  // `Gap`'s render object self-applies `theme.scaling`, so the
  // resolver must NOT multiply by scaling here (Epic #1603 옵션 B —
  // single nested-slot scaling boundary).
  final contentActionGapStyle = CoreToastStyle.defaultContentActionGapStyle
      .merge(merged.contentActionGapStyle);
  final iconContentGapStyle = CoreToastStyle.defaultIconContentGapStyle.merge(
    merged.iconContentGapStyle,
  );
  // The variant's glyph colour folded onto the shared size. `null` when
  // the variant states no colour — that variant draws no glyph, so there
  // is nothing to style and nothing to space.
  final iconStyle = chrome.iconColor == null
      ? null
      : CoreToastStyle.defaultIconStyle
            .merge(merged.iconStyle)
            .merge(CoreIconStyle(color: chrome.iconColor));
  final messageDescriptionGapStyle = CoreToastStyle
      .defaultMessageDescriptionGapStyle
      .merge(
        merged.messageDescriptionGapStyle,
      );
  final closeInset =
      ((merged.closeInset ?? CoreToastStyle.defaultCloseInset).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  // Dismiss-button chrome — chained `defaultCloseButtonStyle` (zero-pad
  // tap target + 16-px close glyph + 150 ms hover + 2-px focus ring),
  // tinted with the per-variant close colours (`inverseOnSurface` at
  // 70 % resting → full on hover, so the glyph reads on the inverse fill
  // the `plain` default was not chosen for), then the
  // per-instance override on top (so a caller `closeButtonStyle` still
  // wins). Raw-forwarded to `Button(variant: .plain, buttonStyle: …)` —
  // the button resolves its own padding / icon / hover-fade /
  // focus-ring and self-applies `theme.scaling`, so the resolver does
  // NOT scale here (Anti-Pattern A, mirrors the chip remove button).
  final closeButtonStyle = CoreToastStyle.defaultCloseButtonStyle
      .merge(
        CoreButtonStyle(
          foregroundColor: chrome.closeForeground,
          hoverForegroundColor: chrome.closeHoverForeground,
        ),
      )
      .merge(merged.closeButtonStyle);
  // Action chrome — the variant foreground injected UNDER the caller's
  // slot, for the reason the close button above injects its own: the
  // action is a `Button` built against the page surface, and the toast
  // states what legible means on its own slab. Merge order keeps the
  // caller's `actionButtonStyle` — and, in the widget, the action's own
  // `buttonStyle` — winning. Raw-forwarded; the button resolves its own
  // chrome (Anti-Pattern A).
  //
  // Underneath it all sits `defaultActionButtonStyle`, whose opaque
  // focus-ring gap band keeps the ring readable on the slab — a
  // transparent gap would put the slab colour between the action and its
  // ring, and the ring would read as part of the slab rather than as a
  // mark on the control.
  // The banner/toast foreground every action wears — shared by the two
  // bundles below so the plain one cannot drift from the other.
  final actionForegroundStyle = CoreButtonStyle(
    foregroundColor: chrome.foregroundColor,
    hoverForegroundColor: chrome.foregroundColor,
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
  final transitionDuration = resolveMotionDuration(
    context,
    merged.transitionDuration ?? CoreToastStyle.defaultTransitionDuration,
  );

  // ─── Slot typography (paint-ready TextStyle) ──────────
  // EMIT Stage 2 (Flutter) — `default.merge(override).toValue(theme:,
  // color:)` is the single-primitive path: it materialises the
  // token-backed role (`CoreToastStyle.defaultMessageStyle` =
  // `labelLarge` with a bold overlay; `defaultDescriptionStyle` =
  // `bodySmall`), layers the per-instance overlay, and resolves the slot
  // colour through the active scheme. The `color:` override forces the
  // variant foreground when the per-instance slot carries no explicit
  // colour, so the text tracks the variant. No hand-rolled
  // `theme.typography.X` role lookup or letterSpacing / lineHeight /
  // fontWeight assembly.
  final messageStyle = CoreToastStyle.defaultMessageStyle
      .merge(merged.messageStyle)
      .toValue(
        color: merged.messageStyle?.color == null ? foregroundColor : null,
        theme: theme,
      );
  final descriptionStyle = CoreToastStyle.defaultDescriptionStyle
      .merge(merged.descriptionStyle)
      .toValue(
        color: merged.descriptionStyle?.color == null ? descriptionColor : null,
        theme: theme,
      );

  // ─── Shadow (scheme.resolve(CoreColors.shadow) tint — C7) ─
  // The full layer stack (override else default) is tinted with the
  // scheme's `shadow` token and converted through the shared
  // `CoreShadowLayersToFlutter` adapter — the style's transform, the CSS
  // blur → σ conversion the Web mirror paints, and the per-layer
  // `* scaling` (both offsets, blur, spread) all happen in that one place,
  // so the widget paints the list as-is — in the panel's decoration, or
  // outside the box where the fill is translucent.
  final shadowBase = scheme
      .resolve(const CoreColor.token(CoreColors.shadow))
      .toValue();
  final panelStack =
      merged.panelBoxShadow ?? CoreToastStyle.defaultPanelBoxShadow;
  final shadow = panelStack.toValue(
    base: shadowBase,
    geometry: theme.geometry,
    scale: scaling,
  );
  // Where the cast is painted: behind a fill that is not opaque, a
  // decoration's shadow shows through the panel (see [castOutsideBox]).
  final castOutsideBox = backgroundColor.a < 1;
  // The rim, gated on the panel's own stack — a panel that casts nothing
  // gets none, on both platforms.
  final insetBoxShadow = resolveSurfaceRim(context, stack: panelStack);

  return ResolvedToast(
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth,
    borderRadius: borderRadius,
    padding: padding,
    minHeight: minHeight,
    messageDescriptionGapStyle: messageDescriptionGapStyle,
    contentActionGapStyle: contentActionGapStyle,
    iconStyle: iconStyle,
    iconContentGapStyle: iconContentGapStyle,
    closeInset: closeInset,
    closeButtonStyle: closeButtonStyle,
    transitionDuration: transitionDuration,
    shadow: shadow,
    castOutsideBox: castOutsideBox,
    messageStyle: messageStyle,
    descriptionStyle: descriptionStyle,
    actionButtonStyle: actionButtonStyle,
    plainActionButtonStyle: plainActionButtonStyle,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
    insetBoxShadow: insetBoxShadow,
  );
}

// ═══════════════════════════════════════════════════
// Toast layer — the host that stacks toasts
// ═══════════════════════════════════════════════════

/// Paint-ready values for Flutter `ToastLayer` — the host that stacks and
/// fans out toasts, not a toast itself.
///
/// Widget tree (`toast_overlay.dart`):
///
/// ```text
/// Stacks
///   ├─ child                                  // the app
///   └─ Position.fill > SafeArea               // per location with entries
///        └─ Padding (padding)
///             └─ Align > MouseRegion > Stacks
///                  └─ ToastEntryLayout        // fanned out by spacing
/// ```
class ResolvedToastLayer {
  /// Creates a [ResolvedToastLayer].
  const ResolvedToastLayer({required this.padding, required this.spacing});

  /// Room between the stacks and the edges of the screen (scaling
  /// pre-applied; the theme density moves the default, a caller's own
  /// framework inset is drawn as given).
  final EdgeInsets padding;

  /// Gap between expanded toasts (logical px, the theme density and
  /// scaling pre-applied).
  final double spacing;
}

/// Resolves [ResolvedToastLayer] for the given [context].
///
/// The layer's values come from its own parameters — [spacing] (always
/// stated: the parameter defaults to `CoreToastStyle.defaultStackSpacing`)
/// and an optional [padding] — not from a toast's style, which cannot state
/// the room between all of them.
ResolvedToastLayer resolveToastLayer(
  BuildContext context, {
  required double spacing,
  EdgeInsetsGeometry? padding,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;

  // Spacing either way: the theme density moves the gap (a stated one too),
  // then the size factor applies.
  final resolvedSpacing = theme.geometry.space(spacing) * scaling;
  // guard-nested-override: layerPadding — the override is the layer's own
  // [padding] parameter, chained right below; a toast's style has no field
  // for it because one toast cannot state the room around every stack.
  final resolvedPadding =
      (padding?.optionallyResolve(context) ??
          CoreToastStyle.defaultLayerPadding.toValue(
            geometry: theme.geometry,
          )) *
      scaling;

  return ResolvedToastLayer(padding: resolvedPadding, spacing: resolvedSpacing);
}
