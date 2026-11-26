/// Cross-platform contract for `SidebarHeader`.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/sidebar_header/sidebar_header_style.dart';
import 'package:coui_core/src/component/contracts/sidebar_header/sidebar_header_variant.dart';

/// The identity row of a sidebar — a workspace with its logo at the top,
/// or the signed-in person with their avatar at the foot.
///
/// Anatomy, start to end: `[ leading ] [ title / subtitle … ]
/// [ trailing ]`. With [onPressed] the whole row opens a switcher (a
/// workspace or account menu); without it the row only shows.
abstract interface class CoreSidebarHeaderContract<W> {
  /// How the row sits on the sidebar.
  CoreSidebarHeaderVariant get variant;

  /// The mark before the text — a logo tile or an `Avatar`.
  W? get leading;

  /// The name — normally a `Text`.
  W get title;

  /// The second line (a role, a plan, an email).
  W? get subtitle;

  /// A glyph at the row's end — normally the switch chevron.
  W? get trailing;

  /// Called when the row is activated. `null` → the row is not pressable.
  CoreVoidCallback? get onPressed;

  /// Per-instance chrome. See [CoreSidebarHeaderStyle] for the merge chain.
  CoreSidebarHeaderStyle? get sidebarHeaderStyle;
}
