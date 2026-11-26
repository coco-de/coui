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

/// Paint-ready chrome for Web `Avatar`.
///
/// DOM shape (two layout modes, `co_avatar` picks based on whether the
/// caller supplied a badge):
///
/// ```text
/// // No badge — avatar box is the root.
/// root (<div>)                              // avatar box: bg / ring / radius / size
///   └─ tier pin (<div>)                     // TypographyTierScope(desktop)
///        └─ image (<img>) | initials (<span>) | child   // co_avatar picks one
///
/// // With badge — root wraps avatar box + badge slot.
/// root (<div>)                              // relative inline-block wrapper
///   ├─ avatarBox (<div>)                    // bg / ring / radius / size
///   │    └─ tier pin (<div>)                // TypographyTierScope(desktop)
///   │         └─ image (<img>) | initials (<span>) | child   // co_avatar picks one
///   └─ badgeSlot (<div>)                    // absolute + anchor point / translate inline
///        └─ tier pin (<div>)                // TypographyTierScope(desktop)
///             └─ AvatarBadgeScope(badgeStyle)    // pure metadata — no DOM
///                  └─ caller-supplied badge component
/// ```
///
/// Each tier pin is a box-less wrapper
/// (`<div style="display: contents" data-coui-typography-tier="desktop">`)
/// that holds the initials and the badge to the desktop tier. The content
/// and the badge sit inside it, so they are not direct children of the
/// avatar box or of the badge slot.
///
/// `co_avatar.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge / fallback / conversion
/// in the widget body. The widget decides whether to render the
/// wrapper / badge slot based on its own `badge` prop.
///
/// The avatar box itself (background / radius / size) is a composed
/// `OutlinedContainer` — [avatarBoxStyle] is a nested
/// [CoreOutlinedContainerStyle] slot raw-forwarded straight to
/// `OutlinedContainer(containerStyle: …)` rather than a
/// `WebElementChrome` this resolver assembles itself
/// (`core/style-contract.md`'s child-component-composition rule).
/// [avatarBoxStyle]'s own border is always fully transparent / zero-
/// width — the ring lives in [ringWrapper] instead (see its doc for
/// why a flush border cannot express it).
class ResolvedAvatar implements WebResolvedChrome {
  /// Creates a [ResolvedAvatar].
  const ResolvedAvatar({
    required this.root,
    required this.avatarBoxStyle,
    required this.ringWrapper,
    required this.image,
    required this.initials,
    required this.badgeSlot,
    required this.badgeStyle,
    required this.childIconStyle,
  });

  /// Paint-ready chrome for the outermost `<div>` — only used as the
  /// badge positioning wrapper when the widget has a badge (see
  /// [avatarBoxStyle] below for the no-badge case, where the composed
  /// `OutlinedContainer` itself is the root).
  @override
  final WebElementChrome root;

  /// Nested [CoreOutlinedContainerStyle] for the avatar box — raw-
  /// forwarded straight to `OutlinedContainer(containerStyle: …)`;
  /// that widget's own resolver owns background / border / radius /
  /// size emit (no className / inlineStyles assembly here — mirrors
  /// `CardImage`'s `frameStyle` nested slot).
  final CoreOutlinedContainerStyle avatarBoxStyle;

  /// Paint-ready chrome for the standoff ring wrapper `<div>` — `null`
  /// when `ring` is `false` (no wrapper renders at all, so a non-ringed
  /// avatar's DOM shape is unchanged). When present, `co_avatar` wraps
  /// the avatar box (and, with a badge, the whole `root` positioning
  /// wrapper) in this element.
  ///
  /// Sized / rounded to match the avatar box exactly, with a two-layer
  /// `box-shadow`: an inner `surface`-token "offset" layer (visible
  /// only in the gap band, since the opaque avatar box in front of it
  /// occludes it everywhere else — the CSS analogue of `FocusOutline`'s
  /// offset layer painting *behind* its child) and an outer ring stroke
  /// layer further out by the ring width. `box-shadow` never affects
  /// layout, so this wrapper adds zero footprint beyond the avatar's
  /// own box.
  final WebElementChrome? ringWrapper;

  /// Paint-ready chrome for the `<img>` content slot.
  final WebElementChrome image;

  /// Paint-ready chrome for the initials `<span>` content slot.
  final WebElementChrome initials;

  /// Paint-ready chrome for the badge positioning wrapper `<div>` —
  /// `co_avatar` renders this only when the `badge` prop is non-null.
  final WebElementChrome badgeSlot;

