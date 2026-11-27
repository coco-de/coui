import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/typography_tier_scope.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/display/avatar/avatar_style.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform avatar for CoUI Web.
///
/// Per Epic #1302 every chrome / dimensional / nested-slot override
/// flows through the single [avatarStyle] (a [CoreAvatarStyle]). The
/// semantic enums (`size`, `shape`) and behaviour (`ring` / `badge`) stay
/// flat on the component. Every chrome default — fill colour, ring colour,
/// border radius, badge gap, badge alignment — lives on
/// `CoreAvatarStyle.defaultX` as a `static const` so Flutter and Web
/// share a single source of truth.
///
/// ```text
/// CoreAvatarStyle.defaultX
///   → CoreAvatarTheme.style
///   → component.avatarStyle
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
class Avatar extends UiComponent implements CoreAvatarContract<Component> {
  /// Creates a [Avatar].
  ///
  /// Avatar took only `key` and `id` — no way to attach a CSS class, an
  /// inline style, an `aria-label`, or a `data-*` hook. Same gap as Chip
  /// had; Card / Button / Divider have carried the full set all along.
  Avatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = CoreAvatarContract.defaultSize,
    this.shape = CoreAvatarShape.defaultShape,
    this.ring = false,
    this.child,
    super.id,
    this.badge,
    this.avatarStyle,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component? child;

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
  final Component? badge;

  /// Per-instance composite style. See [CoreAvatarStyle] for the
  /// merge chain. The badge corner override flows through
  /// `avatarStyle.badgeAlignment`.
  @override
  final CoreAvatarStyle? avatarStyle;

  /// Extracts initials from a full name.
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

  /// Returns a copy with the given fields replaced — the caller's
  /// `classes` / `css` / `attributes` / event handlers included, so a
  /// `.withStyle(...)` or `.radiusN` chain keeps every hook the caller
  /// put on the avatar.
  @override
  Avatar copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? imageUrl,
    String? initials,
    CoreComponentSize? size,
    CoreAvatarShape? shape,
    bool? ring,
    Component? child,
    Component? badge,
    CoreAvatarStyle? avatarStyle,
  }) {
    return Avatar(
      key: key ?? this.key,
      imageUrl: imageUrl ?? this.imageUrl,
      initials: initials ?? this.initials,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      ring: ring ?? this.ring,
      id: id ?? this.id,
      badge: badge ?? this.badge,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers,
      child: child ?? this.child,
    );
  }

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add('role', 'img');
    final alt = initials ?? 'avatar';
    attributes.add('aria-label', alt);
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveAvatar(
      context,
      size: size,
      shape: shape,
      ring: ring,
      avatarStyle: avatarStyle,
    );

    // Content slot — child / image / initials, held to the desktop tier.
    // The box keeps one diameter at every viewport width and the initials
    // role was picked to fill it, so the letters keep their size too. The
    // Flutter twin states the same tier around the whole avatar, badge
    // included; here the scope sits inside the box and inside the badge
    // slot instead, not around the avatar: its wrapper draws no box, and
    // around the root it would be the sibling a parent's `space-x-*` or
    // `:first-child` reaches instead of the avatar.
    final Component slot;
    if (child != null) {
      // An `Icon` handed as `child` that states no size draws at the step's
      // icon size — about half the diameter (mirrors the Flutter twin).
      slot = IconTheme(
        data: IconThemeData.fromCoreIconStyle(resolved.childIconStyle),
        child: child!,
      );
    } else if (imageUrl != null) {
      slot = Component.element(
        tag: 'img',
        classes: resolved.image.className,
        styles: resolved.image.inlineStyles,
        attributes: {
          'src': imageUrl!,
          'alt': initials ?? 'avatar',
        },
      );
    } else {
      final text = (initials ?? '?').substring(
        0,
        (initials?.length ?? 1).clamp(0, 2),
      );
      slot = span(
        [Text(text)],
        classes: resolved.initials.className,
        styles: resolved.initials.inlineStyles,
      );
    }
    final content = TypographyTierScope(tier: .desktop, child: slot);

    final currentBadge = badge;
    final Component avatarTree;
    if (currentBadge == null) {
      // Avatar box is the root — composed `OutlinedContainer`
      // (background / radius / size / clip), not a hand-rolled chrome
      // `<div>` (`core/style-contract.md`'s child-component-composition
      // rule). The corner is the shape's: a disc's `radius9999` clips to a
      // perfect circle on a square box via `overflow: hidden`, a rounded
      // tile's step corner clips the picture to the tile, matching the
      // Flutter twin. id / attributes / events pass through here.
      //
      // `OutlinedContainer` composes background / radius / size / clip
      // only — it never centers its child (mirrors the Flutter twin,
      // which wraps `content` in `Center` before handing it to the same
      // `OutlinedContainer`). `WebLayout.inlineFlexCenter` rides in on
      // the box's own root className (via `classes:`, merged ahead of
      // any caller-supplied classes) rather than an extra wrapper
      // `<div>` — no new DOM node, so the box's own child count stays
      // exactly the one `content` element, and `inline-flex` (not
      // `flex`) keeps the box's own display type identical to what the
      // hand-rolled box had before this became a composed
      // `OutlinedContainer`. The `<img>` content is unaffected since it
      // already fills the box via `w-full h-full object-cover`.
      avatarTree = OutlinedContainer(
        containerStyle: resolved.avatarBoxStyle,
        id: id,
        classes: mergeClasses(classes, WebLayout.inlineFlexCenter),
        css: css,
        attributes: componentAttributes,
        eventHandlers: eventHandlers,
        child: content,
      );
    } else {
      // Inner avatar box (no id / attrs / events — those live on root
      // wrapper).
      final avatarBox = OutlinedContainer(
        containerStyle: resolved.avatarBoxStyle,
        classes: WebLayout.inlineFlexCenter,
        child: content,
      );

      avatarTree = div(
        [
          avatarBox,
          div(
            [
              TypographyTierScope(
                tier: .desktop,
                child: AvatarBadgeScope(
                  style: resolved.badgeStyle,
                  child: currentBadge,
                ),
              ),
            ],
            classes: resolved.badgeSlot.className,
            styles: resolved.badgeSlot.inlineStyles,
          ),
        ],
        id: id,
        classes: [resolved.root.className, ?classes].join(' ').trim(),
        styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
        attributes: componentAttributes,
        events: events,
      );
    }

    // Ring — a purely decorative standoff wrapper outside the avatar's
    // own bounds, not a border on `avatarBoxStyle` (a border paints *on*
    // the edge, so it cannot express the ring's gap). `box-shadow` never
    // affects layout, so this wrapper adds no footprint beyond the
    // avatar's own box; `null` when `ring` is `false`, so a non-ringed
    // avatar's DOM shape is unchanged.
    final ringWrapper = resolved.ringWrapper;
    if (ringWrapper == null) {
      return avatarTree;
    }
    return div(
      [avatarTree],
      classes: ringWrapper.className,
      styles: ringWrapper.inlineStyles,
    );
  }
}

