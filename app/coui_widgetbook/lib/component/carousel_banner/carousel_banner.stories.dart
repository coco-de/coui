import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'carousel_banner.stories.g.dart';

// CarouselBanner widgetbook constants.
//
// The strip is a full-width band, so the preview states the band it sits
// in: the two sizes are drawn for two screens and the frame should say
// which one. Widths, not the strip's own metrics — inset, thumbnail, gap
// and both type roles all come from [CoreCarouselBannerSize].
const _kPhoneBandWidth = 360.0;
const _kDesktopBandWidth = 440.0;
const double _kThumbnailIconSize = CoreSize.size24;
const _kThumbnailIconColor = CoreColor.token(CoreColors.onSurfaceVariant);

void _noop() {}

/// Knob input for [CarouselBanner] stories.
class CarouselBannerInput {
  /// Creates a [CarouselBannerInput].
  const CarouselBannerInput({
    this.title = 'Summer Sale',
    this.description = 'Up to 30% off everything',
    this.size = CoreCarouselBannerSize.sm,
    this.showThumbnail = true,
    this.tappable = false,
  });

  /// Headline text.
  final String title;

  /// Supporting line under the title — the line is dropped when empty.
  final String description;

  /// Which of the two band sizes the strip is drawn at.
  final CoreCarouselBannerSize size;

  /// Whether the leading thumbnail is shown.
  final bool showThumbnail;

  /// Whether the strip carries a tap handler.
  final bool tappable;
}

/// Stand-in for a caller-supplied thumbnail picture.
///
/// Only the glyph: the square, its fill and its corner are the strip's own
/// chrome, and the placeholder sits on top of them.
class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        LucideIcons.image,
        iconStyle: CoreIconStyle(
          size: _kThumbnailIconSize,
          color: _kThumbnailIconColor,
        ),
      ),
    );
  }
}

/// Navigation metadata for the CarouselBanner component.
const kComponentMeta = ComponentMeta(name: 'CarouselBanner', path: 'display');

/// Story metadata for [CarouselBanner].
const kMeta = Meta(CarouselBanner.new, argsType: CarouselBannerInput.new);

/// Default builder mapping [CarouselBannerInput] args to a
/// [CarouselBanner].
final CarouselBannerDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: switch (args.size) {
      .sm => _kPhoneBandWidth,
      .md => _kDesktopBandWidth,
    },
    child: child,
  ),
  builder: (context, args) => CarouselBanner(
    onTap: args.tappable ? _noop : null,
    size: args.size,
    thumbnail: args.showThumbnail ? const _ThumbnailPlaceholder() : null,
    title: Text(args.title),
    description: args.description.isEmpty ? null : Text(args.description),
  ),
);

/// Phone-width strip with a thumbnail, a title and a supporting line.
final $Default = _Story();

/// Desktop-width strip — a deeper inset, a larger thumbnail and one step
/// up on both type roles.
final $Medium = _Story(
  args: _Args(
    size: EnumArg(
      CoreCarouselBannerSize.md,
      values: CoreCarouselBannerSize.values,
    ),
    title: StringArg('New this week'),
    description: StringArg('Three titles just landed in the store'),
  ),
);

/// Strip without a thumbnail — the text column takes the full width and
/// the band shrinks to what the words need.
final $NoThumbnail = _Story(
  name: 'No Thumbnail',
  args: _Args(
    showThumbnail: BoolArg(false),
    title: StringArg('Free shipping this weekend'),
    description: StringArg('No minimum order'),
  ),
);

/// Title alone — an empty description drops the line, and the thumbnail
/// still sets the band height.
final $TitleOnly = _Story(
  name: 'Title Only',
  args: _Args(
    title: StringArg('Members get early access'),
    description: StringArg(''),
  ),
);

/// Tappable strip — the composed `Clickable` carries the pointer cursor,
/// keyboard activation and the focus ring.
final $Tappable = _Story(
  args: _Args(
    tappable: BoolArg(true),
    title: StringArg('Open the sale'),
    description: StringArg('Tap, or focus and press Enter'),
  ),
);
