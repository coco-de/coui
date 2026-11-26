/// Thumb visibility mode for a unified scrollbar component.
library;

/// Controls how prominent the scrollbar thumb is.
///
/// On Flutter this drives `RawScrollbar.thumbVisibility` plus the
/// resolved thumb thickness; on Web it maps to the `scrollbar-*`
/// utility classes (`scrollbar-thin` / `scrollbar-none`).
enum CoreScrollbarVisibility {
  /// Thumb fades in while scrolling and fades out afterwards
  /// (overlay scrollbar). Flutter `thumbVisibility: false`,
  /// Web default `overflow: auto` scrollbar.
  auto,

  /// Thumb is always visible at the full resolved thickness.
  /// Flutter `thumbVisibility: true`.
  always,

  /// Thin thumb. Flutter halves the resolved thickness; Web emits
  /// `scrollbar-thin`.
  thin,

  /// Thumb is hidden but the area still scrolls. Flutter omits the
  /// painted thumb; Web emits `scrollbar-none`.
  ///
  /// Hides pixels only. The accessibility node that reports scroll
  /// position survives on both platforms — this is the one mode where a
  /// sighted user has no position cue at all, so it is the last mode
  /// that should take the non-visual one away too. That node renders
  /// nothing in any mode (`sr-only` on Web, a zero-paint `Semantics`
  /// sibling on Flutter), so it was never part of what `hidden` hides.
  hidden;

  /// Default visibility for `Scrollbar` — both Flutter and Web
  /// constructors reference this so the platforms cannot diverge.
  static const CoreScrollbarVisibility defaultVisibility = auto;
}
