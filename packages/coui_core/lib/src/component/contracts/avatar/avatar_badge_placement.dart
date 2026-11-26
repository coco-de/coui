import 'package:coui_core/src/component/contracts/avatar/avatar_style.dart';

/// How an `Avatar` places its badge against the corner
/// [CoreAvatarStyle.badgeAlignment] names.
///
/// The badge marks the avatar's outline, so where it sits follows the
/// outline: a rounded tile has a corner to tuck the badge into, a disc has
/// none — its corner is empty space, and a badge in it floats off the edge.
/// [CoreAvatarStyle.defaultsByShape] picks one per shape; a placement
/// stated on the theme or the instance wins over both.
///
/// Both platforms place the badge through
/// [CoreAvatarStyle.badgeAnchorFor], so the geometry is stated once.
enum CoreAvatarBadgePlacement {
  /// The badge's box sits inside the box corner, its edges
  /// [CoreAvatarStyle.badgeInset] in from the avatar's edges — a rounded
  /// tile's badge, flush in its corner at the default inset of 0.
  corner,

  /// The badge's centre sits on the disc's outline, in the direction of
  /// the alignment — 45° up and out for the top-end corner — and
  /// [CoreAvatarStyle.badgeInset] in from it toward the centre. A disc's
  /// badge.
  outline;

  /// The placement a style that states none takes.
  static const CoreAvatarBadgePlacement defaultPlacement = corner;
}
