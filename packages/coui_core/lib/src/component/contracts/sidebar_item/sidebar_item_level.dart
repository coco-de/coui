import 'package:coui_core/src/component/contracts/sidebar_item/sidebar_item_style.dart';

/// How deep a `SidebarItem` sits.
///
/// Each level's height and label role live in
/// [CoreSidebarItemStyle.defaultsByLevel].
enum CoreSidebarItemLevel {
  /// A row in the sidebar's own list — 36 tall. The default.
  top,

  /// A row folded under a `SidebarGroup` — 32 tall, one role quieter.
  nested;

  /// Widget default level — the Flutter / Web `SidebarItem` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreSidebarItemLevel defaultLevel = top;
}