/// Chain sugar mirroring the Flutter `Avatar.withStyle` extension —
/// merges a [CoreAvatarStyle] patch into [Avatar.avatarStyle] via the
/// existing [Avatar.copyWith].
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

/// A circular badge indicator overlaid on a [Avatar].
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [avatarBadgeStyle] (a [CoreAvatarBadgeStyle]).
class AvatarBadge extends UiComponent
    implements CoreAvatarBadgeContract<Component> {
  /// Creates a [AvatarBadge].
  AvatarBadge({
    super.key,
    this.child,
    this.avatarBadgeStyle,
    super.id,
  }) : super(tag: 'div');

  @override
  final Component? child;

  /// Per-instance composite style — chrome flat fields. See
  /// [CoreAvatarBadgeStyle] for the merge chain.
  @override
  final CoreAvatarBadgeStyle? avatarBadgeStyle;

  @override
  AvatarBadge copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Component? child,
    CoreAvatarBadgeStyle? avatarBadgeStyle,
  }) {
    return AvatarBadge(
      key: key ?? this.key,
      avatarBadgeStyle: avatarBadgeStyle ?? this.avatarBadgeStyle,
      id: id ?? this.id,
      child: child ?? this.child,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveAvatarBadge(
      context,
      inheritedStyle: AvatarBadgeScope.maybeOf(context),
      avatarBadgeStyle: avatarBadgeStyle,
    );

    final badgeChildren = child != null ? [child!] : <Component>[];

    return div(
      badgeChildren,
      id: id,
      classes: [resolved.root.className, ?classes].join(' ').trim(),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: componentAttributes,
      events: events,
    );
  }
}

/// Chain sugar mirroring the Flutter `AvatarBadge.withStyle` extension —
/// merges a [CoreAvatarBadgeStyle] patch into [AvatarBadge.avatarBadgeStyle]
/// via the existing [AvatarBadge.copyWith].
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

