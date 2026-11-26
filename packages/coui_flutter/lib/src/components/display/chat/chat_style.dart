import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedChat / ResolvedChatBubble — single
// structs read by `Chat` / `ChatBubble` widgets.
// ═══════════════════════════════════════════════════

/// Resolver output for [Chat] / [ChatGroup].
///
/// Single struct that the widget reads — the nested-merge chain
/// (`CoreChatStyle.defaultX` ← `theme.chat.style` ← `widget.chatStyle`)
/// is applied once here so the widget never has to spell out the
/// fallback chain inline.
class ResolvedChat {
  /// Creates a [ResolvedChat].
  const ResolvedChat({
    required this.avatarSpacing,
    required this.groupSpacing,
    required this.headerTextStyle,
    required this.footerTextStyle,
  });

  /// Resolved padding spacing between avatar and message column
  /// (logical px). Fed straight into the avatar wrapper's
  /// `EdgeInsetsDirectional` — no `Gap`, so the value stays a raw
  /// double.
  final double avatarSpacing;

  /// Resolved inter-bubble spacing inside a group (logical px,
  /// scaling pre-applied). Flows directly into `Column.spacing`
  /// (Flutter 3.27+) — a native paint-API argument that consumes raw
  /// doubles, so no `Gap` interleave in the widget body.
  final double groupSpacing;

  /// Resolved header text style — paint-ready [TextStyle] with the
  /// token role materialised (`defaultHeaderTextStyle.merge(override)
  /// .toValue(theme:)`), so both platforms render the same typography
  /// instead of inheriting divergent ambient defaults.
  final TextStyle headerTextStyle;

  /// Resolved footer text style — same shape as [headerTextStyle].
  final TextStyle footerTextStyle;
}

