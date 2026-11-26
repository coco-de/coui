/// Cross-platform contract for `Sidebar`.
library;

import 'package:coui_core/src/component/contracts/sidebar/sidebar_style.dart';
import 'package:coui_core/src/component/contracts/sidebar/sidebar_type.dart';

/// An app's side navigation — a fixed-width column at the reading start
/// of the screen that holds the app's identity, a search trigger, the
/// navigation rows, and at its foot the person and help.
///
/// The sidebar frames regions; it draws no row of its own. The rows are
/// caller-composed `SidebarItem` / `SidebarSection` / `SidebarGroup`, the
/// rail destinations `SidebarRailItem`, so every part keeps its own style.
///
/// Anatomy by [type]:
///
/// ```text
/// standard    panel  top    header · search
///                    body   children
///                    bottom footer · help · user
/// twoPane     rail   railHeader · railItems · railFooter
///             panel  top    panelTitle · panelAction · search
///                    body   children
///                    bottom footer · help · user
/// collapsed   rail   railHeader · railItems · railFooter
/// ```
///
/// A long body scrolls; the top and bottom regions stay put.
abstract interface class CoreSidebarContract<W> {
  /// Which shape the sidebar takes.
  CoreSidebarType get type;

  /// The identity at the top of the panel — normally a `SidebarHeader`.
  W? get header;

  /// The search trigger under the header — normally a `SidebarSearch`.
  W? get search;

  /// The two-pane panel's title — the name of the rail's current area.
  W? get panelTitle;

  /// An action at the end of the panel title row (a new-item glyph).
  W? get panelAction;

  /// The panel's rows, top to bottom.
  List<W> get children;

  /// Content above help and the person at the foot of the panel — a usage
  /// card, an upgrade prompt. The sidebar gives it room; it draws nothing
  /// of its own.
  W? get footer;

  /// The help row at the foot of the panel — normally a `SidebarItem`.
  W? get help;

  /// The signed-in person at the very foot — normally a `SidebarHeader`.
  W? get user;

  /// The rail's mark above its destinations (a logo tile).
  W? get railHeader;

  /// The rail's destinations, top to bottom — normally `SidebarRailItem`s.
  List<W> get railItems;

  /// What sits at the rail's foot (settings, the person's avatar).
  W? get railFooter;

  /// The navigation landmark's accessible name. `null` names none.
  String? get semanticLabel;

  /// Per-instance chrome. See [CoreSidebarStyle] for the merge chain.
  CoreSidebarStyle? get sidebarStyle;
}
