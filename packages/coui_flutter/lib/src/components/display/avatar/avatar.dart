import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

/// Reports "no baseline" for its subtree so a baseline query never
/// descends into it.
///
/// The ring layer below is `Position`-ed *decoration* (`IgnorePointer`,
/// not content) inside a [Stacks]. A stack's baseline must come from its
/// real content child, never from a decorative overlay — but
/// `RenderStack.computeDryBaseline` queries every child, positioned ones
/// included, via `getDryBaseline`. A childless decorative box
/// (`RenderDecoratedBox`) then asserts in `computeDryBaseline`, which
/// surfaces the moment a baseline-driven ancestor (an inline `Table`
/// cell, a `WidgetSpan`) asks the stack for a dry baseline. Mirrors
/// `FocusOutline`'s `_NoBaseline` — duplicated rather than shared
/// because it is private to that file.
class _NoBaseline extends SingleChildRenderObjectWidget {
  const _NoBaseline({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNoBaseline();
}

class _RenderNoBaseline extends RenderProxyBox {
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => null;

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => null;
}

/// Unified cross-platform avatar with token-based rendering.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [avatarStyle] (a [CoreAvatarStyle]). The
/// semantic enums (`size`, `shape`) and behaviour (`ring` / `badge`) stay
/// flat on the widget. Every chrome default — fill colour, ring colour,
/// border radius, badge gap, badge alignment — lives on
/// `CoreAvatarStyle.defaultX` as a `static const` so Flutter and Web
/// share a single source of truth.
///
/// ```text
/// CoreAvatarStyle.defaultX
///   → CoreAvatarTheme.style
///   → widget.avatarStyle
/// ```
///
/// Example:
/// ```dart
/// Avatar(
///   imageUrl: 'https://example.com/photo.jpg',
///   initials: 'JD',
///   size: CoreComponentSize.lg,
///   badge: AvatarBadge(
///     avatarBadgeStyle: CoreAvatarBadgeStyle(
///       backgroundColor: CoreColor.token(CoreColors.success),
///     ),
///   ),
/// )
/// ```
class Avatar extends StatelessWidget implements CoreAvatarContract<Widget> {
  /// Creates a [Avatar].
  const Avatar({
    this.imageUrl,
    this.initials,
    super.key,
    this.size = CoreAvatarContract.defaultSize,
    this.shape = CoreAvatarShape.defaultShape,
    this.ring = false,
    this.child,
    this.badge,
    this.avatarStyle,
  });

  /// Extracts initials from a full name.
  ///
  /// Single word: first two characters (e.g. "John" -> "JO").
  /// Multiple words: first character of each of the first two
  /// words (e.g. "John Doe" -> "JD").
  static String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) {
      final word = parts.first;
      if (word.length > 1) {
        return '${word[0]}${word[1]}'.toUpperCase();
      }
      return word[0].toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  final String? imageUrl;

  @override
  final String? initials;

  @override
  final CoreComponentSize size;

  @override
  final CoreAvatarShape shape;

  @override
  final bool ring;

  @override
  final Widget? child;

  @override
  final Widget? badge;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `fallbackTextStyle` slot for the initials fallback. See
  /// [CoreAvatarStyle] for the merge chain. The badge corner override
  /// flows through `avatarStyle.badgeAlignment`.
  @override
  final CoreAvatarStyle? avatarStyle;

  Widget _buildInitials(ResolvedAvatar resolved) {
    final text = (initials ?? '?').substring(
      0,
      (initials?.length ?? 1).clamp(0, 2),
    );
    // Resolver returns a paint-ready `TextStyle` (typography role +
    // slot override + deterministic font-size / colour fallback already
    // layered) — the widget forwards it raw.
    //
    // The disc is a fixed size and the initials only mark a name that is
    // written beside it, so the OS text scale does not reach them: grown with
    // it, two letters outgrow the disc, wrap onto two lines and are cut off
    // (a `CircleAvatar` shields its child the same way).
    return MediaQuery.withNoTextScaling(
      child: Text(text, style: resolved.fallbackTextStyle),
    );
  }

  /// Returns a copy of this [Avatar] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Avatar copyWith({
    Key? key,
    String? imageUrl,
    String? initials,
    CoreComponentSize? size,
    CoreAvatarShape? shape,
    bool? ring,
    Widget? badge,
    CoreAvatarStyle? avatarStyle,
    Widget? child,
  }) {
    return Avatar(
      key: key ?? this.key,
      imageUrl: imageUrl ?? this.imageUrl,
      initials: initials ?? this.initials,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      ring: ring ?? this.ring,
      badge: badge ?? this.badge,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      child: child ?? this.child,
    );
  }

