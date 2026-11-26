import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/util/standoff_border_radius.dart';

// ═══════════════════════════════════════════════════
// ResolvedAvatar — single struct read by `Avatar`
// ═══════════════════════════════════════════════════

/// Resolver output for [Avatar].
///
/// Single struct that the widget reads — the nested-merge chain
/// (`CoreAvatarStyle.defaultX` ← `theme.avatar.style` ←
/// `widget.avatarStyle`) plus token-table fallback is applied once
/// here so the widget never has to spell out the fallback chain
/// inline. Dimensional values are returned **paint-ready** (already
/// multiplied by [Theme.scaling]) so the widget never re-applies the
/// scaling factor.
class ResolvedAvatar {
  /// Creates a [ResolvedAvatar].
  const ResolvedAvatar({
    required this.size,
    required this.diameter,
    required this.containerStyle,
    required this.ringColor,
    required this.ringWidth,
    required this.ringOffset,
    required this.ringOffsetColor,
    required this.ringOffsetBorderRadius,
    required this.ringBorderRadius,
    required this.badgeInset,
    required this.badgeSize,
    required this.badgeAlignment,
    required this.badgePlacement,
    required this.badgeLeft,
    required this.badgeTop,
    required this.badgeAnchor,
    required this.badgeStyle,
    required this.childIconTheme,
    required this.fallbackTextStyle,
  });

  /// Resolved avatar size (after theme fallback).
  final CoreComponentSize size;

  /// Resolved avatar diameter (logical px, paint-ready).
  final double diameter;

  /// [CoreOutlinedContainerStyle] for the composed `OutlinedContainer`
  /// surface — background fill / radius / size are merged and expressed
  /// as `coui_core` domain types so the receiving widget runs its own
  /// colour / radius resolution once (mirrors `Card`'s `containerStyle`).
  /// The border always collapses fully transparent / zero-width here —
  /// the ring itself no longer rides this flush border. A flush border
  /// cannot express [ringOffset] (a border paints *on* the edge, not
  /// standing off from it), so the ring moved to a decorative overlay
  /// `Avatar` paints outside its own bounds (mirrors `FocusOutline`'s
  /// standoff ring) and reads [ringColor] / [ringWidth] / [ringOffset]
  /// directly. The active surface style's injected control-shadow is
  /// still supplied by `OutlinedContainer` internally — this resolver
  /// no longer restates it via `resolveInjectedCast`.
  final CoreOutlinedContainerStyle containerStyle;

  /// Resolved ring stroke colour (paint-ready) — read by `Avatar`'s
  /// standoff ring overlay when `ring` is `true`.
  final Color ringColor;

  /// Resolved ring stroke width (logical px, paint-ready) — read by
  /// `Avatar`'s standoff ring overlay when `ring` is `true`.
  final double ringWidth;

  /// Resolved gap between the avatar's own edge and the inner edge of
  /// the ring stroke (logical px, paint-ready) — read by `Avatar`'s
  /// standoff ring overlay when `ring` is `true`.
  final double ringOffset;

  /// Resolved fill for the gap band between the avatar's own edge and
  /// the ring stroke (paint-ready) — always the `surface` token (the
  /// same colour as `CoreFocusRing.opaqueOffsetColor`, and the Web
  /// twin's `ring-offset-surface`). Read by `Avatar`'s standoff ring
  /// overlay when `ring` is `true`: painted as a filled shape *behind*
  /// the avatar box, so it only shows in the gap band around the edge
  /// (the opaque avatar box occludes it everywhere else).
  final Color ringOffsetColor;

  /// Corner of the gap-band layer (paint-ready) — the avatar's own
  /// painted corner grown by [ringOffset], so the band's outer edge
  /// shares the avatar's curve whatever its shape. A square corner (a
  /// preset that caps the radius at zero) stays square, the same as the
  /// Web twin's `box-shadow` spread.
  final BorderRadius ringOffsetBorderRadius;

  /// Corner of the ring-stroke layer's outer edge (paint-ready) — the
  /// avatar's own painted corner grown by [ringOffset] + [ringWidth]. A
  /// disc's pill clamps to a circle; a rounded tile's ring follows its
  /// corner at that standoff.
  final BorderRadius ringBorderRadius;

  /// Resolved badge inset toward the centre (logical px, paint-ready).
  final double badgeInset;

  /// Resolved badge diameter the step hands its badge (logical px,
  /// paint-ready) — the size an [AvatarBadge] that states none draws at.
  final double badgeSize;

  /// Resolved corner the badge sits at, relative to the avatar.
  final CoreAlignment badgeAlignment;

  /// Resolved placement — in the box corner or on the outline.
  final CoreAvatarBadgePlacement badgePlacement;

