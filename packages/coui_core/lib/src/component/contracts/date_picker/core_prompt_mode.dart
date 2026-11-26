/// How a form-level overlay (date picker, time picker, item picker,
/// object input, …) presents its picker UI.
///
/// `popover` anchors a floating panel under the trigger; `dialog`
/// pushes a centred modal. The choice is a hard render-shape decision
/// — it does not change with viewport size or platform — so callers
/// pass it explicitly per-instance instead of letting an ambient
/// `mobileMode` / `useSheetOverlay` flag swap it implicitly.
///
/// Mirrored 1:1 by Flutter's `PromptMode` (legacy form overlays) and
/// referenced by both Flutter / Web unified components so the contract
/// can carry the same enum value across platforms.
enum CorePromptMode {
  /// Anchored popover — calendar / list opens under the trigger,
  /// dismissed by outside-click or selection.
  popover,

  /// Centred modal dialog with `Cancel` / `Save` actions — the
  /// picker commits its pending value only when the user confirms.
  dialog,
}
