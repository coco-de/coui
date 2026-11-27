/// A promotional strip for a `Carousel(variant: .banner)` slide.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/carousel_banner/carousel_banner_style.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

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
///       thumbnail: img(src: 'promo.png'),
///       title: Component.text('여름 세일'),
///       description: Component.text('전 품목 30% 할인'),
///       onTap: openSale,
///     ),
///   ],
/// )
/// ```
///
/// surface:content — a face in the page flow: what shows through it is the
/// page it is laid on.
class CarouselBanner extends UiComponent
    implements CoreCarouselBannerContract<Component> {
  /// Creates a [CarouselBanner].
  const CarouselBanner({
    super.key,
    this.onTap,
    this.size = CoreCarouselBannerSize.defaultSize,
    this.thumbnail,
    this.title,
    this.description,
    this.carouselBannerStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final CoreCarouselBannerSize size;

  @override
  final Component? thumbnail;

  @override
  final Component? title;

  @override
  final Component? description;

  @override
  final void Function()? onTap;

  @override
  final CoreCarouselBannerStyle? carouselBannerStyle;

  @override
  CarouselBanner copyWith({
    Key? key,
    void Function()? onTap,
    CoreCarouselBannerSize? size,
    Component? thumbnail,
    Component? title,
    Component? description,
    CoreCarouselBannerStyle? carouselBannerStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
  }) => CarouselBanner(
    key: key ?? this.key,
    onTap: onTap ?? this.onTap,
    size: size ?? this.size,
    thumbnail: thumbnail ?? this.thumbnail,
    title: title ?? this.title,
    description: description ?? this.description,
    carouselBannerStyle: carouselBannerStyle ?? this.carouselBannerStyle,
    id: id ?? this.id,
    classes: classes ?? this.classes,
    css: css ?? this.css,
    attributes: attributes ?? userProvidedAttributes,
    eventHandlers: eventHandlers ?? this.eventHandlers,
  );

  @override
  Component build(BuildContext context) {
    final resolved = resolveCarouselBanner(
      context,
      size: size,
      carouselBannerStyle: carouselBannerStyle,
    );

    final interactive = onTap != null;
    final rules = resolveCarouselBannerRules();
    // Interactive: the caller passthrough moves to the composing
    // `Clickable` root (the pattern `Card` uses) and the strip carries
    // only its own resolved chrome. Otherwise everything the caller
    // handed us stays on the styled root.
    final strip = div(
      [
        if (thumbnail != null) ...[
          div(
            [
              Component.element(
                tag: 'style',
                children: [RawText(rules.css)],
              ),
              // Nearest `IconTheme` so an `Icon` handed to the slot draws at
              // the icon size and colour the style states, centred by the
              // flex box — the app-root ambient size and colour would
              // otherwise decide (mirrors the Flutter twin's `IconTheme`).
              // Emits no DOM.
              IconTheme(
                data: IconThemeData.fromCoreIconStyle(
                  resolved.thumbnailIconStyle,
                ),
                child: thumbnail!,
              ),
            ],
            classes: resolved.thumbnail.className,
            styles: resolved.thumbnail.inlineStyles,
          ),
          Gap(gapStyle: resolved.thumbnailTextGapStyle),
        ],
        div(
          [
            if (title != null)
              div(
                [title!],
                classes: resolved.title.className,
                styles: resolved.title.inlineStyles,
              ),
            if (title != null && description != null)
              Gap(gapStyle: resolved.titleDescriptionGapStyle),
            if (description != null)
              div(
                [description!],
                classes: resolved.description.className,
                styles: resolved.description.inlineStyles,
              ),
          ],
          classes: resolved.text.className,
          styles: resolved.text.inlineStyles,
        ),
      ],
      id: interactive ? null : id,
      classes: interactive
          ? resolved.root.className
          : rootClasses(resolved.root.className),
      styles: interactive
          ? resolved.root.inlineStyles
          : Styles.combine([?resolved.root.inlineStyles, ?this.css]),
      attributes: interactive ? null : componentAttributes,
      events: interactive ? null : this.events,
    );

    if (!interactive) return strip;

    // The composed `Clickable` owns tap, keyboard activation, cursor and
    // the focus ring (`role="button"` + `tabindex`) — the same thing
    // `Card` does with its own tap. Hand-rolling `role` and a click
    // handler here would leave the strip unreachable by keyboard while
    // looking correct with a mouse. No `clickableStyle` slot: the strip
    // states no divergence from `Clickable`'s own interaction chrome.
    return Clickable(
      onPressed: onTap,
      attributes: componentAttributes,
      classes: classes,
      css: this.css,
      eventHandlers: eventHandlers,
      id: id,
      child: strip,
    );
  }
}

/// Chain sugar for merging a [CoreCarouselBannerStyle] patch into
/// [CarouselBanner.carouselBannerStyle] without hand-reconstructing every
/// field. Mirrors the Flutter extension so both platforms read
/// identically.
extension CarouselBannerStyleChain on CarouselBanner {
  /// Sets the content padding.
  CarouselBanner contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreCarouselBannerStyle(padding: value));

  /// Sets the background paint and preserves the other style fields.
  CarouselBanner backgroundColor(CoreColor value) =>
      withStyle(CoreCarouselBannerStyle(backgroundColor: value));

  /// Returns a copy with [patch] merged over the existing chrome slot.
  CarouselBanner withStyle(CoreCarouselBannerStyle patch) => copyWith(
    carouselBannerStyle:
        carouselBannerStyle?.merge(patch) ??
        const CoreCarouselBannerStyle().merge(patch),
  );
}