  /// Distance from the avatar box's left edge to the badge's anchor point
  /// (logical px, paint-ready) — [CoreAvatarStyle.badgeAnchorFor] at the
  /// painted diameter.
  final double badgeLeft;

  /// Distance from the avatar box's top edge to the badge's anchor point
  /// (logical px, paint-ready).
  final double badgeTop;

  /// The point of the badge's own box that sits on the anchor, as
  /// fractions of its size — [Avatar] translates the badge by the negative
  /// of it, so the placement holds whatever size the badge draws at.
  final Offset badgeAnchor;

  /// The badge style the avatar hands its `badge` slot — the step's size
  /// under the instance's `badgeStyle`, raw-forwarded (the badge's own
  /// resolver scales it). [AvatarBadge] lays its own style over it.
  final CoreAvatarBadgeStyle badgeStyle;

  /// Ambient icon theme around the `child` slot — the step's icon size,
  /// stated as a token size (an `Icon` scales its own box).
  final IconThemeData childIconTheme;

  /// Paint-ready initials fallback text style. The resolver layers the
  /// size's typography role ([CoreAvatarStyle.fallbackRoleFor]), the shared
  /// colour + weight ([CoreAvatarStyle.defaultFallbackTextStyle]), the
  /// per-instance `fallbackTextStyle` slot override and — only when the
  /// instance states an `initialsFontRatio` — the diameter-scaled font
  /// size into one [TextStyle] so the widget forwards it raw to `Text`.
  final TextStyle fallbackTextStyle;
}

