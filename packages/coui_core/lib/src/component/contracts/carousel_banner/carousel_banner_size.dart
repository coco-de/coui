/// Size axis for `CarouselBanner`.
library;

/// The two sizes a promotional banner strip is drawn at.
///
/// Two, not the shared six-step scale, because this strip is not a control
/// that grows and shrinks with a form around it — it is a full-width band
/// and the choice is which screen it is on. The designer draws exactly
/// these: a phone-width strip and a desktop-width one, and every metric
/// between them moves together (inset, thumbnail, gap, both type roles).
enum CoreCarouselBannerSize {
  /// Phone width — 16 inset, 56 thumbnail, `titleSmall` / `bodySmall`.
  sm,

  /// Desktop width — 20 inset, 72 thumbnail, `titleMedium` / `bodyMedium`.
  md;

  /// The size a `CarouselBanner` takes when the caller states none.
  ///
  /// `sm`, because a banner that is too small on a wide screen still reads;
  /// one that is too large on a phone pushes the content it sits above off
  /// the fold.
  static const CoreCarouselBannerSize defaultSize = sm;
}
