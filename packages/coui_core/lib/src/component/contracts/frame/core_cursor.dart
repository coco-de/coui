/// Mouse cursor style for `CoreFrameContract`.
///
/// Maps to:
/// - Flutter: `MouseRegion(cursor: SystemMouseCursors.X)`.
/// - Web: CSS `cursor: <kind>`.
///
/// Only the values used by the design system are listed; any rare
/// case (`grabbing`, `wait`, `crosshair`, etc.) can be added later.
enum CoreCursor {
  /// Standard arrow.
  basic,

  /// Pointer (hand) — typically for clickable elements.
  pointer,

  /// Text I-beam — for editable / selectable text.
  text,

  /// Open-hand — for draggable elements.
  grab,

  /// Closed-hand — while dragging.
  grabbing,

  /// "Not allowed" — for disabled clickable elements.
  forbidden,

  /// Resize column (horizontal arrows).
  resizeColumn,

  /// Resize row (vertical arrows).
  resizeRow,
}
