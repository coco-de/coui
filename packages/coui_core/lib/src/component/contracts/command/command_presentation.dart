/// The shape a `Command` palette takes — how it is drawn, not where it is
/// mounted.
library;

/// How a `Command` palette presents itself.
///
/// A presentation decides chrome and bounds only: radius, border, shadow,
/// list inset, width floor / ceiling, list scroll ceiling. It does **not**
/// decide scrim, modality or routing — a `dialog` palette is placed inside
/// `Dialog` by the caller (which owns the scrim), a `fullscreen` one is
/// pushed as a route by the caller. The component owns "how it looks"; the
/// consumer owns "when to pick which", usually by breakpoint: below `md`
/// fullscreen, above `lg` dialog, embedded in a page inline.
///
/// Named by shape rather than by device on purpose. A desktop app's narrow
/// side panel is `inline`, and a tablet may deliberately use `fullscreen`;
/// names like `mobile` / `desktop` would be wrong the first time either
/// happened.
enum CoreCommandPresentation {
  /// Embedded in a page. Parent width (floor 240), outline border, no
  /// shadow, list scrolls at 320, footer hidden by default.
  inline,

  /// Floating over content, inside a `Dialog`. Max width 640, radius 20,
  /// large shadow, list scrolls at 400, footer shown by default.
  dialog,

  /// Fills the viewport. No radius, no border, no shadow, list takes the
  /// remaining height, footer hidden (the soft keyboard takes that room), a
  /// back affordance in the header.
  fullscreen;

  /// The shape a bare `Command()` takes — embedded in a page.
  static const CoreCommandPresentation defaultPresentation = inline;
}