/// Displays multiple [Avatar] components in an overlapping layout.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [avatarGroupStyle] (a [CoreAvatarGroupStyle]).
class AvatarGroup extends UiComponent
    implements CoreAvatarGroupContract<Avatar> {
  /// Creates a [AvatarGroup] stacked to the left (default).
  AvatarGroup({
    required this.children,
    super.key,
    this.direction = CoreAvatarGroupDirection.toLeft,
    this.max,
    this.avatarGroupStyle,
    super.id,
  }) : super(tag: 'div');

  /// Creates a [AvatarGroup] stacked to the left.
  AvatarGroup.toLeft({
    required this.children,
    super.key,
    this.max,
    this.avatarGroupStyle,
    super.id,
  }) : direction = CoreAvatarGroupDirection.toLeft,
       super(tag: 'div');

  /// Creates a [AvatarGroup] stacked to the right.
  AvatarGroup.toRight({
    required this.children,
    super.key,
    this.max,
    this.avatarGroupStyle,
    super.id,
  }) : direction = CoreAvatarGroupDirection.toRight,
       super(tag: 'div');

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

  @override
  AvatarGroup copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<Avatar>? children,
    CoreAvatarGroupDirection? direction,
    int? max,
    CoreAvatarGroupStyle? avatarGroupStyle,
  }) {
    return AvatarGroup(
      key: key ?? this.key,
      direction: direction ?? this.direction,
      max: max ?? this.max,
      avatarGroupStyle: avatarGroupStyle ?? this.avatarGroupStyle,
      id: id ?? this.id,
      children: children ?? this.children,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveAvatarGroup(
      context,
      direction: direction,
      avatarGroupStyle: avatarGroupStyle,
    );

    // The first child sits where it is; every later one carries the
    // overlap that pulls it back over its predecessor.
    Component decorate(Avatar child, {required bool following}) {
      final chrome = following ? resolved.followingItem : resolved.item;
      final itemStyles = chrome.inlineStyles;
      // Apply both class and inline override (if any) without losing
      // existing user-supplied classes / styles.
      final decorated = child.copyWith(
        classes: [
          child.classes,
          chrome.className,
        ].where((c) => c != null && c.isNotEmpty).join(' '),
      );
      if (itemStyles == null) return decorated;
      return decorated.copyWith(
        css: Styles.combine([?decorated.css, itemStyles]),
      );
    }

    final visible = max != null && max! < children.length
        ? children.sublist(0, max)
        : children;
    final remaining = max != null && max! < children.length
        ? children.length - max!
        : 0;

    final wrappedChildren = <Component>[
      for (var i = 0; i < visible.length; i++)
        decorate(visible[i], following: i > 0),
      if (remaining > 0)
        decorate(
          Avatar(
            initials: '+$remaining',
            size: visible.first.size,
          ),
          following: visible.isNotEmpty,
        ),
    ];

    final containerOverride = resolved.root.inlineStyles;

    return div(
      wrappedChildren,
      id: id,
      classes: resolved.root.className,
      styles: containerOverride == null
          ? this.css
          : Styles.combine([?this.css, containerOverride]),
      attributes: componentAttributes,
    );
  }
}

/// Chain sugar mirroring the Flutter `AvatarGroup.withStyle` extension —
/// merges a [CoreAvatarGroupStyle] patch into [AvatarGroup.avatarGroupStyle]
/// via the existing [AvatarGroup.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreAvatarGroupStyle.merge` right-side-wins semantics).
extension AvatarGroupStyleChain on AvatarGroup {
  /// Returns a copy of this [AvatarGroup] with [patch] merged into
  /// [avatarGroupStyle] (patch fields win on conflict).
  AvatarGroup withStyle(CoreAvatarGroupStyle patch) => copyWith(
    avatarGroupStyle: (avatarGroupStyle ?? const CoreAvatarGroupStyle()).merge(
      patch,
    ),
  );
}

/// Hands the badge in an [Avatar]'s `badge` slot its step's style.
///
/// An [AvatarBadge] below lays its own `avatarBadgeStyle` over this one, so
/// the avatar sets the default size and a size the badge states wins.
/// Named and shaped like the Flutter counterpart so the two platforms read
/// the same. Pure metadata — emits no DOM of its own.
///
/// Not exported from the package — the avatar mounts it around its own
/// badge slot.
class AvatarBadgeScope extends InheritedComponent {
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
      context.dependOnInheritedComponentOfExactType<AvatarBadgeScope>()?.style;

  @override
  bool updateShouldNotify(AvatarBadgeScope oldComponent) =>
      style != oldComponent.style;
}