/// Resolves [ResolvedChat] for the given [context].
ResolvedChat resolveChat(
  BuildContext context, {
  CoreChatStyle? chatStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final chatTheme = theme.coreComponentTheme?.chat;

  final merged = resolveStyleChain(const CoreChatStyle(), [
    chatTheme?.style,
    chatStyle,
  ]);

  // ─── Paint-ready chrome (synthesised in locals; return stays bare) ──
  final avatarSpacing =
      theme.geometry.space(
        merged.avatarSpacing ?? CoreChatStyle.defaultAvatarSpacing,
      ) *
      scaling;
  final groupSpacing =
      theme.geometry.space(
        merged.groupSpacing ?? CoreChatStyle.defaultGroupSpacing,
      ) *
      scaling;
  final headerTextStyle = CoreChatStyle.defaultHeaderTextStyle
      .merge(merged.headerTextStyle)
      .toValue(theme: theme);
  final footerTextStyle = CoreChatStyle.defaultFooterTextStyle
      .merge(merged.footerTextStyle)
      .toValue(theme: theme);

  return ResolvedChat(
    avatarSpacing: avatarSpacing,
    groupSpacing: groupSpacing,
    headerTextStyle: headerTextStyle,
    footerTextStyle: footerTextStyle,
  );
}

/// Resolver output for [ChatBubble].
class ResolvedChatBubble {
  /// Creates a [ResolvedChatBubble].
  const ResolvedChatBubble({
    required this.padding,
    required this.borderRadius,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.maxWidthFactor,
    required this.alignment,
    required this.tail,
    required this.tailEdge,
    required this.tailWidth,
    required this.tailHeight,
    required this.tailTipRadius,
    required this.textStyle,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
  });

  /// Resolved inner padding.
  final EdgeInsets padding;

  /// Resolved border radius.
  final BorderRadius borderRadius;

  /// Resolved background fill colour.
  final Color backgroundColor;

  /// Resolved foreground (text) colour.
  final Color foregroundColor;

  /// Resolved max bubble width fraction.
  final double maxWidthFactor;

  /// The side the bubble sits on: the bubble's own `alignment`, else the
  /// alignment of the row it is in, else [CoreChatAlignment.defaultAlignment].
  /// It decides which corner the tail leaves from.
  final CoreChatAlignment alignment;

  /// Whether the tail is drawn: the requested tail, and only when the bubble
  /// paints a fill for it to continue. A bubble without a fill (the `plain`
  /// variant, or a caller-made transparent one) has no surface to extend, so
  /// the tail cannot be switched on there.
  final bool tail;

  /// The bubble edge the tail sits on — the pointer leaves from this edge's
  /// corner on the alignment side.
  final CoreChatBubbleTailEdge tailEdge;

  /// Resolved tail width (logical px).
  final double tailWidth;

  /// Resolved tail height (logical px).
  final double tailHeight;

  /// Resolved tail pointer-tip rounding radius (logical px) — the
  /// concave curve stops this far above the bottom edge and arcs
  /// around the tip instead of ending in a sharp cusp. Single arc
  /// radius for a `Path`-drawn tip, not a rectangular 4-corner
  /// concept — `BorderRadius` doesn't apply here.
  final double tailTipRadius; // guard-non-rect-radius

  /// Resolved bubble content text style — paint-ready [TextStyle]
  /// with the token role materialised
  /// (`defaultTextStyle.merge(override).toValue(theme:)`). Colour is
  /// left to the widget's variant-[foregroundColor] base unless the
  /// caller's override carries an explicit colour.
  final TextStyle textStyle;

  /// Backdrop blur sigma for the bubble's body, or `null` when the active
  /// style states no material or the bubble paints no fill.
  ///
  /// The body is a content surface (the class doc's `surface:content`), so
  /// it draws the whole material the style states — the frost, the chroma
  /// lift, the dimming, the edge light and the bend — not only the fill
  /// share. The tail is not part of the frosted box: it takes the share
  /// through [backgroundColor] and nothing else, which is also exactly
  /// what the Web twin's tail gets by inheriting the body's restated fill.
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through the body, or null.
  final double? surfaceBackdropBrightness;

  /// Edge light along the body's contour, or null.
  final ResolvedSurfaceSheen? surfaceSheen;
}

/// Resolves [ResolvedChatBubble] for the given [context] / [variant].
///
/// [variant] / [alignment] / [tail] are build-time semantic props — a prop
/// the caller states is used as stated. One left `null` is the bubble's to
/// pick: the alignment of the row it sits in ([ChatAlignmentScope]), and from
/// that side the variant and tail it takes by default
/// (`CoreChatBubbleContract.defaultVariantFor` / `defaultTailFor`). The
/// alignment picks which corner flattens so the tail's concave curve
/// continues the bubble edge.
ResolvedChatBubble resolveChatBubble(
  BuildContext context, {
  CoreChatBubbleVariant? variant,
  CoreChatAlignment? alignment,
  bool? tail,
  CoreChatBubbleStyle? chatBubbleStyle,
}) {
  final bubbleAlignment =
      alignment ??
      ChatAlignmentScope.maybeOf(context) ??
      CoreChatAlignment.defaultAlignment;
  final bubbleVariant =
      variant ?? CoreChatBubbleContract.defaultVariantFor(bubbleAlignment);
  final bubbleTail =
      tail ?? CoreChatBubbleContract.defaultTailFor(bubbleAlignment);
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final bubbleTheme = theme.coreComponentTheme?.chatBubble;

  // ChatBubble draws its own box rather than composing
  // `OutlinedContainer` (its concave tail path is cut against the same
  // fill, a shape the container has no slot for — #4358), so it reads the
  // content-role seat directly — and then draws all of it, as that
  // primitive would have: the fill share below, the rest of the material
  // further down.
  final material = theme.surfaceFor(.content, depth: SurfaceDepth.of(context));
  final surfaceOpacity = material?.opacityIn(theme);

  /// Folds the active content-role material's opacity into [color].
  CoreColor materialFill(CoreColor color) =>
      surfaceOpacity == null ? color : color.scaleAlpha(surfaceOpacity);

  // ─── Token tables ─────────────────────────────────────
  // Variant-specific chrome defaults (background / foreground colour).
  final variantStyle = CoreChatBubbleStyle.defaultsByVariant[bubbleVariant]!;

  // ─── Merge chain ──────────────────────────────────────
  // design-system default → theme.style → theme.variantStyles[v] → widget.
  final merged = resolveStyleChain(const CoreChatBubbleStyle(), [
    bubbleTheme?.style,
    bubbleTheme?.variantStyles?[bubbleVariant],
    chatBubbleStyle,
  ]);

  // ─── Resolved chrome (paint-ready Flutter values) ─────
  final padding =
      (merged.padding ??
              variantStyle.padding ??
              CoreChatBubbleStyle.defaultPadding)
          .toValue(geometry: theme.geometry);
  final mergedRadius =
      merged.borderRadius ?? CoreChatBubbleStyle.defaultBorderRadius;
  final tailEdge = merged.tailEdge ?? CoreChatBubbleStyle.defaultTailEdge;
  // ─── Colours (C7 — scheme.resolve(x).toValue() single path) ─
  // Per-instance override wins, else the variant chrome default. Both
  // arms run the resolve → Flutter `Color` conversion in one expression
  // so dark-mode tokens resolve against the active scheme.
  final backgroundColor = scheme
      .resolve(
        materialFill(merged.backgroundColor ?? variantStyle.backgroundColor),
      )
      .toValue();
  final foregroundColor = scheme
      .resolve(merged.foregroundColor ?? variantStyle.foregroundColor)
      .toValue();

  // Behaviour / dimensional scalars — `??` fallback synthesised in
  // locals so the return literal stays a bare mapping (resolver-
  // pattern.md: synthesis in locals, return = bare).
  final maxWidthFactor =
      merged.maxWidthFactor ??
      variantStyle.maxWidthFactor ??
      CoreChatBubbleStyle.defaultMaxWidthFactor;
  final tailWidth = merged.tailWidth ?? CoreChatBubbleStyle.defaultTailWidth;
  final tailHeight = merged.tailHeight ?? CoreChatBubbleStyle.defaultTailHeight;
  final tailTipRadius =
      merged.tailTipRadius ?? CoreChatBubbleStyle.defaultTailTipRadius;
  final textStyle = CoreChatBubbleStyle.defaultTextStyle
      .merge(merged.textStyle)
      .toValue(theme: theme);

  // The rest of the material, gated on the fill the way every surface's is:
  // a bubble a caller made transparent has nothing to frost behind and no
  // box to light the edge of.
  final hasFill = backgroundColor.a > 0;
  // The tail extends the fill, so a bubble with no fill has none to draw.
  final effectiveTail = bubbleTail && hasFill;
  // The tail corner — the tail edge's corner on the alignment side. A
  // drawn pointer flows out of it, so it must be square for the concave
  // curve to continue the bubble edge (daisyUI `border-end-end-radius: 0`
  // convention) — a rounded corner leaves a notch between the bubble and
  // the tail. Without a pointer it is the stated tail corner, else simply
  // the `borderRadius` corner.
  final tailCorner = effectiveTail ? 0.0 : merged.tailCornerRadius;
  // Shaped before the geometry bends the corners, so a preset moves a stated
  // tail corner the way it moves the other three. Square is one of the
  // geometry's fixed points: a pointer's corner stays square under every
  // style.
  final borderRadius =
      (tailCorner == null
              ? mergedRadius
              : tailEdge.withTailCorner(
                  mergedRadius,
                  alignment: bubbleAlignment,
                  corner: tailCorner,
                ))
          .toValue(geometry: theme.geometry);
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill ? resolveSurfaceSheen(theme) : null;

  return ResolvedChatBubble(
    padding: padding,
    borderRadius: borderRadius,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    maxWidthFactor: maxWidthFactor,
    alignment: bubbleAlignment,
    tail: effectiveTail,
    tailEdge: tailEdge,
    tailWidth: tailWidth,
    tailHeight: tailHeight,
    tailTipRadius: tailTipRadius,
    textStyle: textStyle,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
  );
}
