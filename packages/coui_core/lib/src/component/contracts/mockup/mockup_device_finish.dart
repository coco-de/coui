/// How a `MockupDevice` is finished — a picture of hardware, or a frame.
///
/// The axis keys `CoreMockupDeviceStyle.defaultsByFinish` and
/// `CoreMockupDeviceTheme.finishStyles`. It is orthogonal to
/// `CoreMockupDevice` (which hardware) and `CoreMockupOrientation` (which way
/// it is held): the same contract — child, device, orientation, width — draws
/// either way, and only the look differs.
enum CoreMockupDeviceFinish {
  /// A picture of the device: gradient rail, rim light, hardware buttons,
  /// antenna bands, camera, status bar and home bar.
  realistic,

  /// A preview frame rather than a device picture: one plain ring around the
  /// screen and nothing else — no rail, buttons, antenna bands, rim light or
  /// lens, no shadow, and no camera, status bar or home bar unless asked for.
  flat;

  /// Widget default finish. Flutter / Web `MockupDevice` reference this
  /// single source so neither platform silently diverges.
  static const CoreMockupDeviceFinish defaultFinish = realistic;
}
