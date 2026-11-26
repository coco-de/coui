/// Per-instance style for `CarouselBanner`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/carousel_banner/carousel_banner_size.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `CarouselBanner` should render.
///
/// Platform-neutral. The semantic `size` identifier and the content slots
/// stay on the widget; everything visual arrives here.
@immutable
class CoreCarouselBannerStyle implements CoreStyle<CoreCarouselBannerStyle> {
  /// Creates a [CoreCarouselBannerStyle].
  const CoreCarouselBannerStyle({
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.thumbnailSize,
    this.thumbnailBorderRadius,
    this.thumbnailBackgroundColor,
    this.thumbnailIconStyle,
    this.thumbnailTextGapStyle,
    this.titleDescriptionGapStyle,
    this.titleStyle,
    this.descriptionStyle,
  });

  // ─── Design-system defaults ─────────────────────────────────────

  /// Default strip fill — `primaryContainer`.
  ///
  /// A tinted band rather than the page's own surface: this strip is an
  /// interruption in a column of content, and a fill that matches the page
  /// makes it read as more of that content. The container step is the one
  /// tint the palette states as "carries text at body contrast".
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.primaryContainer,
  );

  /// Default strip corner — the `panel` role (12).
  ///
  /// An inline strip that sits in the page flow and carries its own tint is
  /// the same kind of face as an inline alert, and that is the step the
  /// radius ladder gives it. The thumbnail inside keeps its own, smaller
  /// corner ([defaultThumbnailBorderRadius]): a picture box is not the strip.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadiusRole.panel,
  );

  /// Default thumbnail corner — `radius8`.
  ///
  /// Smaller than the strip's corner on purpose: the thumbnail is a picture
  /// inset inside a tinted band, and a picture at the band's own corner
  /// would read as a second band. It is a picture box rather than a
  /// control, so no role names it and the step is stated as it is.
  static const CoreBorderRadius defaultThumbnailBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius8);

  /// Default thumbnail placeholder fill — `surface`.
  ///
  /// What shows through where a caller's picture does not reach (a
  /// transparent PNG, a slow network). The page's own surface, so the hole
  /// reads as empty rather than as a second tint.
  static const CoreColor defaultThumbnailBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default colour of an icon placed in the thumbnail — `onSurfaceVariant`.
  ///
  /// The glyph stands in for a picture on the `surface` placeholder, so it
  /// recedes (the variant tone) instead of speaking at body contrast.
  static const CoreColor defaultThumbnailIconColor = CoreColor.token(
    CoreColors.onSurfaceVariant,
  );

  /// Default title colour, carried inside [defaultsBySize]'s title role —
  /// `onPrimaryContainer`, the foreground the fill states.
  static const CoreColor defaultTitleColor = CoreColor.token(
    CoreColors.onPrimaryContainer,
  );

  /// Default description colour — the title's token, not a step down.
  ///
  /// On a tinted container a grey does not read as a second step; it
  /// reads as unreadable. Both lines take the container's own foreground
  /// and weight carries the hierarchy instead — the same call `Banner`
  /// makes on its nine tinted variants.
  static const CoreColor defaultDescriptionColor = CoreColor.token(
    CoreColors.onPrimaryContainer,
  );

  // ─── Size-keyed defaults ─────────────────────────────────────────
  //
  // Every metric that separates the two sizes, in one table. The
  // designer draws both and they move together: a wider strip gets a
  // deeper inset, a larger picture, more air
  // between picture and text, and one step up on both type roles.
  /// Per-size defaults for the fields that differ between `sm` and `md`.
  static const Map<CoreCarouselBannerSize, CoreCarouselBannerStyle>
  defaultsBySize = {
    CoreCarouselBannerSize.sm: CoreCarouselBannerStyle(
      padding: CoreEdgeInsets.all(CoreSpace.space16),
      thumbnailSize: CoreSize.size56,
      thumbnailIconStyle: CoreIconStyle(
        size: CoreIconSize.size24,
        color: defaultThumbnailIconColor,
      ),
      thumbnailTextGapStyle: CoreGapStyle(size: CoreSpace.space12),
      titleDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space2),
      titleStyle: CoreTextStyle.token(
        CoreTextStyles.titleSmall,
        color: defaultTitleColor,
      ),
      descriptionStyle: CoreTextStyle.token(
        CoreTextStyles.bodySmall,
        color: defaultDescriptionColor,
      ),
    ),
    CoreCarouselBannerSize.md: CoreCarouselBannerStyle(
      padding: CoreEdgeInsets.all(CoreSpace.space20),
      thumbnailSize: CoreSize.size72,
      thumbnailIconStyle: CoreIconStyle(
        size: CoreIconSize.size24,
        color: defaultThumbnailIconColor,
      ),
      thumbnailTextGapStyle: CoreGapStyle(size: CoreSpace.space16),
      titleDescriptionGapStyle: CoreGapStyle(size: CoreSpace.space2),
      titleStyle: CoreTextStyle.token(
        CoreTextStyles.titleMedium,
        color: defaultTitleColor,
      ),
      descriptionStyle: CoreTextStyle.token(
        CoreTextStyles.bodyMedium,
        color: defaultDescriptionColor,
      ),
    ),
  };

  /// Strip fill override. `null` → [defaultBackgroundColor].
  final CoreColor? backgroundColor;

  /// Strip corner override. `null` → [defaultBorderRadius].
  final CoreBorderRadius? borderRadius;

  /// Strip inset override. `null` → [defaultsBySize] for the active size.
  final CoreEdgeInsets? padding;

  /// Thumbnail side length override (logical px). `null` → [defaultsBySize]
  /// for the active size. The thumbnail is square, and it is what sets the
  /// strip's height: inset + this + inset.
  final double? thumbnailSize;

  /// Thumbnail corner override. `null` → [defaultThumbnailBorderRadius].
  final CoreBorderRadius? thumbnailBorderRadius;

  /// Thumbnail placeholder fill override. `null` →
  /// [defaultThumbnailBackgroundColor].
  final CoreColor? thumbnailBackgroundColor;

  /// How an `Icon` handed to the thumbnail slot is drawn — its size and its
  /// colour. `null` → [defaultsBySize] for the active size.
  ///
  /// The slot's rule has two halves, and this field is the first: an icon is
  /// centred in the square at this size, in this colour, and an image fills
  /// the square. An `Icon` that states its own size or colour keeps it. The
  /// stroke is not a field here — it is a function of the size
  /// (`CoreIconStroke`).
  final CoreIconStyle? thumbnailIconStyle;

  /// Thumbnail → text column spacer. `null` → [defaultsBySize] for the
  /// active size.
  final CoreGapStyle? thumbnailTextGapStyle;

  /// Title → description spacer. `null` → [defaultsBySize] for the active
  /// size.
  final CoreGapStyle? titleDescriptionGapStyle;

  /// Title typography override. `null` → [defaultsBySize] for the active
  /// size.
  final CoreTextStyle? titleStyle;

  /// Description typography override. `null` → [defaultsBySize] for the
  /// active size.
  final CoreTextStyle? descriptionStyle;

  @override
  CoreCarouselBannerStyle merge(CoreCarouselBannerStyle? other) {
    if (other == null) return this;
    return CoreCarouselBannerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      thumbnailSize: other.thumbnailSize ?? thumbnailSize,
      thumbnailBorderRadius:
          other.thumbnailBorderRadius ?? thumbnailBorderRadius,
      thumbnailBackgroundColor:
          other.thumbnailBackgroundColor ?? thumbnailBackgroundColor,
      thumbnailIconStyle:
          thumbnailIconStyle?.merge(other.thumbnailIconStyle) ??
          other.thumbnailIconStyle,
      thumbnailTextGapStyle:
          thumbnailTextGapStyle?.merge(other.thumbnailTextGapStyle) ??
          other.thumbnailTextGapStyle,
      titleDescriptionGapStyle:
          titleDescriptionGapStyle?.merge(other.titleDescriptionGapStyle) ??
          other.titleDescriptionGapStyle,
      titleStyle: titleStyle?.merge(other.titleStyle) ?? other.titleStyle,
      descriptionStyle:
          descriptionStyle?.merge(other.descriptionStyle) ??
          other.descriptionStyle,
    );
  }

  /// Returns a copy with the given fields replaced.
  CoreCarouselBannerStyle copyWith({
    CoreColor? backgroundColor,
    CoreBorderRadius? borderRadius,
    CoreEdgeInsets? padding,
    double? thumbnailSize,
    CoreBorderRadius? thumbnailBorderRadius,
    CoreColor? thumbnailBackgroundColor,
    CoreIconStyle? thumbnailIconStyle,
    CoreGapStyle? thumbnailTextGapStyle,
    CoreGapStyle? titleDescriptionGapStyle,
    CoreTextStyle? titleStyle,
    CoreTextStyle? descriptionStyle,
  }) {
    return CoreCarouselBannerStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      thumbnailSize: thumbnailSize ?? this.thumbnailSize,
      thumbnailBorderRadius:
          thumbnailBorderRadius ?? this.thumbnailBorderRadius,
      thumbnailBackgroundColor:
          thumbnailBackgroundColor ?? this.thumbnailBackgroundColor,
      thumbnailIconStyle: thumbnailIconStyle ?? this.thumbnailIconStyle,
      thumbnailTextGapStyle:
          thumbnailTextGapStyle ?? this.thumbnailTextGapStyle,
      titleDescriptionGapStyle:
          titleDescriptionGapStyle ?? this.titleDescriptionGapStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCarouselBannerStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderRadius == other.borderRadius &&
          padding == other.padding &&
          thumbnailSize == other.thumbnailSize &&
          thumbnailBorderRadius == other.thumbnailBorderRadius &&
          thumbnailBackgroundColor == other.thumbnailBackgroundColor &&
          thumbnailIconStyle == other.thumbnailIconStyle &&
          thumbnailTextGapStyle == other.thumbnailTextGapStyle &&
          titleDescriptionGapStyle == other.titleDescriptionGapStyle &&
          titleStyle == other.titleStyle &&
          descriptionStyle == other.descriptionStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderRadius,
    padding,
    thumbnailSize,
    thumbnailBorderRadius,
    thumbnailBackgroundColor,
    thumbnailIconStyle,
    thumbnailTextGapStyle,
    titleDescriptionGapStyle,
    titleStyle,
    descriptionStyle,
  );
}
