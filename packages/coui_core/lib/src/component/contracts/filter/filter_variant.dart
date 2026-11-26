/// Filter-specific visual variants.
///
/// `Filter` is a segmented filter control. It currently exposes a
/// single visual treatment, but the enum is kept so the widget default
/// has one canonical reference point (avoiding silent Flutter / Web
/// divergence) and so future variants can be added without a breaking
/// constructor change.
enum CoreFilterVariant {
  /// Default segmented control — filled container with selectable items.
  segmented;

  /// Widget default variant. Both Flutter and Web `Filter` constructors
  /// reference this value so the default cannot diverge across platforms.
  static const CoreFilterVariant defaultVariant = segmented;
}
