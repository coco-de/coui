/// Single-entry resolver for `CarouselBanner` (Web).
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

const _kThumbnailClass = 'co-carousel-banner-thumbnail';

/// Scoped CSS text for `<style>` block in `CarouselBanner`.
/// Only a direct image fills the thumbnail; nested caller layouts and icons
/// retain their own sizing. Zero specificity lets caller classes and inline
/// styles override these defaults without replacing the caller's element.
class ResolvedCarouselBannerRules {
  /// Creates the thumbnail's structural rules.
  const ResolvedCarouselBannerRules({required this.css});

  /// CSS scoped to the thumbnail wrapper.
  final String css;
}

/// Resolves the direct-image layout rule, shared by both thumbnail sizes.
/// There are no theme values or crop/fit decisions in this structural rule.
ResolvedCarouselBannerRules resolveCarouselBannerRules() {
  final css = StringBuffer()
    ..write(':where(.$_kThumbnailClass > img)')
    ..write('{display:block;width:100%;height:100%}');
  return ResolvedCarouselBannerRules(css: css.toString());
}

/// Paint-ready chrome for Web `CarouselBanner`.
///
/// DOM shape:
///
/// ```text
/// root (<div>)                    fill · corner · inset · flex row · centred
///   ├─ thumbnail (<div>)          square side · corner · placeholder fill ·
///   │                             flex centred; an `Icon` inside is drawn at
///   │                             the icon size and colour the style states
///   │                             (thumbnailIconStyle)
///   │                             // * skips when `thumbnail == null`
///   ├─ gap                        Gap(thumbnailTextGapStyle)
///   └─ text (<div>)               flex column · flex-1 · min-w-0
///        ├─ title                 titleStyle (typography + ink)
///        ├─ gap                   Gap(titleDescriptionGapStyle)
///        └─ description           descriptionStyle
/// ```
///
/// `carousel_banner.dart` reads each slot's `className` + `inlineStyles`
/// straight from `resolved.<slot>` — no merge, no fallback, no conversion
/// in the widget body.
class ResolvedCarouselBanner implements WebResolvedChrome {
  /// Creates a [ResolvedCarouselBanner].
  const ResolvedCarouselBanner({
    required this.root,
    required this.thumbnail,
    required this.text,
    required this.title,
    required this.description,
    required this.thumbnailIconStyle,
    required this.thumbnailTextGapStyle,
    required this.titleDescriptionGapStyle,
  });

  @override
  final WebElementChrome root;

  /// The square picture box at the leading edge.
  final WebElementChrome thumbnail;

  /// The column holding title and description.
  final WebElementChrome text;

  /// The headline's typography and ink.
  final WebElementChrome title;

  /// The supporting line's typography and ink.
  final WebElementChrome description;

  /// Size and colour of an `Icon` placed in the thumbnail — the row's
  /// `thumbnailIconStyle`, so the glyph is centred in the square at its icon
  /// size the way the Flutter twin and the canvas draw it (the box is
  /// flex-centred). Handed to the slot as an ambient `IconTheme`; an `Icon`
  /// that states its own size or colour keeps it.
  final CoreIconStyle thumbnailIconStyle;

  /// Thumbnail → text spacer, raw-forwarded to `Gap`.
  final CoreGapStyle thumbnailTextGapStyle;

  /// Title → description spacer, raw-forwarded on the same terms.
  final CoreGapStyle titleDescriptionGapStyle;
}

