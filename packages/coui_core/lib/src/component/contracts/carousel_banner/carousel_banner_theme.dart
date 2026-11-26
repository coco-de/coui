/// Project-level theme slot for `CarouselBanner`.
library;

import 'package:coui_core/src/component/contracts/carousel_banner/carousel_banner_style.dart';
import 'package:meta/meta.dart';

/// Project-wide `CarouselBanner` chrome override.
///
/// One slot, not a per-size map: the two sizes differ only in the metrics
/// [CoreCarouselBannerStyle.defaultsBySize] already states, and a project
/// that wants a different tint or corner wants it at both sizes.
@immutable
class CoreCarouselBannerTheme {
  /// Creates a [CoreCarouselBannerTheme].
  const CoreCarouselBannerTheme({this.style});

  /// Chrome applied to every `CarouselBanner`, under each instance's own
  /// `carouselBannerStyle`.
  final CoreCarouselBannerStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCarouselBannerTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
