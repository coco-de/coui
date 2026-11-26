/// Five-step size scale for `CoreDockContract`.
///
/// Controls the dock bar's minimum height (and indirectly icon/label sizing).
/// Mirrors the five steps used by legacy Flutter `Dock` and Web DaisyUI
/// `dock-*` modifiers so values can be shared cross-platform without
/// importing the Flutter SDK.
library;

/// Size preset for `Dock`.
enum CoreDockSize {
  /// Extra small. Compact bar; labels hidden by default.
  xs,

  /// Small.
  sm,

  /// Medium. Default.
  md,

  /// Large.
  lg,

  /// Extra large.
  xl,
}
