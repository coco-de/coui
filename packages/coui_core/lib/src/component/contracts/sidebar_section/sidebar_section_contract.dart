/// Cross-platform contract for `SidebarSection`.
library;

import 'package:coui_core/src/component/contracts/sidebar_section/sidebar_section_style.dart';

/// A quiet heading above a run of sidebar rows, with an optional action
/// glyph at its far end.
///
/// A heading, not a destination: it takes no focus of its own. A caller
/// that gives [action] a pressable widget makes that widget focusable.
abstract interface class CoreSidebarSectionContract<W> {
  /// The heading — normally a `Text`.
  W get label;

  /// A glyph or control at the heading's end (an add or a more glyph).
  W? get action;

  /// Per-instance chrome. See [CoreSidebarSectionStyle] for the merge
  /// chain.
  CoreSidebarSectionStyle? get sidebarSectionStyle;
}
