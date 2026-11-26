import 'package:coui_core/src/component/contracts/sidebar_header/sidebar_header_style.dart';

/// How a `SidebarHeader` sits on the sidebar.
///
/// Each variant's face and line live in
/// [CoreSidebarHeaderStyle.defaultsByVariant].
enum CoreSidebarHeaderVariant {
  /// On the sidebar's own face, no line. The default.
  plain,

  /// On a bordered `surface` tile — the person's own row at the bottom.
  card;

  /// Widget default variant — the Flutter / Web `SidebarHeader`
  /// constructors reference this so the default cannot silently diverge.
  static const CoreSidebarHeaderVariant defaultVariant = plain;
}