  // The initials are sized to fill a disc whose diameter is the step's at
  // every viewport width, so the avatar states the tier its box was drawn
  // for — the desktop one — rather than let a narrow viewport shrink the
  // glyphs inside an unchanged disc. The Web twin states the same scope.
  @override
  Widget build(BuildContext context) => TypographyTierScope(
    tier: .desktop,
    child: Builder(builder: _buildAvatar),
  );

  Widget _buildAvatar(BuildContext context) {
    final resolved = resolveAvatar(
      context,
      size: size,
      shape: shape,
      ring: ring,
      avatarStyle: avatarStyle,
    );
    final avatarSize = resolved.diameter;

    // Determine content.
    final initialsFallback = _buildInitials(resolved);
    Widget content;
    if (child != null) {
      // An `Icon` handed as `child` that states no size draws at the step's
      // icon size — about half the diameter.
      content = IconTheme.merge(data: resolved.childIconTheme, child: child!);
    } else if (imageUrl != null) {
      // No clip of its own: `OutlinedContainer` below clips its child to
      // the corner it paints (anti-aliased), so the picture takes the
      // avatar's shape — a disc or a rounded tile — the same way the Web
      // twin's `overflow: hidden` box does. A circle clip here would cut a
      // rounded tile's picture into an oval.
      content = Image.network(
        imageUrl!,
        errorBuilder: (_, _, _) => initialsFallback,
        semanticLabel: initials ?? 'avatar',
        width: avatarSize,
        height: avatarSize,
        fit: .cover,
      );
    } else {
      content = initialsFallback;
    }

    // Outer chrome — composed `OutlinedContainer` (background / ring
    // border / radius / clip / surface material / injected control-shadow),
    // not a hand-rolled `Container(decoration: BoxDecoration(...))`. The
    // corner is the shape's: a disc's pill clamps to a perfect circle on a
    // square box the same way the Web `border-radius: 9999px` twin does,
    // and a rounded tile's step corner is drawn as stated, so no separate
    // `shape: .circle` branch is needed.
    Widget avatar = OutlinedContainer(
      containerStyle: resolved.containerStyle,
      child: Center(child: content),
    );

    // Ring — a standoff overlay outside the avatar's own bounds, not a
    // border on `containerStyle` (a border paints *on* the edge, so it
    // cannot express `ringOffset`'s gap). `Stacks(fit: .passthrough,
    // clipBehavior: .none)` lets these decorative layers paint beyond
    // the avatar without growing the layout box `_AvatarBadgeLayout`
    // below sizes against. Two layers: an offset (gap) layer sits
    // *behind* the avatar, filled with `ringOffsetColor` — since the
    // avatar itself is always opaque, that fill shows only in the gap
    // band around its edge, never over its own content. (`FocusOutline`
    // strokes its band instead, because the controls it wraps can be
    // translucent.) The ring stroke layer sits on top, further out by
    // `ringWidth`. Both layers take the corner the resolver grew from the
    // avatar's own — a disc's ring stays a circle, a rounded tile's ring
    // keeps the tile's curve — so the widget does no corner math.
    if (ring) {
      final offsetExtent = resolved.ringOffset;
      final ringExtent = resolved.ringOffset + resolved.ringWidth;
      avatar = Stacks(
        fit: .passthrough,
        clipBehavior: .none,
        children: [
          Position(
            top: -offsetExtent,
            right: -offsetExtent,
            bottom: -offsetExtent,
            left: -offsetExtent,
            child: _NoBaseline(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: resolved.ringOffsetColor,
                    borderRadius: resolved.ringOffsetBorderRadius,
                  ),
                ),
              ),
            ),
          ),
          avatar,
          Position(
            top: -ringExtent,
            right: -ringExtent,
            bottom: -ringExtent,
            left: -ringExtent,
            child: _NoBaseline(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: resolved.ringColor,
                      width: resolved.ringWidth,
                    ),
                    borderRadius: resolved.ringBorderRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // If no badge, return the plain avatar.
    if (badge == null) {
      return avatar;
    }

    // Badge overlay using Stack — anchored where the resolver places it,
    // with the step's badge style handed down to the slot.
    return _AvatarBadgeLayout(
      avatarSize: avatarSize,
      left: resolved.badgeLeft,
      top: resolved.badgeTop,
      anchor: resolved.badgeAnchor,
      badge: AvatarBadgeScope(style: resolved.badgeStyle, child: badge!),
      child: avatar,
    );
  }
}

/// Chain sugar for merging a [CoreAvatarStyle] patch into
/// [Avatar.avatarStyle] without hand-reconstructing every field.
/// Mirrors the Web `Avatar.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreAvatarStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreAvatarStyle.borderRadius] and `.primary` sets
/// [CoreAvatarStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Avatar(initials: 'JD').radius4.primary
/// ```
extension AvatarStyleChain on Avatar {
  /// Sets the background paint and preserves the other style fields.
  Avatar backgroundColor(CoreColor value) =>
      withStyle(CoreAvatarStyle(backgroundColor: value));

