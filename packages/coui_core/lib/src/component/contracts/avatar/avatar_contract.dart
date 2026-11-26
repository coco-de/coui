/// Platform-independent contract for avatar components.
library;

import 'package:coui_core/src/component/contracts/avatar/avatar_badge_style.dart';
import 'package:coui_core/src/component/contracts/avatar/avatar_group_style.dart';
import 'package:coui_core/src/component/contracts/avatar/avatar_shape.dart';
import 'package:coui_core/src/component/contracts/avatar/avatar_style.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for an avatar component.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [avatarStyle] field — see [CoreAvatarStyle] for the
/// merge chain. The semantic enums ([size], [shape]) and behaviour
/// fields stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreAvatarContract<W> {
  /// Widget default size. Flutter / Web `Avatar` constructors reference
  /// this so neither platform diverges silently, and the avatar group
  /// measures its stack from the same size. `sm` (32) — the size most
  /// avatars are drawn at.
  static const CoreComponentSize defaultSize = CoreComponentSize.sm;

  /// Image URL for the avatar.
  String? get imageUrl;

  /// Initials text displayed when no image.
  String? get initials;

  /// The size of the avatar.
  CoreComponentSize get size;

  /// The outline — a disc ([CoreAvatarShape.circle], the default) or a
  /// rounded tile ([CoreAvatarShape.rounded]) for an organisation, a
  /// workspace or an app. The rounded tile's corner is the step's, stated
  /// per size in [CoreAvatarStyle.defaultsBySize]; an
  /// `avatarStyle.borderRadius` wins over both shapes.
  CoreAvatarShape get shape;

  /// Whether to show a ring border.
  bool get ring;

  /// Custom child widget (overrides image/initials).
  W? get child;

  /// Badge widget overlaid on the avatar.
  W? get badge;

  /// Per-instance avatar chrome / dimensional / slot style.
  ///
  /// All visual chrome — including the badge inset (`badgeInset`) and
  /// the badge corner (`badgeAlignment`) — flows through this single
  /// field (the former composite-layout exception is abolished per
  /// verify.md 7-6). Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreAvatarTheme.style
  ///   → parent component slot override
  ///   → widget.avatarStyle
  /// ```
  CoreAvatarStyle? get avatarStyle;
}

/// Contract for an avatar badge component.
///
/// Type parameters:
/// - [W] - platform widget type.
///
/// Renders a small circular indicator overlaid on an avatar.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [avatarBadgeStyle] field — see [CoreAvatarBadgeStyle].
abstract interface class CoreAvatarBadgeContract<W> {
  /// Custom child widget inside the badge.
  W? get child;

  /// Per-instance badge chrome / dimensional style.
  ///
  /// Use `avatarBadgeStyle: CoreAvatarBadgeStyle(backgroundColor: ...,
  /// size: ...)` for the badge fill / size overrides that used to
  /// live on the flat `color` / `size` params (Story #1362 Batch 3 —
  /// Epic #1302 chrome cleanup).
  CoreAvatarBadgeStyle? get avatarBadgeStyle;
}

/// Stacking direction for avatar groups.
enum CoreAvatarGroupDirection {
  /// Stack avatars to the left (default).
  toLeft,

  /// Stack avatars to the right.
  toRight,
}

/// Contract for an avatar group component.
///
/// Type parameters:
/// - [W] - platform widget type.
///
/// Renders multiple avatars in an overlapping layout.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [avatarGroupStyle] field — see [CoreAvatarGroupStyle].
abstract interface class CoreAvatarGroupContract<W> {
  /// Avatar widgets to display.
  List<W> get children;

  /// Stacking direction.
  CoreAvatarGroupDirection get direction;

  /// Maximum number of avatars to show.
  ///
  /// Remaining avatars are represented by a "+N" indicator.
  int? get max;

  /// Per-instance group chrome / dimensional style.
  ///
  /// Use `avatarGroupStyle: CoreAvatarGroupStyle(extraSpacing: ...)` for
  /// the extra paint-time spacing override (paint-time positive offset
  /// added on top of the negative overlap) that used to live on the
  /// flat `gap` param (Story #1362 Batch 3 — Epic #1302 chrome
  /// cleanup). Per the #1659 D-category re-classification the field is
  /// `extraSpacing` (paint-time offset multiplier — distinct from a
  /// structural sibling gap).
  CoreAvatarGroupStyle? get avatarGroupStyle;
}