  /// Nested [CoreAvatarBadgeStyle] the avatar hands its badge slot — the
  /// step's size under the instance's `badgeStyle`, raw-forwarded through
  /// an `AvatarBadgeScope` (the badge's own resolver emits it).
  final CoreAvatarBadgeStyle badgeStyle;

  /// Nested [CoreIconStyle] mounted as the ambient `IconTheme` around the
  /// `child` slot — the step's icon size, which an `Icon` handed as `child`
  /// that states none draws at.
  final CoreIconStyle childIconStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAvatar] for the given [context].
///
/// Merge chain:
///
/// ```text
/// defaultsBySize[size] → defaultsByShape[shape] → design-system default
///   → theme.coreComponentTheme.avatar.style
///   → widget.avatarStyle
/// ```
ResolvedAvatar resolveAvatar(
  BuildContext context, {
  required CoreComponentSize size,
  required CoreAvatarShape shape,
  required bool ring,
  CoreAvatarStyle? avatarStyle,
}) {
  final avatarTheme = context.theme.coreComponentTheme?.avatar;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreAvatarStyle(), [
    avatarTheme?.style,
    avatarStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  // Semantic identifiers (`size`, `shape`) come straight from the widget —
  // the theme cannot override them (mirrors the Flutter resolver; a
  // semantic identifier never round-trips through the Theme).
  final effectiveSize = size;

  // The step's row with the shape's row over it — the rounded tile keeps
  // the step's corner, a disc takes the pill. A corner stated on the theme
  // or the instance wins over both (mirrors the Flutter resolver).
  final chrome = CoreAvatarStyle.defaultsBySize[effectiveSize]!.merge(
    CoreAvatarStyle.defaultsByShape[shape],
  );

  // ─── Resolved chrome values ───────────────────────────
  // Each value finished its merge + fallback so the local builders
  // below run from a single source of truth (closures capture these
  // directly).
  final coreBorderRadius = merged.borderRadius ?? chrome.borderRadius!;
  final ringColor = merged.ringColor ?? CoreAvatarStyle.defaultRingColor;
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
  // (mirrors the Flutter resolver).
  final badgeStyle = CoreAvatarStyle.badgeStyleFor(
    effectiveSize,
  ).merge(merged.badgeStyle);
  final childIconStyle = CoreAvatarStyle.childIconStyleFor(
    effectiveSize,
  ).merge(merged.childIconStyle);
  // Initials typography — the size's role over the shared colour + weight
  // default, then the per-instance slot; `emitTypography` puts the role
  // (and a token colour) on classes and only a raw overlay inline, so the
  // weight arrives as an inline `font-weight`. The diameter is the stated
  // `diameter` or the one the size names in the shared
  // `CoreAvatarStyle.defaultsBySize` table; only an instance that states
  // `initialsFontRatio` sizes the letters from it (mirrors the Flutter
  // resolver).
  final initialsEmit = emitTypography(
    merged.fallbackTextStyle,
    CoreAvatarStyle.defaultFallbackTextStyle.merge(
      CoreAvatarStyle.fallbackRoleFor(effectiveSize),
    ),
  );
  final initialsDiameter =
      merged.diameter ?? CoreAvatarStyle.diameterFor(effectiveSize);
  final initialsFontRatio = merged.initialsFontRatio;

  // ─── Outer chrome — composed `OutlinedContainer` contract input
  // (mirrors the Flutter twin and `CardImage`'s `frameStyle` nested
  // slot). Background / radius / size are merged and expressed as
  // `coui_core` domain types; `OutlinedContainer`'s own resolver runs
  // the class-vs-inline emit decision itself. The border is always
  // fully transparent / zero-width now — the ring paints in
  // [ringWrapper] instead (see [ResolvedAvatar.avatarBoxStyle] doc).
  final avatarBoxStyle = CoreOutlinedContainerStyle(
    backgroundColor:
        merged.backgroundColor ?? CoreAvatarStyle.defaultBackgroundColor,
    borderColor: .transparent,
    borderRadius: coreBorderRadius,
    borderWidth: 0.0,
    width: initialsDiameter,
    height: initialsDiameter,
  );

  // ─── Local builders ───────────────────────────────────
  // Closures capture every chrome value above — no named-arg
  // explosion. Local to the resolver, inaccessible from outside.

  /// Composes the standoff ring wrapper's inline-CSS bundle — `null`
  /// when `ring` is `false` (no wrapper element at all). Sized /
  /// rounded to match the avatar box — a `box-shadow` spread grows each
  /// round corner by its spread, so a rounded tile's ring keeps the
  /// tile's curve at the standoff the Flutter twin grows its layers by —
  /// with a two-layer `box-shadow`:
  /// the inner layer is the `surface` token at [ringOffset] spread (the
  /// gap band — the same colour as `CoreFocusRing.opaqueOffsetColor`,
  /// since the avatar box painted on top of it occludes it everywhere
  /// but that band), the outer layer is [ringColor] at
  /// `ringWidth + ringOffset` spread (the stroke itself). Neither layer
  /// rides `OutlinedContainer`'s own `box-shadow` — restating that
  /// value here would re-implement a shared primitive's shadow
  /// ownership (`core/style-contract.md`'s child-component-composition
  /// rule), so the ring lives on its own wrapper element instead.
  WebElementChrome? buildRingWrapper() {
    if (!ring) return null;
    final offsetRem = '${ringOffset / kRemDivisor}rem';
    return WebElementChrome(
      className: WebLayout.inlineBlock,
      inlineStyles: Styles(
        raw: {
          'width': '${initialsDiameter / kRemDivisor}rem',
          'height': '${initialsDiameter / kRemDivisor}rem',
          'border-radius': coreBorderRadius.toValue(),
          'box-shadow':
              '0 0 0 $offsetRem '
              '${const CoreColor.token(CoreColors.surface).toValue()}, '
              '0 0 0 calc(${strokeWidthCss(ringWidth)} + $offsetRem) '
              '${ringColor.toValue()}',
        },
      ),
    );
  }

  /// Composes the `<img>` content slot Tailwind className — fills the
  /// avatar box with `object-cover`. No border radius is emitted here —
  /// the composed `OutlinedContainer` avatar box already clips its
  /// child to the rounded shape via `overflow: hidden` (mirrors
  /// `CardImage`'s `image` slot, which relies on the same frame clip).
  String buildImageClassName() =>
      '${WebLayout.wFull} ${WebLayout.hFull} object-cover';

  /// Composes the initials `<span>` Tailwind className — the role class
  /// and the token colour class from [initialsEmit] + a `select-none` so
  /// the user cannot text-select the initials.
  String buildInitialsClassName() => [
    if (initialsEmit.className.isNotEmpty) initialsEmit.className,
    'select-none',
  ].join(' ');

  /// Composes the initials inline-CSS bundle — the explicit overlays of
  /// the `fallbackTextStyle` slot (weight, a raw colour, a stated size …)
  /// and, only when the instance states `initialsFontRatio`, the
  /// diameter-scaled font-size. A `fallbackTextStyle.fontSize` override
  /// wins over the ratio (mirrors the Flutter resolver). `rem` carries the
  /// browser font-size accessibility scale.
  Styles buildInitialsInlineStyles() {
    final raw = {...?initialsEmit.inline};
    if (initialsFontRatio != null) {
      raw['font-size'] ??=
          '${(initialsDiameter * initialsFontRatio) / kRemDivisor}rem';
    }
    return Styles(raw: raw);
  }

  /// Composes the badge positioning slot inline-CSS bundle — puts the
  /// slot's anchor point where [CoreAvatarStyle.badgeAnchorFor] places it
  /// (logical px → rem) and translates the slot by the badge's own anchor
  /// fraction, so a badge of any size lands on it. The same Core call the
  /// Flutter `_AvatarBadgeLayout` reads, so the badge lands at the same
  /// spot on both platforms.
  ///
  /// Pinned: the anchor is a position against the avatar's edge, which the
  /// Flutter twin leaves out of the density.
  Styles buildBadgeSlotInlineStyles() {
    final anchor = CoreAvatarStyle.badgeAnchorFor(
      diameter: initialsDiameter,
      inset: badgeInset,
      alignment: badgeAlignment,
      placement: badgePlacement,
    );
    String percent(double fraction) {
      final value = -fraction * 100;
      return value == value.roundToDouble() ? '${value.toInt()}%' : '$value%';
    }

    return Styles(
      raw: {
        'left': pinnedLengthCss(anchor.x),
        'top': pinnedLengthCss(anchor.y),
        'transform':
            'translate(${percent(anchor.alignX)}, ${percent(anchor.alignY)})',
      },
    );
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedAvatar(
    root: const WebElementChrome(className: WebLayout.relativeInlineBlock),
    avatarBoxStyle: avatarBoxStyle,
    ringWrapper: buildRingWrapper(),
    image: WebElementChrome(className: buildImageClassName()),
    initials: WebElementChrome(
      className: buildInitialsClassName(),
      inlineStyles: buildInitialsInlineStyles(),
    ),
    badgeSlot: WebElementChrome(
      // `flex` shrinks the slot to the badge it holds, so the translate's
      // percentages are the badge's own size — a block slot would add the
      // line box below an inline badge.
      className: '${WebLayout.absolute} ${WebLayout.flex}',
      inlineStyles: buildBadgeSlotInlineStyles(),
    ),
    badgeStyle: badgeStyle,
    childIconStyle: childIconStyle,
  );
}

// ═══════════════════════════════════════════════════
// Resolved output — AvatarBadge
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `AvatarBadge`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // bg + size + radius dot + inner ring
///   └─ caller-supplied child                // co_avatar_badge renders only when child != null
/// ```
///
/// Single-slot resolver — the badge is one filled circle whose
/// chrome (background, size, radius) is folded once into [root].
class ResolvedAvatarBadge implements WebResolvedChrome {
  /// Creates a [ResolvedAvatarBadge].
  const ResolvedAvatarBadge({required this.root});

  /// Paint-ready chrome for the badge `<div>` — sizing / radius
  /// className with default bg class when no override applies, plus
  /// inline-CSS for background / size overrides.
  @override
  final WebElementChrome root;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAvatarBadge] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → inheritedStyle (the enclosing Avatar's step size)
///   → widget.avatarBadgeStyle
/// ```
ResolvedAvatarBadge resolveAvatarBadge(
  BuildContext context, {
  CoreAvatarBadgeStyle? inheritedStyle,
  CoreAvatarBadgeStyle? avatarBadgeStyle,
}) {
  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreAvatarBadgeStyle(), [
    inheritedStyle,
    avatarBadgeStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final backgroundColor = merged.backgroundColor;
  // Size is **always** emitted inline (`(merged ?? default)/rem`) — the
  // badge has no `borderRadius` override field, so its always-circular
  // radius is promoted (not dropped) to a single always-inline surface
  // shared with the size (Epic #1603 single-signature gate).
  final sizePx = merged.size ?? CoreAvatarBadgeStyle.defaultSize;
  final borderRadius = CoreAvatarStyle.defaultBorderRadius.toValue();
  final borderColor =
      merged.borderColor ?? CoreAvatarBadgeStyle.defaultBorderColor;
  final borderWidth =
      merged.borderWidth ?? CoreAvatarBadgeStyle.defaultBorderWidth;

  // ─── Local builders ───────────────────────────────────

  /// Composes the badge dot Tailwind className — layout primitives +
  /// the default background colour-token class when no inline override
  /// applies. Size and border radius are always emitted inline (see
  /// [buildRootInlineStyles]) — no `rounded-*` / `w-*` / `h-*` class.
  String buildRootClassName() {
    final bgClass = backgroundColor == null
        ? 'bg-${CoreAvatarBadgeStyle.defaultBackgroundColor.tailwindColor}'
        : '';
    return <String>[
      WebLayout.inlineFlexCenter,
      if (bgClass.isNotEmpty) bgClass,
    ].join(' ');
  }

  /// Composes the badge dot inline-CSS bundle — always emits the size
  /// (`(merged ?? default)/rem`), the always-circular border radius and the
  /// inner ring; the background colour override is layered on when
  /// supplied.
  Styles buildRootInlineStyles() {
    final raw = <String, String>{};
    if (backgroundColor != null) {
      // Web EMIT is theme-free — token → var(--coui-X), raw → rgba (no
      // `scheme.resolve` no-op).
      raw['background-color'] = backgroundColor.toValue();
    }
    // Size and radius are always inline — default and override share
    // these surfaces so the resolved chrome reflects `merged.size`
    // directly.
    raw['width'] = '${sizePx / kRemDivisor}rem';
    raw['height'] = '${sizePx / kRemDivisor}rem';
    raw['border-radius'] = borderRadius;
    // The ring inside the dot's edge — an inset `box-shadow`, which paints
    // inward and takes no layout, so the dot keeps its size (the Flutter
    // twin's foreground decoration). Theme-free: token → var(--coui-X).
    if (borderWidth > 0) {
      raw['box-shadow'] =
          'inset 0 0 0 ${strokeWidthCss(borderWidth)} ${borderColor.toValue()}';
    }
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedAvatarBadge(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// Resolved output — AvatarGroup
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `AvatarGroup`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                              // flex (+ flex-row-reverse)
///   ├─ caller-supplied Avatar             // the first child — `item` chrome
///   ├─ caller-supplied Avatar             // every later child — `followingItem` chrome (overlap)
///   └─ ...
/// ```
///
/// `co_avatar_group.dart` reads `resolved.root.className` /
/// `inlineStyles` for the container and `resolved.item` /
/// `resolved.followingItem` for each child — every per-child border /
/// colour override and the overlap are baked into those chromes here.
class ResolvedAvatarGroup implements WebResolvedChrome {
  /// Creates a [ResolvedAvatarGroup].
  const ResolvedAvatarGroup({
    required this.root,
    required this.item,
    required this.followingItem,
  });

  /// Paint-ready chrome for the outer container `<div>` — flex layout
  /// className (`flex-row-reverse` when the direction is right-stacked),
  /// plus the optional inline `column-gap` override carrying the
  /// `extraSpacing` paint-time positive offset.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome wrapped around the first child avatar — adds
  /// the per-item separator border (default class fallback + optional
  /// inline width / colour override).
  final WebElementChrome item;

  /// Paint-ready chrome wrapped around every child after the first —
  /// [item]'s chrome plus the negative `margin-left` that pulls the child
  /// back over its predecessor by the overlap.
  final WebElementChrome followingItem;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedAvatarGroup] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → widget.avatarGroupStyle
/// ```
ResolvedAvatarGroup resolveAvatarGroup(
  BuildContext context, {
  required CoreAvatarGroupDirection direction,
  CoreAvatarGroupStyle? avatarGroupStyle,
}) {
  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreAvatarGroupStyle(), [
    avatarGroupStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final extraSpacingPx = merged.extraSpacing;
  final overlapPx = merged.overlap ?? CoreAvatarGroupStyle.defaultOverlap;
  final borderColor = merged.borderColor;
  final borderWidthEmit = emitStrokeWidth(
    merged.borderWidth,
    CoreAvatarGroupStyle.defaultBorderWidth,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes the container Tailwind className — `flex` (and
  /// `flex-row-reverse` when the group stacks toward the right). The
  /// overlap is not a class: see [buildFollowingItemInlineStyles].
  String buildRootClassName() => switch (direction) {
    .toLeft => WebLayout.flex,
    .toRight => '${WebLayout.flex} ${WebLayout.flexRowReverse}',
  };

  /// Composes the container inline-CSS bundle — emits the optional
  /// extra paint-time positive `column-gap` override (re-injected on
  /// top of the default negative overlap class).
  Styles? buildRootInlineStyles() {
    if (extraSpacingPx == null) return null;
    return Styles(
      raw: {'column-gap': spaceCss(extraSpacingPx)},
    );
  }

  /// Composes the per-item separator border Tailwind className —
  /// default `border-*` width + colour classes are stripped when the
  /// user supplied the corresponding inline override.
  String buildItemClassName() {
    final borderWidthClass = borderWidthEmit.className;
    final borderColorClass = borderColor == null
        ? 'border-${CoreAvatarGroupStyle.defaultBorderColor.tailwindColor}'
        : '';
    return [
      if (borderWidthClass.isNotEmpty) borderWidthClass,
      if (borderColorClass.isNotEmpty) borderColorClass,
    ].join(' ');
  }

  /// Composes the per-item inline-CSS map — border-colour and
  /// border-width overrides when the user provided them.
  Map<String, String> buildItemInlineRaw() => {
    // Web EMIT is theme-free — token → var(--coui-X), raw → rgba (no
    // `scheme.resolve` no-op).
    if (borderColor != null) 'border-color': borderColor.toValue(),
    ...?borderWidthEmit.inline,
  };

  /// Composes the per-item inline-CSS bundle — [buildItemInlineRaw], or
  /// `null` when the user overrode nothing.
  Styles? buildItemInlineStyles() {
    final raw = buildItemInlineRaw();
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  /// Composes the inline-CSS bundle of every child after the first — the
  /// item overrides plus the overlap as a negative `margin-left` (the
  /// same side the Tailwind `-space-x-*` utility pulls on, so either
  /// direction lays out as it did).
  ///
  /// Pinned: the overlap is a position the Flutter twin translates each
  /// avatar by and leaves out of the density, so it must not name a
  /// spacing variable here — a utility class would, and the avatars
  /// would slide apart on Web alone. `extraSpacing` is spacing and stays
  /// on the container's `column-gap`.
  Styles buildFollowingItemInlineStyles() => Styles(
    raw: {
      ...buildItemInlineRaw(),
      'margin-left': pinnedLengthCss(-overlapPx),
    },
  );

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedAvatarGroup(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    item: WebElementChrome(
      className: buildItemClassName(),
      inlineStyles: buildItemInlineStyles(),
    ),
    followingItem: WebElementChrome(
      className: buildItemClassName(),
      inlineStyles: buildFollowingItemInlineStyles(),
    ),
  );
}