// ═══════════════════════════════════════════════════
// resolveAvatar — single entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAvatar] for the given [context].
///
/// ```text
/// defaultsBySize[size] → defaultsByShape[shape] → CoreAvatarStyle.defaultX
///   → CoreAvatarTheme.style
///   → widget.avatarStyle
/// ```
ResolvedAvatar resolveAvatar(
  BuildContext context, {
  required CoreComponentSize size,
  required CoreAvatarShape shape,
  required bool ring,
  CoreAvatarStyle? avatarStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final avatarTheme = theme.coreComponentTheme?.avatar;

  final merged = resolveStyleChain(const CoreAvatarStyle(), [
    avatarTheme?.style,
    avatarStyle,
  ]);

  // Semantic identifiers (`size`, `shape`) come straight from the widget —
  // the theme cannot override them (render-only.md (c): a
  // semantic-identifier theme override is itself a violation). Web resolves
  // them identically, so the two platforms stay 1:1.
  final effectiveSize = size;

  // The step's row with the shape's row over it — the rounded tile keeps
  // the step's corner, a disc takes the pill. A corner stated on the theme
  // or the instance wins over both.
  final chrome = CoreAvatarStyle.defaultsBySize[effectiveSize]!.merge(
    CoreAvatarStyle.defaultsByShape[shape],
  );

  // ─── Stage1 RESOLVE (Core values — Flutter = Web) ─────
  final bgCore =
      merged.backgroundColor ?? CoreAvatarStyle.defaultBackgroundColor;
  final ringCore = merged.ringColor ?? CoreAvatarStyle.defaultRingColor;
  final coreBorderRadius = merged.borderRadius ?? chrome.borderRadius!;
  final ringWidth = merged.ringWidth ?? CoreAvatarStyle.defaultRingWidth;
  final ringOffset = merged.ringOffset ?? CoreAvatarStyle.defaultRingOffset;
  final badgeInset = merged.badgeInset ?? CoreAvatarStyle.defaultBadgeInset;
  final badgeAlignment =
      merged.badgeAlignment ?? CoreAvatarStyle.defaultBadgeAlignment;
  final badgePlacement =
      merged.badgePlacement ??
      chrome.badgePlacement ??
      CoreAvatarStyle.defaultBadgePlacement;
  // Nested slots, raw-forwarded: the step's row under the instance's slot
  // (composite — a caller that states only a colour keeps the step's size).
  final badgeStyle = CoreAvatarStyle.badgeStyleFor(
    effectiveSize,
  ).merge(merged.badgeStyle);
  final childIconStyle = CoreAvatarStyle.childIconStyleFor(
    effectiveSize,
  ).merge(merged.childIconStyle);
  // Initials fallback typography — the size's role laid over the shared
  // colour + weight default, then the per-instance `fallbackTextStyle` slot
  // (composite: a caller that overrides only `color` keeps the size's role
  // and the 600 weight).
  final fallbackTextCore = CoreAvatarStyle.defaultFallbackTextStyle
      .merge(CoreAvatarStyle.fallbackRoleFor(effectiveSize))
      .merge(merged.fallbackTextStyle);
  // Only an instance that states a ratio sizes the initials from the
  // diameter; otherwise the role's own size, tracking and leading stand.
  final fontRatio = merged.initialsFontRatio;

  // ─── Stage2 EMIT (Flutter — theme-dependent) ─────────
  // Paint-ready avatar diameter — also drives the deterministic initials
  // font-size fallback below.
  final diameter =
      (merged.diameter ?? CoreAvatarStyle.diameterFor(effectiveSize)) * scaling;
  final ringColorValue = scheme.resolve(ringCore).toValue();
  final ringWidthValue = theme.geometry.stroke(ringWidth, scaling: scaling);
  final ringOffsetValue = ringOffset * scaling;
  final ringOffsetColorValue = scheme
      .resolve(const CoreColor.token(CoreColors.surface))
      .toValue();
  // The ring follows the corner the avatar box actually paints — the same
  // geometry bend and size factor `OutlinedContainer` runs on
  // [containerStyle]'s radius — grown by each layer's standoff, so a
  // rounded tile's ring keeps its curve. The Web twin gets the same growth
  // from its `box-shadow` spread.
  final paintedBorderRadius =
      coreBorderRadius.toValue(geometry: theme.geometry) * scaling;
  final ringOffsetBorderRadius = paintedBorderRadius.standoff(
    ringOffsetValue,
  );
  final ringBorderRadius = paintedBorderRadius.standoff(
    ringOffsetValue + ringWidthValue,
  );
  final badgeInsetValue = badgeInset * scaling;
  final badgeSizeValue =
      (badgeStyle.size ?? CoreAvatarBadgeStyle.defaultSize) * scaling;
  final badgeAnchor = CoreAvatarStyle.badgeAnchorFor(
    diameter: diameter,
    inset: badgeInsetValue,
    alignment: badgeAlignment,
    placement: badgePlacement,
  );
  final badgeAnchorOffset = Offset(badgeAnchor.alignX, badgeAnchor.alignY);
  // Token size — `Icon` multiplies its box by the scaling itself.
  final childIconTheme = IconThemeData(size: childIconStyle.size);
  // Single-primitive typography EMIT — `style.toValue(theme:)`
  // materialises the size's role + resolves the slot colour through the
  // active scheme; a stated `initialsFontRatio` wins over the role's size
  // only when the slot carries no explicit `fontSize`.
  final fallbackTextStyle =
      (fontRatio == null
              ? fallbackTextCore
              : fallbackTextCore.copyWith(
                  fontSize: fallbackTextCore.fontSize ?? (diameter * fontRatio),
                ))
          .toValue(theme: theme);

  // ─── Outer chrome — composed `OutlinedContainer` contract input.
  // Background / radius / size are merged and expressed as `coui_core`
  // domain types — `OutlinedContainer`'s own resolver runs the final
  // `scheme.resolve(...).toValue()` + geometry / scaling step itself
  // (mirrors `Card`'s `containerStyle`). The border is always fully
  // transparent / zero-width now — the ring paints in a standoff
  // overlay outside these bounds instead (see [ResolvedAvatar
  // .containerStyle] doc). `width` / `height` are the already-scaled
  // [diameter] — `OutlinedContainer` forwards them straight to its
  // paint pipeline without re-scaling.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: bgCore,
    borderColor: .transparent,
    borderRadius: coreBorderRadius,
    borderWidth: 0.0,
    width: diameter,
    height: diameter,
  );

  return ResolvedAvatar(
    size: effectiveSize,
    diameter: diameter,
    containerStyle: containerStyle,
    ringColor: ringColorValue,
    ringWidth: ringWidthValue,
    ringOffset: ringOffsetValue,
    ringOffsetColor: ringOffsetColorValue,
    ringOffsetBorderRadius: ringOffsetBorderRadius,
    ringBorderRadius: ringBorderRadius,
    badgeInset: badgeInsetValue,
    badgeSize: badgeSizeValue,
    badgeAlignment: badgeAlignment,
    badgePlacement: badgePlacement,
    badgeLeft: badgeAnchor.x,
    badgeTop: badgeAnchor.y,
    badgeAnchor: badgeAnchorOffset,
    badgeStyle: badgeStyle,
    childIconTheme: childIconTheme,
    fallbackTextStyle: fallbackTextStyle,
  );
}

// ═══════════════════════════════════════════════════
// ResolvedAvatarBadge — single struct read by `AvatarBadge`
// ═══════════════════════════════════════════════════

/// Resolver output for [AvatarBadge].
class ResolvedAvatarBadge {
  /// Creates a [ResolvedAvatarBadge].
  const ResolvedAvatarBadge({
    required this.backgroundColor,
    required this.size,
    required this.borderColor,
    required this.borderWidth,
  });

