/// Cross-platform contract for `SidebarItem`.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/sidebar_item/sidebar_item_level.dart';
import 'package:coui_core/src/component/contracts/sidebar_item/sidebar_item_style.dart';

/// One destination in a sidebar — a glyph, a name, and at its far end an
/// optional unread dot, a count and a trailing glyph.
///
/// The current place draws a raised face and a heavier label, and states
/// itself to assistive technology (`aria-current="page"` on Web).
///
/// Anatomy, start to end: `[ leading ] [ label … ] [ dot ] [ count ]
/// [ trailing ]`.
abstract interface class CoreSidebarItemContract<W> {
  /// The destination's name — normally a `Text`.
  W get label;

  /// The glyph before the label.
  W? get leading;

  /// A count shown at the row's end — normally a `Badge`.
  W? get count;

  /// A glyph at the row's very end (a chevron, an external-link mark).
  W? get trailing;

  /// Whether an unread dot shows before the count.
  bool get dot;

  /// How deep the row sits.
  CoreSidebarItemLevel get level;

  /// Whether this row is the current place. A disabled row is never
  /// selected — disabled outranks selection.
  bool get selected;

  /// Whether the row can be activated. `null` → enabled exactly when
  /// [onPressed] is set (`enabled ?? onPressed != null`).
  bool? get enabled;

  /// Called when the row is activated — a click, a tap, or Enter / Space
  /// while it holds focus.
  CoreVoidCallback? get onPressed;

  /// Per-instance chrome. See [CoreSidebarItemStyle] for the merge chain.
  CoreSidebarItemStyle? get sidebarItemStyle;
}
