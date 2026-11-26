/// Variant axis for `Carousel`.
library;

/// What kind of thing a carousel is cycling through.
///
/// Not a chrome choice — it decides where the dots sit and whether the
/// prev / next controls exist, because those two follow from what is being
/// cycled rather than from taste.
enum CoreCarouselVariant {
  /// Arbitrary content, one item at a time, filling the viewport.
  ///
  /// The dots float over the slide (there is nowhere else for them to go
  /// without stealing height from it) and the prev / next controls show,
  /// because a full-bleed slide gives a pointer nothing else to aim at.
  slide,

  /// A thin promotional strip — `CarouselBanner` in `items`.
  ///
  /// The dots sit in flow **under** the strip: a banner is 88 logical px
  /// tall and an overlay row would cover the words it exists to show. The
  /// prev / next controls are off by default for the same reason — two
  /// 32-px discs on an 88-px band leave no strip — so a banner advances by
  /// swipe or by autoplay.
  banner;

  /// The variant a carousel takes when the caller states none — `slide`,
  /// which is what a carousel is without further instruction.
  static const CoreCarouselVariant defaultVariant = slide;
}
