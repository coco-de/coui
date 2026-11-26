/// Size axis for `Carousel`.
library;

import 'package:coui_core/src/component/contracts/dot_indicator/dot_indicator_size.dart';

/// The two screens a carousel is drawn for.
///
/// A carousel takes its extent from its parent, so this is not a width —
/// it is which set of interior metrics the parts inside it use. Today that
/// is the indicator dot size; the banner strip inside a `banner` carousel
/// carries its own size for the same reason (`CoreCarouselBannerSize`),
/// and a caller who mixes the two is stating that on purpose.
enum CoreCarouselSize {
  /// Phone — smaller dots, so a row of them does not dominate a narrow
  /// strip.
  sm,

  /// Desktop — the kit's usual dot size.
  md;

  /// The size a carousel takes when the caller states none — `md`, the
  /// dot size every other placement in this kit already draws.
  static const CoreCarouselSize defaultSize = md;

  /// Which `DotIndicator` size this carousel's indicator row draws at.
  ///
  /// Two sizes here, three there: a carousel has no use for the largest
  /// dots. The mapping lives on the enum rather than in each resolver
  /// because both platforms need the same answer and a copy in each is a
  /// copy that can disagree — the same reason `CoreCardElevation` converts
  /// itself rather than being switched over twice.
  CoreDotIndicatorSize toDotIndicatorSize() => switch (this) {
    sm => CoreDotIndicatorSize.sm,
    md => CoreDotIndicatorSize.md,
  };
}
