/// Variant enum for unified swiper components.
library;

/// The presentation style of a swiper overlay.
///
/// Mirrors the legacy `SwiperHandler` drawer / sheet split — the
/// drawer style carries panel chrome (shadow, surface fill) while the
/// sheet style is intentionally minimal.
enum CoreSwiperVariant {
  /// Drawer-style overlay — elevated panel with shadow chrome.
  drawer,

  /// Sheet-style overlay — minimal decoration, edge-to-edge content.
  sheet;

  /// Widget default variant. The Flutter / Web `Swiper` constructor
  /// default references this value so the two platforms cannot
  /// silently diverge.
  static const CoreSwiperVariant defaultVariant = drawer;
}