  /// Returns a copy of this [Avatar] with [patch] merged into
  /// [avatarStyle] (patch fields win on conflict).
  Avatar withStyle(CoreAvatarStyle patch) => copyWith(
    avatarStyle: (avatarStyle ?? const CoreAvatarStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Avatar get radius0 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Avatar get radius2 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Avatar get radius4 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Avatar get radius6 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Avatar get radius8 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Avatar get radius10 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Avatar get radius12 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Avatar get radius14 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Avatar get radius16 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Avatar get radius20 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Avatar get radius24 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Avatar get radius28 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Avatar get radius32 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Avatar get radius36 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Avatar get radius40 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Avatar get radius48 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Avatar get radius56 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Avatar get radius64 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Avatar get radius9999 => withStyle(
    const CoreAvatarStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Avatar get primary => withStyle(
    const CoreAvatarStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Avatar get secondary => withStyle(
    const CoreAvatarStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Avatar get tertiary => withStyle(
    const CoreAvatarStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Avatar get surface => withStyle(
    const CoreAvatarStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Avatar get surfaceContainer => withStyle(
    const CoreAvatarStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Avatar get error => withStyle(
    const CoreAvatarStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Avatar get success => withStyle(
    const CoreAvatarStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Avatar get warning => withStyle(
    const CoreAvatarStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Avatar get info => withStyle(
    const CoreAvatarStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Avatar get outline => withStyle(
    const CoreAvatarStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Avatar get transparent =>
      withStyle(const CoreAvatarStyle(backgroundColor: .transparent));
}

// ---------------------------------------------------------------------------
// Badge layout helper (internal).
// ---------------------------------------------------------------------------

class _AvatarBadgeLayout extends StatelessWidget {
  const _AvatarBadgeLayout({
    required this.avatarSize,
    required this.left,
    required this.top,
    required this.anchor,
    required this.badge,
    required this.child,
  });

  final double avatarSize;

  /// The anchor point, from the avatar box's top-left (paint-ready).
  final double left;
  final double top;

  /// The point of the badge's own box that sits on the anchor, as
  /// fractions of its size.
  final Offset anchor;
  final Widget badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The badge's anchor point lands on (`left`, `top`) whatever size the
    // badge draws at — the same translate the Web build applies in CSS.
    return SizedBox(
      width: avatarSize,
      height: avatarSize,
      child: Stacks(
        clipBehavior: .none,
        children: [
          child,
          Position(
            top: top,
            left: left,
            child: FractionalTranslation(
              translation: -anchor,
              child: badge,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hands the badge in an [Avatar]'s `badge` slot its step's style.
///
/// An [AvatarBadge] below lays its own `avatarBadgeStyle` over this one, so
/// the avatar sets the default size and a size the badge states wins.
/// Named and shaped like the Web counterpart so the two platforms read the
/// same.
///
/// Not exported from the package — the avatar mounts it around its own
/// badge slot.
class AvatarBadgeScope extends InheritedWidget {
  /// Creates a scope handing [style] to the badge in [child].
  const AvatarBadgeScope({
    required this.style,
    required super.child,
    super.key,
  });

  /// The style the enclosing avatar hands its badge.
  final CoreAvatarBadgeStyle style;

  /// The nearest enclosing avatar's badge style, or `null`.
  static CoreAvatarBadgeStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AvatarBadgeScope>()?.style;

  @override
  bool updateShouldNotify(AvatarBadgeScope oldWidget) =>
      style != oldWidget.style;
}

// ---------------------------------------------------------------------------
// AvatarBadge
// ---------------------------------------------------------------------------

/// A circular badge indicator overlaid on a [Avatar].
///
/// Shows a colored dot or custom child. Used for online status,
/// notification counts, etc.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [avatarBadgeStyle] (a [CoreAvatarBadgeStyle]).
class AvatarBadge extends StatelessWidget
    implements CoreAvatarBadgeContract<Widget> {
  /// Creates a [AvatarBadge].
  const AvatarBadge({
    this.child,
    super.key,
    this.avatarBadgeStyle,
  });

  @override
  final Widget? child;

  /// Per-instance composite style — chrome flat fields. See
  /// [CoreAvatarBadgeStyle] for the merge chain.
  @override
  final CoreAvatarBadgeStyle? avatarBadgeStyle;

  /// Returns a copy of this [AvatarBadge] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  AvatarBadge copyWith({
    Key? key,
    CoreAvatarBadgeStyle? avatarBadgeStyle,
    Widget? child,
  }) {
    return AvatarBadge(
      key: key ?? this.key,
      avatarBadgeStyle: avatarBadgeStyle ?? this.avatarBadgeStyle,
      child: child ?? this.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAvatarBadge(
      context,
      inheritedStyle: AvatarBadgeScope.maybeOf(context),
      avatarBadgeStyle: avatarBadgeStyle,
    );
    final resolvedSize = resolved.size;

    // The ring is a foreground decoration painted inside the dot's edge,
    // so it neither grows the dot nor insets the child — the same inward
    // ring the Web build draws with an inset `box-shadow`.
    return Container(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        shape: .circle,
      ),
      foregroundDecoration: resolved.borderWidth > 0
          ? BoxDecoration(
              border: Border.all(
                color: resolved.borderColor,
                width: resolved.borderWidth,
              ),
              shape: .circle,
            )
          : null,
      width: resolvedSize,
      height: resolvedSize,
      child: child != null ? Center(child: child) : null,
    );
  }
}

/// Chain sugar for merging a [CoreAvatarBadgeStyle] patch into
/// [AvatarBadge.avatarBadgeStyle] without hand-reconstructing every
/// field. Mirrors the Web `AvatarBadge.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreAvatarBadgeStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreAvatarBadgeStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// AvatarBadge().success
/// ```
extension AvatarBadgeStyleChain on AvatarBadge {
  /// Sets the border color.
  AvatarBadge borderColor(CoreColor value) =>
      withStyle(CoreAvatarBadgeStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  AvatarBadge borderWidth(double value) =>
      withStyle(CoreAvatarBadgeStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  AvatarBadge backgroundColor(CoreColor value) =>
      withStyle(CoreAvatarBadgeStyle(backgroundColor: value));

  /// Returns a copy of this [AvatarBadge] with [patch] merged into
  /// [avatarBadgeStyle] (patch fields win on conflict).
  AvatarBadge withStyle(CoreAvatarBadgeStyle patch) => copyWith(
    avatarBadgeStyle: (avatarBadgeStyle ?? const CoreAvatarBadgeStyle()).merge(
      patch,
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  AvatarBadge get primary => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  AvatarBadge get secondary => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  AvatarBadge get tertiary => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  AvatarBadge get surface => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  AvatarBadge get surfaceContainer => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  AvatarBadge get error => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  AvatarBadge get success => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  AvatarBadge get warning => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  AvatarBadge get info => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  AvatarBadge get outline => withStyle(
    const CoreAvatarBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  AvatarBadge get transparent => withStyle(
    const CoreAvatarBadgeStyle(backgroundColor: .transparent),
  );
}

// ---------------------------------------------------------------------------
// AvatarGroup
// ---------------------------------------------------------------------------

/// Displays multiple [Avatar] widgets in an overlapping layout.
///
/// Example:
/// ```dart
/// AvatarGroup(
///   children: [
///     Avatar(imageUrl: 'url1', initials: 'A'),
///     Avatar(imageUrl: 'url2', initials: 'B'),
///     Avatar(initials: 'C'),
///   ],
///   max: 3,
/// )
/// AvatarGroup.toRight(children: [...])
/// ```
class AvatarGroup extends StatelessWidget
    implements CoreAvatarGroupContract<Avatar> {
  /// Creates a [AvatarGroup] stacked to the left (default).
  const AvatarGroup({
    required this.children,
    super.key,
    this.direction = CoreAvatarGroupDirection.toLeft,
    this.max,
    this.avatarGroupStyle,
  });

  /// Creates a [AvatarGroup] stacked to the left.
  const AvatarGroup.toLeft({
    required this.children,
    super.key,
    this.max,
    this.avatarGroupStyle,
  }) : direction = CoreAvatarGroupDirection.toLeft;

  /// Creates a [AvatarGroup] stacked to the right.
  const AvatarGroup.toRight({
    required this.children,
    super.key,
    this.max,
    this.avatarGroupStyle,
  }) : direction = CoreAvatarGroupDirection.toRight;

  @override
  final List<Avatar> children;

  @override
  final CoreAvatarGroupDirection direction;

  @override
  final int? max;

  /// Per-instance composite style — chrome flat fields. See
  /// [CoreAvatarGroupStyle] for the merge chain.
  @override
  final CoreAvatarGroupStyle? avatarGroupStyle;

  /// Returns a copy of this [AvatarGroup] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  AvatarGroup copyWith({
    Key? key,
    CoreAvatarGroupDirection? direction,
    int? max,
    CoreAvatarGroupStyle? avatarGroupStyle,
    List<Avatar>? children,
  }) {
    return AvatarGroup(
      key: key ?? this.key,
      direction: direction ?? this.direction,
      max: max ?? this.max,
      avatarGroupStyle: avatarGroupStyle ?? this.avatarGroupStyle,
      children: children ?? this.children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAvatarGroup(
      context,
      avatarGroupStyle: avatarGroupStyle,
    );

    final visible = max != null && max! < children.length
        ? children.sublist(0, max)
        : children;
    final remaining = max != null && max! < children.length
        ? children.length - max!
        : 0;

    // Build the list of avatar widgets including the "+N" overflow.
    final avatars = <Widget>[...visible];
    if (remaining > 0) {
      avatars.add(
        Avatar(initials: '+$remaining', size: visible.first.size),
      );
    }

    // Reverse for toRight direction so overlap order is correct.
    final ordered = direction == .toRight ? avatars.reversed.toList() : avatars;

    return _AvatarGroupLayout(
      avatars: ordered,
      overlap: resolved.overlap,
      extraSpacing: resolved.extraSpacing,
      borderColor: resolved.borderColor,
      borderWidth: resolved.borderWidth,
      defaultDiameter: resolved.defaultDiameter,
      direction: direction,
    );
  }
}

/// Chain sugar for merging a [CoreAvatarGroupStyle] patch into
/// [AvatarGroup.avatarGroupStyle] without hand-reconstructing every
/// field. Mirrors the Web `AvatarGroup.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreAvatarGroupStyle.merge` right-side-wins semantics).
extension AvatarGroupStyleChain on AvatarGroup {
  /// Sets the border color.
  AvatarGroup borderColor(CoreColor value) =>
      withStyle(CoreAvatarGroupStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  AvatarGroup borderWidth(double value) =>
      withStyle(CoreAvatarGroupStyle(borderWidth: value));

  /// Returns a copy of this [AvatarGroup] with [patch] merged into
  /// [avatarGroupStyle] (patch fields win on conflict).
  AvatarGroup withStyle(CoreAvatarGroupStyle patch) => copyWith(
    avatarGroupStyle: (avatarGroupStyle ?? const CoreAvatarGroupStyle()).merge(
      patch,
    ),
  );
}

// ---------------------------------------------------------------------------
// Group layout helper (internal).
// ---------------------------------------------------------------------------

class _AvatarGroupLayout extends StatelessWidget {
  const _AvatarGroupLayout({
    required this.avatars,
    required this.overlap,
    required this.extraSpacing,
    required this.borderColor,
    required this.borderWidth,
    required this.defaultDiameter,
    required this.direction,
  });

  final List<Widget> avatars;
  final double overlap;
  final double extraSpacing;
  final Color borderColor;
  final double borderWidth;
  final double defaultDiameter;
  final CoreAvatarGroupDirection direction;

  double _estimateHeight(BuildContext context) {
    // Use the default (md) avatar diameter as height estimate. Add ring
    // width for the per-item separator border.
    return defaultDiameter + borderWidth * 2;
  }

  @override
  Widget build(BuildContext context) {
    if (avatars.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (int i = 0; i < avatars.length; i += 1) {
      Widget avatar = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          shape: .circle,
        ),
        child: avatars[i],
      );

      children.add(avatar);
    }

    return SizedBox(
      height: _estimateHeight(context),
      child: Row(
        mainAxisSize: .min,
        children: [
          for (int i = 0; i < children.length; i += 1)
            Transform.translate(
              offset: Offset(
                i > 0 ? -overlap * i + extraSpacing * i : 0,
                0,
              ),
              child: children[i],
            ),
        ],
      ),
    );
  }
}
