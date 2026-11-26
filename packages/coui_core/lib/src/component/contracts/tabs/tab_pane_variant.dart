/// Visual / layout variant for the unified `TabPane` component.
library;

/// The visual and layout variant of a `TabPane`.
///
/// - [boxed] renders the default settings-card look: a content panel
///   fused to the tab strip with a T-junction outline (the historic
///   `TabPane` reading).
/// - [editorStrip] renders IDE editor chrome: the strip alone. The
///   content panel is **not** part of the contract in this variant —
///   callers own the editor body beside / below the strip. Outer card
///   chrome and the T-junction overlap are off; style chrome comes from
///   [CoreTabPaneStyle.defaultsByVariant] (a 40 px strip whose chips fill
///   its height, `tabSpacing: 0` with no rule between tabs, flat strip band,
///   flush corners, a bottom line under the strip that the selected tab's
///   face covers — `borderWidth` drawn in `borderColor` — a tab focus
///   ring drawn inside the tab's box so the scrolling strip does not clip
///   it, a `primary` indicator bar along the inside of the selected tab's
///   top edge — `indicatorColor` at `indicatorWidth`, paint only, no layout
///   height — and a 24×24 close box with a 12 px `onSurfaceSubtle`
///   glyph, fixed through hover, on a tab that carries `CoreTabItem.onClose`).
///
/// The semantic enum lives on the widget, not on
/// [CoreTabPaneStyle] (`core/style-contract.md`).
enum CoreTabPaneVariant {
  /// Boxed settings card — tab strip fused onto an integrated content
  /// panel (default).
  boxed,

  /// IDE editor chrome — strip only; `CoreTabItem.content` is not
  /// rendered.
  editorStrip;

  /// Widget default variant. Flutter / Web `TabPane` constructors
  /// reference this so a single change cannot silently diverge.
  static const CoreTabPaneVariant defaultVariant = boxed;
}
