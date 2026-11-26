/// Which device a `MockupDevice` draws.
///
/// The axis keys `CoreMockupDeviceStyle.defaultsByDevice` /
/// `CoreMockupDeviceTheme.deviceStyles` — the same idiom a variant enum
/// follows. It is a device *kind*; which way that hardware is held is
/// `CoreMockupOrientation`, a second axis that carries a decision of its
/// own — a turned body moves every button one edge along, which the
/// screen aspect cannot say.
enum CoreMockupDevice {
  /// A phone — tall screen, pill camera, paired volume buttons.
  phone,

  /// A tablet — squarer screen, round camera, single volume rocker.
  tablet;

  /// Widget default device. Flutter / Web `MockupDevice` reference this
  /// single source so neither platform silently diverges.
  static const CoreMockupDevice defaultDevice = phone;
}
