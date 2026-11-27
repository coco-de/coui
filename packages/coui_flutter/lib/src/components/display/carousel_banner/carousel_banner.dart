/// A promotional strip for a `Carousel(variant: .banner)` slide.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/display/carousel_banner/carousel_banner_style.dart';
import 'package:coui_flutter/src/components/icon/icon.dart';
import 'package:coui_flutter/src/components/infra/clickable/clickable.dart';
import 'package:coui_flutter/src/components/layout/gap/gap.dart';
import 'package:flutter/widgets.dart' hide Icon;

/// One promotional strip: a thumbnail beside a title and a supporting line.
///
/// Goes in `Carousel(variant: .banner, items: [...])`. It is its own
/// component rather than a carousel mode because its content is
/// per-slide — three banners are three of these, each with its own words
/// and picture, and one carousel field could only hold one set.
///
/// ```dart
/// Carousel(
///   variant: .banner,
///   items: [
///     CarouselBanner(
///       thumbnail: Image.asset('promo.png'),
///       title: Text('여름 세일'),
///       description: Text('전 품목 30% 할인'),
///       onTap: openSale,
///     ),
///   ],
/// )
/// ```
class CarouselBanner extends StatelessWidget
    implements CoreCarouselBannerContract<Widget> {
  /// Creates a [CarouselBanner].
  const CarouselBanner({
    super.key,
    this.onTap,
    this.size = CoreCarouselBannerSize.defaultSize,
    this.thumbnail,
    this.title,
    this.description,
    this.carouselBannerStyle,
  });

  @override
  final CoreCarouselBannerSize size;

  @override
  final Widget? thumbnail;

  @override
  final Widget? title;

  @override
  final Widget? description;

  @override
  final void Function()? onTap;

  @override
  final CoreCarouselBannerStyle? carouselBannerStyle;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCarouselBanner(
      context,
      size: size,
      carouselBannerStyle: carouselBannerStyle,
    );

    final strip = DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.backgroundColor,
        borderRadius: resolved.borderRadius,
      ),
      child: Padding(
        padding: resolved.padding,
        child: Row(
          children: [
            if (thumbnail != null) ...[
              // The thumbnail box is square and it is what sets the
              // strip's height — inset + side + inset. The fill behind the
              // caller's picture shows where that picture does not reach
              // (a transparent PNG, a slow network), and the clip keeps a
              // photo inside the corner the strip states.
              //
              // What fills the square depends on what was handed in: a
              // picture takes the box's tight constraints and fills it, an
              // `Icon` is a mark rather than a picture, so it is centred at
              // the icon size the style states (`thumbnailIconTheme`) instead
              // of being stretched to the square.
              SizedBox.square(
                dimension: resolved.thumbnailSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: resolved.thumbnailBackgroundColor,
                    borderRadius: resolved.thumbnailBorderRadius,
                  ),
                  child: ClipRRect(
                    borderRadius: resolved.thumbnailBorderRadius,
                    child: IconTheme.merge(
                      data: resolved.thumbnailIconTheme,
                      child: thumbnail is Icon
                          ? Center(child: thumbnail)
                          : thumbnail!,
                    ),
                  ),
                ),
              ),
              Gap(gapStyle: resolved.thumbnailTextGapStyle),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    DefaultTextStyle.merge(
                      style: resolved.titleTextStyle,
                      child: title!,
                    ),
                  if (title != null && description != null)
                    Gap(gapStyle: resolved.titleDescriptionGapStyle),
                  if (description != null)
                    DefaultTextStyle.merge(
                      style: resolved.descriptionTextStyle,
                      child: description!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return strip;
    // The composed `Clickable` owns tap, keyboard activation, cursor and
    // the focus ring — the same thing `Card` does with its own tap. A
    // hand-rolled `GestureDetector` here would leave the strip unreachable
    // by keyboard while looking correct with a mouse.
    //
    // No `clickableStyle` slot: the strip states no divergence from
    // `Clickable`'s own interaction chrome, and a field nothing states is a
    // field no canvas can draw. If a press-shrink on a full-width band
    // turns out wrong, that is the value to state — and it arrives with the
    // entry that explains why the canvas cannot show it.
    return Clickable(onPressed: onTap, child: strip);
  }
}

/// Chain sugar for merging a [CoreCarouselBannerStyle] patch into
/// [CarouselBanner.carouselBannerStyle] without hand-reconstructing every
/// field. Mirrors the Web extension so both platforms read identically.
extension CarouselBannerStyleChain on CarouselBanner {
  /// Sets the background paint and preserves the other style fields.
  CarouselBanner backgroundColor(CoreColor value) =>
      withStyle(CoreCarouselBannerStyle(backgroundColor: value));

  /// Returns a copy with [patch] merged over the existing chrome slot.
  CarouselBanner withStyle(CoreCarouselBannerStyle patch) => CarouselBanner(
    key: key,
    onTap: onTap,
    size: size,
    thumbnail: thumbnail,
    title: title,
    description: description,
    carouselBannerStyle:
        carouselBannerStyle?.merge(patch) ??
        const CoreCarouselBannerStyle().merge(patch),
  );
}
