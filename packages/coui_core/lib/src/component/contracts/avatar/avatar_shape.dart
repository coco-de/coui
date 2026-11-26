import 'package:coui_core/src/component/contracts/avatar/avatar_style.dart';

/// The outline an `Avatar` is drawn in — a disc or a rounded tile.
///
/// A person is a disc. An organisation, a workspace or an app is a rounded
/// tile: the same initials or picture, set in a square whose corners are
/// rounded rather than gone. Both are the same component — the tile is not
/// a second part, it is this axis.
///
/// The corner is never computed from the diameter on either platform: each
/// row of [CoreAvatarStyle.defaultsBySize] states the rounded tile's corner
/// for its step, and [CoreAvatarStyle.defaultsByShape] lays the pill over
/// it for [circle]. A corner a caller states
/// (`avatarStyle.borderRadius`) wins over both shapes.
enum CoreAvatarShape {
  /// A disc — the pill corner on a square box. The default.
  circle,

  /// A rounded tile — a quarter of the step's diameter, stated per step in
  /// [CoreAvatarStyle.defaultsBySize] (24 → 6, 32 → 8, 40 → 10, 48 → 12,
  /// 64 → 16, 96 → 24).
  rounded;

  /// Widget default shape — the Flutter / Web `Avatar` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreAvatarShape defaultShape = circle;
}
