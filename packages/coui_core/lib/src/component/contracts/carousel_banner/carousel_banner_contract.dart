/// Cross-platform contract for `CarouselBanner`.
library;

import 'package:coui_core/src/component/contracts/carousel_banner/carousel_banner_size.dart';
import 'package:coui_core/src/component/contracts/carousel_banner/carousel_banner_style.dart';

/// One promotional strip: a thumbnail beside a title and a line of
/// supporting text.
///
/// It exists as its own component rather than as a `Carousel` mode because
/// its content is per-slide — a carousel of three banners is three of
/// these, each with its own words and picture, and a `Carousel` field
/// could only state one. `Carousel(variant: .banner, items: [...])` is
/// where they go, and the carousel states where the dots sit; this states
/// what one slide holds.
///
/// `Card` was the near miss. It carries media, header and body too, but it
/// stacks them vertically — media above the text — and this strip is
/// horizontal, which is not a value either component's fields can bend
/// into the other's shape.
abstract interface class CoreCarouselBannerContract<W> {
  /// Which of the two sizes this strip is drawn at.
  CoreCarouselBannerSize get size;

  /// The picture at the leading edge. `null` draws no thumbnail and the
  /// text column takes the full width.
  W? get thumbnail;

  /// The headline. Usually a `Text`.
  W? get title;

  /// The supporting line under the title. `null` drops the line and the
  /// column holds the title alone.
  W? get description;

  /// Called when the strip is tapped. `null` makes it non-interactive.
  void Function()? get onTap;

  /// Per-instance chrome / dimensional / slot style.
  CoreCarouselBannerStyle? get carouselBannerStyle;
}
