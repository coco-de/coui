/// Cross-platform contract for `SidebarSearch`.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/sidebar_search/sidebar_search_style.dart';

/// A field-shaped trigger for the app's search, at the top of a sidebar —
/// a search glyph, a placeholder, and the shortcut that opens the same
/// search from anywhere.
///
/// It is a button, not an input: pressing it hands off to the search
/// surface the app owns (a command palette, a search page). The
/// placeholder is its accessible name.
abstract interface class CoreSidebarSearchContract<W> {
  /// The text the trigger shows, and its accessible name.
  String get placeholder;

  /// The keys of the shortcut, drawn as a composed `Kbd` (`['⌘', 'K']`).
  /// `null` or empty draws none.
  List<String>? get shortcut;

  /// Called when the trigger is activated. `null` → disabled.
  CoreVoidCallback? get onPressed;

  /// Per-instance chrome. See [CoreSidebarSearchStyle] for the merge chain.
  CoreSidebarSearchStyle? get sidebarSearchStyle;
}