  /// Resolved badge fill colour.
  final Color backgroundColor;

  /// Resolved badge diameter (logical px, paint-ready).
  final double size;

  /// Resolved colour of the ring inside the dot's edge.
  final Color borderColor;

  /// Resolved width of the ring inside the dot's edge (logical px,
  /// paint-ready) — painted inward, so the dot keeps [size].
  final double borderWidth;
}

/// Resolves [ResolvedAvatarBadge] for the given [context].
///
/// [inheritedStyle] is what an enclosing [Avatar] hands its badge slot (its
/// step's size); the badge's own [avatarBadgeStyle] is laid over it.
ResolvedAvatarBadge resolveAvatarBadge(
  BuildContext context, {
  CoreAvatarBadgeStyle? inheritedStyle,
  CoreAvatarBadgeStyle? avatarBadgeStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;

  final merged = resolveStyleChain(const CoreAvatarBadgeStyle(), [
    inheritedStyle,
    avatarBadgeStyle,
  ]);

  // ─── Stage1 RESOLVE ───────────────────────────────────
  final bgCore =
      merged.backgroundColor ?? CoreAvatarBadgeStyle.defaultBackgroundColor;
  final size = merged.size ?? CoreAvatarBadgeStyle.defaultSize;
  final borderCore =
      merged.borderColor ?? CoreAvatarBadgeStyle.defaultBorderColor;
  final borderWidth =
      merged.borderWidth ?? CoreAvatarBadgeStyle.defaultBorderWidth;

  // ─── Stage2 EMIT (Flutter) ────────────────────────────
  final backgroundColor = scheme.resolve(bgCore).toValue();
  final sizeValue = size * scaling;
  final borderColor = scheme.resolve(borderCore).toValue();
  final borderWidthValue = theme.geometry.stroke(borderWidth, scaling: scaling);

  return ResolvedAvatarBadge(
    backgroundColor: backgroundColor,
    size: sizeValue,
    borderColor: borderColor,
    borderWidth: borderWidthValue,
  );
}

// ═══════════════════════════════════════════════════
// ResolvedAvatarGroup — single struct read by `AvatarGroup`
// ═══════════════════════════════════════════════════

/// Resolver output for [AvatarGroup].
class ResolvedAvatarGroup {
  /// Creates a [ResolvedAvatarGroup].
  const ResolvedAvatarGroup({
    required this.extraSpacing,
    required this.overlap,
    required this.borderColor,
    required this.borderWidth,
    required this.defaultDiameter,
  });

  /// Extra paint-time positive offset added on top of the negative
  /// `overlap` translation (logical px, paint-ready). Multiplied per
  /// item by the group layout — distinct from a structural sibling gap.
  final double extraSpacing;

  /// Overlap distance between adjacent avatars (logical px, paint-ready).
  final double overlap;

  /// Resolved per-item separator border colour.
  final Color borderColor;

  /// Resolved per-item separator border width (logical px, paint-ready).
  final double borderWidth;

  /// Resolved default avatar diameter (logical px, paint-ready) used
  /// by the group layout to estimate row height.
  final double defaultDiameter;
}

/// Resolves [ResolvedAvatarGroup] for the given [context].
ResolvedAvatarGroup resolveAvatarGroup(
  BuildContext context, {
  CoreAvatarGroupStyle? avatarGroupStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;

  final merged = resolveStyleChain(const CoreAvatarGroupStyle(), [
    avatarGroupStyle,
  ]);

  // ─── Stage1 RESOLVE ───────────────────────────────────
  final borderCore =
      merged.borderColor ?? CoreAvatarGroupStyle.defaultBorderColor;
  final extraSpacing =
      merged.extraSpacing ?? CoreAvatarGroupStyle.defaultExtraSpacing;
  final overlap = merged.overlap ?? CoreAvatarGroupStyle.defaultOverlap;
  final borderWidth =
      merged.borderWidth ?? CoreAvatarGroupStyle.defaultBorderWidth;

  // ─── Stage2 EMIT (Flutter) ────────────────────────────
  final extraSpacingValue = theme.geometry.space(extraSpacing) * scaling;
  final overlapValue = overlap * scaling;
  final borderColor = scheme.resolve(borderCore).toValue();
  final borderWidthValue = theme.geometry.stroke(borderWidth, scaling: scaling);
  final defaultDiameter =
      CoreAvatarStyle.diameterFor(CoreAvatarContract.defaultSize) * scaling;

  return ResolvedAvatarGroup(
    extraSpacing: extraSpacingValue,
    overlap: overlapValue,
    borderColor: borderColor,
    borderWidth: borderWidthValue,
    defaultDiameter: defaultDiameter,
  );
}
