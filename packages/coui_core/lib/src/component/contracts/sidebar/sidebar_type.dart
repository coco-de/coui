import 'package:coui_core/src/component/contracts/sidebar/sidebar_style.dart';

/// The three shapes a `Sidebar` comes in.
///
/// Each type's widths, insets and rail face live in
/// [CoreSidebarStyle.defaultsByType].
enum CoreSidebarType {
  /// One panel — header, search, the rows, and the bottom region. The
  /// default.
  standard,

  /// An icon rail beside a panel: the rail switches between areas, the
  /// panel lists the current area's rows under its own title.
  twoPane,

  /// The icon rail alone — the panel folded away.
  collapsed;

  /// Widget default type — the Flutter / Web `Sidebar` constructors
  /// reference this so the default cannot silently diverge.
  static const CoreSidebarType defaultType = standard;

  /// Whether this type draws the icon rail.
  bool get hasRail => this != standard;

  /// Whether this type draws the panel.
  bool get hasPanel => this != collapsed;
}
