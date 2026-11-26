/// Cross-platform contract for `SidebarRailItem`.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/sidebar_rail_item/sidebar_rail_item_style.dart';

/// One destination in a sidebar's icon rail — a glyph alone in a square.
///
/// It has no visible label, so [label] is required: it is the accessible
/// name and the tooltip.
abstract interface class CoreSidebarRailItemContract<W> {
  /// The glyph.
  W get icon;

  /// The destination's name — its accessible name and its tooltip.
  String get label;

  /// Whether an unread dot shows at the square's top-end corner.
  bool get dot;

  /// Whether this destination is the current place. A disabled
  /// destination is never selected.
  bool get selected;

  /// Whether the destination can be activated. `null` → enabled exactly
  /// when [onPressed] is set.
  bool? get enabled;

  /// Called when the destination is activated.
  CoreVoidCallback? get onPressed;

  /// Per-instance chrome. See [CoreSidebarRailItemStyle] for the merge
  /// chain.
  CoreSidebarRailItemStyle? get sidebarRailItemStyle;
}