/// Resolves `CarouselBanner` chrome for [size], merging the theme slot
/// under the per-instance [carouselBannerStyle].
ResolvedCarouselBanner resolveCarouselBanner(
  BuildContext context, {
  CoreCarouselBannerSize size = CoreCarouselBannerSize.defaultSize,
  CoreCarouselBannerStyle? carouselBannerStyle,
}) {
  final bannerTheme = context.theme.coreComponentTheme?.carouselBanner;

  // ─── Stage 1 RESOLVE (identical to Flutter) ───────────
  final merged = resolveStyleChain(const CoreCarouselBannerStyle(), [
    bannerTheme?.style,
    carouselBannerStyle,
  ]);
  // The size row under everything the caller and the project stated: the
  // size metrics move together, so the table is the base rather than
  // separate fallback rungs for each field.
  final sized = CoreCarouselBannerStyle.defaultsBySize[size]!.merge(merged);

  // ─── Stage 2 EMIT (theme-free emit family) ────────────
  final backgroundEmit = emitColor(
    merged.backgroundColor,
    CoreCarouselBannerStyle.defaultBackgroundColor,
    .background,
  );
  final radiusEmit = emitRadius(
    merged.borderRadius,
    CoreCarouselBannerStyle.defaultBorderRadius,
  );
  final paddingEmit = emitSpacing(
    merged.padding,
    sized.padding!,
    prefix: 'p',
    cssProperty: 'padding',
  );
  final thumbnailRadiusEmit = emitRadius(
    merged.thumbnailBorderRadius,
    CoreCarouselBannerStyle.defaultThumbnailBorderRadius,
  );
  final thumbnailBackgroundEmit = emitColor(
    merged.thumbnailBackgroundColor,
    CoreCarouselBannerStyle.defaultThumbnailBackgroundColor,
    .background,
  );
  final titleEmit = emitTypography(merged.titleStyle, sized.titleStyle!);
  final descriptionEmit = emitTypography(
    merged.descriptionStyle,
    sized.descriptionStyle!,
  );

  // The thumbnail's side is a number rather than a token key: it is
  // `size56` / `size72` on the scale, and `CoreSize.scale` does not
  // reach Tailwind's `w-` / `h-` utilities (see `core/design-tokens.md`),
  // so the one honest emit is a rem length inline.
  final thumbnailSide = sized.thumbnailSize! / kRemDivisor;

  String buildRootClassName() => [
    WebLayout.flex,
    WebLayout.flexRow,
    WebLayout.itemsCenter,
    WebLayout.wFull,
    if (backgroundEmit.className.isNotEmpty) backgroundEmit.className,
    if (radiusEmit.className.isNotEmpty) radiusEmit.className,
    if (paddingEmit.className.isNotEmpty) paddingEmit.className,
  ].join(' ');

  Styles? buildRootInlineStyles() {
    final raw = <String, String>{
      ...?backgroundEmit.inline,
      ...?radiusEmit.inline,
      ...?paddingEmit.inline,
    };
    return raw.isEmpty ? null : Styles(raw: raw);
  }

  // Flex-centred, like the canvas's thumbnail frame: whatever the caller
  // puts in sits in the middle of the square rather than at its top-left
  // corner, and as a flex item it is blockified, so an inline glyph's
  // baseline offset does not push it out of the box.
  String buildThumbnailClassName() => [
    _kThumbnailClass,
    WebLayout.flex,
    WebLayout.itemsCenter,
    WebLayout.justifyCenter,
    WebLayout.shrinkZero,
    if (thumbnailBackgroundEmit.className.isNotEmpty)
      thumbnailBackgroundEmit.className,
    if (thumbnailRadiusEmit.className.isNotEmpty) thumbnailRadiusEmit.className,
  ].join(' ');

  Styles buildThumbnailInlineStyles() => Styles(
    raw: {
      // Square, and it is what sets the strip's height: inset + this +
      // inset. `overflow: hidden` keeps a caller's photo inside the
      // corner the strip states.
      'width': '${thumbnailSide}rem',
      'height': '${thumbnailSide}rem',
      'overflow': 'hidden',
      ...?thumbnailBackgroundEmit.inline,
      ...?thumbnailRadiusEmit.inline,
    },
  );

  return ResolvedCarouselBanner(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    thumbnail: WebElementChrome(
      className: buildThumbnailClassName(),
      inlineStyles: buildThumbnailInlineStyles(),
    ),
    // `min-w-0` is what lets the text wrap instead of holding the row open
    // at its longest word — the Flutter twin gets the same from `Expanded`.
    text: const WebElementChrome(
      className:
          '${WebLayout.flex} ${WebLayout.flexCol} '
          '${WebLayout.flex1} ${WebLayout.minWZero}',
    ),
    title: WebElementChrome(
      className: '${titleEmit.className} ${WebLayout.breakWords}',
      inlineStyles: switch (titleEmit.inline) {
        final raw? => Styles(raw: raw),
        null => null,
      },
    ),
    description: WebElementChrome(
      className: '${descriptionEmit.className} ${WebLayout.breakWords}',
      inlineStyles: switch (descriptionEmit.inline) {
        final raw? => Styles(raw: raw),
        null => null,
      },
    ),
    thumbnailIconStyle: sized.thumbnailIconStyle!,
    thumbnailTextGapStyle: sized.thumbnailTextGapStyle!,
    titleDescriptionGapStyle: sized.titleDescriptionGapStyle!,
  );
}
