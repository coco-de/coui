/// Single-entry resolver for `CarouselBanner` (Flutter).
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/theme/theme.dart';
import 'package:coui_flutter/src/util/core_to_flutter.dart';
import 'package:flutter/widgets.dart';

/// Paint-ready chrome for Flutter `CarouselBanner`.
///
/// Widget tree:
///
/// ```text
/// DecoratedBox (backgroundColor + borderRadius)
///   └─ Padding (padding)
///        └─ Row
///             ├─ thumbnail box (thumbnailSize, thumbnailBorderRadius,
///             │                 thumbnailBackgroundColor)   // * with thumbnail
///             │    └─ IconTheme (thumbnailIconTheme)        // an `Icon` is centred at
///             │                                             // its size; a picture fills
///             ├─ Gap(thumbnailTextGapStyle)                 // * with thumbnail
///             └─ Expanded > Column
///                  ├─ title        (titleTextStyle)
///                  ├─ Gap(titleDescriptionGapStyle)         // * with description
///                  └─ description  (descriptionTextStyle)   // * Show description
/// ```
///
/// `carousel_banner.dart` reads these straight — no merge, no fallback,
/// no token lookup in the widget body.
@immutable
class ResolvedCarouselBanner {
  /// Creates a [ResolvedCarouselBanner].
  const ResolvedCarouselBanner({
    required this.backgroundColor,
    required this.borderRadius,
    required this.padding,
    required this.thumbnailSize,
    required this.thumbnailBorderRadius,
    required this.thumbnailBackgroundColor,
    required this.thumbnailIconTheme,
    required this.thumbnailTextGapStyle,
    required this.titleDescriptionGapStyle,
    required this.titleTextStyle,
    required this.descriptionTextStyle,
  });

  /// Resolved strip fill.
  final Color backgroundColor;

  /// Effective strip corner.
  final BorderRadius borderRadius;

  /// Effective strip inset (already scaled).
  final EdgeInsets padding;

  /// Effective thumbnail side length (already scaled).
  final double thumbnailSize;

  /// Effective thumbnail corner.
  final BorderRadius thumbnailBorderRadius;

  /// Resolved thumbnail placeholder fill — what shows where a caller's
  /// picture does not reach.
  final Color thumbnailBackgroundColor;

  /// Ambient icon theme for an `Icon` handed to the thumbnail — the size
  /// and colour of [CoreCarouselBannerStyle.thumbnailIconStyle]. The size is
  /// the token size (`Icon` multiplies its own box by the scaling), and an
  /// `Icon` that states its own size or colour keeps it. The widget centres
  /// the glyph in the square; anything that is not an `Icon` fills it.
  final IconThemeData thumbnailIconTheme;

  /// Thumbnail → text spacer, raw-forwarded so `Gap` scales it itself.
  final CoreGapStyle thumbnailTextGapStyle;

  /// Title → description spacer, raw-forwarded on the same terms.
  final CoreGapStyle titleDescriptionGapStyle;

  /// Paint-ready title typography.
  final TextStyle titleTextStyle;

  /// Paint-ready description typography.
  final TextStyle descriptionTextStyle;
}

/// Resolves `CarouselBanner` chrome for [size], merging the theme slot
/// under the per-instance [carouselBannerStyle].
ResolvedCarouselBanner resolveCarouselBanner(
  BuildContext context, {
  CoreCarouselBannerSize size = CoreCarouselBannerSize.defaultSize,
  CoreCarouselBannerStyle? carouselBannerStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final colorScheme = theme.colorScheme;
  final bannerTheme = theme.coreComponentTheme?.carouselBanner;

  // ─── Stage 1 RESOLVE ──────────────────────────────────
  final merged = resolveStyleChain(const CoreCarouselBannerStyle(), [
    bannerTheme?.style,
    carouselBannerStyle,
  ]);
  // The size row under everything the caller and the project stated: the
  // size metrics move together, so the table is the base rather than
  // separate fallback rungs for each field.
  final sized = CoreCarouselBannerStyle.defaultsBySize[size]!.merge(merged);

  // Read from `merged`, not from `sized`: these four are the same at both
  // sizes, so the size row states none of them and reading the row would
  // hide which chain the value came off.
  final backgroundColorCore =
      merged.backgroundColor ?? CoreCarouselBannerStyle.defaultBackgroundColor;
  final borderRadiusCore =
      merged.borderRadius ?? CoreCarouselBannerStyle.defaultBorderRadius;
  final thumbnailBorderRadiusCore =
      merged.thumbnailBorderRadius ??
      CoreCarouselBannerStyle.defaultThumbnailBorderRadius;
  final thumbnailBackgroundColorCore =
      merged.thumbnailBackgroundColor ??
      CoreCarouselBannerStyle.defaultThumbnailBackgroundColor;

  // ─── Stage 2 EMIT ─────────────────────────────────────
  final backgroundColor = colorScheme.resolve(backgroundColorCore).toValue();
  final thumbnailBackgroundColor = colorScheme
      .resolve(thumbnailBackgroundColorCore)
      .toValue();
  final borderRadius = borderRadiusCore.toValue(geometry: theme.geometry);
  final thumbnailBorderRadius = thumbnailBorderRadiusCore.toValue(
    geometry: theme.geometry,
  );
  final thumbnailIconStyle = sized.thumbnailIconStyle!;
  // Token size — `Icon` multiplies its box by the scaling itself, so a size
  // pre-multiplied here would be scaled twice (and the stroke rule would
  // read the multiplied size).
  final thumbnailIconTheme = IconThemeData(
    size: thumbnailIconStyle.size,
    color: colorScheme.resolve(thumbnailIconStyle.color!).toValue(),
  );
  final padding = sized.padding!.toValue(geometry: theme.geometry) * scaling;
  final thumbnailSize = sized.thumbnailSize! * scaling;
  final titleTextStyle = sized.titleStyle!.toValue(theme: theme);
  final descriptionTextStyle = sized.descriptionStyle!.toValue(theme: theme);

  return ResolvedCarouselBanner(
    backgroundColor: backgroundColor,
    borderRadius: borderRadius,
    padding: padding,
    thumbnailSize: thumbnailSize,
    thumbnailBorderRadius: thumbnailBorderRadius,
    thumbnailBackgroundColor: thumbnailBackgroundColor,
    thumbnailIconTheme: thumbnailIconTheme,
    thumbnailTextGapStyle: sized.thumbnailTextGapStyle!,
    titleDescriptionGapStyle: sized.titleDescriptionGapStyle!,
    titleTextStyle: titleTextStyle,
    descriptionTextStyle: descriptionTextStyle,
  );
}
