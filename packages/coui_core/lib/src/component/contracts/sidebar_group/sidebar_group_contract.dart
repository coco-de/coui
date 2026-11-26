/// Cross-platform contract for `SidebarGroup`.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/sidebar_group/sidebar_group_style.dart';

/// A sidebar row that folds a run of nested rows under it.
///
/// The group draws its own row — a `SidebarItem` with [leading] and
/// [label] and a chevron at its end — and below it, while open, the
/// [children] indented behind a thin line. Activating the row opens or
/// closes the group (`aria-expanded` on Web).
///
/// Open state is the caller's when [expanded] is set (controlled) and the
/// group's own otherwise, starting at [initiallyExpanded].
abstract interface class CoreSidebarGroupContract<W> {
  /// Widget default for [initiallyExpanded] — the Flutter / Web
  /// `SidebarGroup` constructors reference this.
  static const bool defaultInitiallyExpanded = true;

  /// The group's name — normally a `Text`.
  W get label;

  /// The glyph before the name.
  W? get leading;

  /// The nested rows — normally `SidebarItem`s at the nested level.
  List<W> get children;

  /// Whether the group is open. `null` → the group keeps its own state.
  bool? get expanded;

  /// Whether an uncontrolled group starts open.
  bool get initiallyExpanded;

  /// Called with the new open state when the row is activated.
  CoreValueChanged<bool>? get onExpandedChanged;

  /// Per-instance chrome. See [CoreSidebarGroupStyle] for the merge chain.
  CoreSidebarGroupStyle? get sidebarGroupStyle;
}
