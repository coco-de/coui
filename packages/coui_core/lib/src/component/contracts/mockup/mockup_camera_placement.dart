/// Where a `MockupDevice`'s camera assembly sits.
///
/// A fact about the hardware, so it is stated per device in
/// `CoreMockupDeviceStyle.defaultsByDevice` and read by the one rule set that
/// derives the geometry (`CoreMockupDeviceLayout`) — never branched on a
/// device name in a resolver or a builder.
enum CoreMockupCameraPlacement {
  /// Cut out of the screen itself: a pill resting against the screen's top
  /// edge, centred. Turned a quarter turn counter-clockwise with the device,
  /// it rests against the screen's leading (left) edge instead — the
  /// assembly is part of the screen's content area, so it reserves a safe
  /// area.
  screen,

  /// Set into the bezel strip above the screen, centred on that strip in
  /// both orientations. The screen underneath is uninterrupted, so the
  /// assembly reserves nothing.
  bezel,
}
