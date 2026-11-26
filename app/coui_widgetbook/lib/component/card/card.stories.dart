import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'card.stories.g.dart';

// Card widgetbook constants.
const _kCardWidth = 300.0;
const _kMediaHeight = 120.0;
const _kMediaIconSize = 32.0;
const _kMediaBackground = Color(0xFFF3F4F6);
const _kMediaIconColor = CoreColor(0xFF9CA3AF);

/// Knob input for [Card] stories.
class CardInput {
  /// Creates a [CardInput].
  const CardInput({
    this.variant = CoreCardVariant.defaultVariant,
    this.elevation = CoreCardElevation.none,
    this.headerText = '',
    this.bodyText = 'This is the card content with some description text.',
    this.footerText = '',
    this.badgeText = 'NEW',
    this.showMedia = false,
    this.showOverlayBadge = false,
  });

  /// Card variant.
  final CoreCardVariant variant;

  /// Card shadow elevation.
  final CoreCardElevation elevation;

  /// Header slot text — hidden when empty.
  final String headerText;

  /// Body slot text.
  final String bodyText;

  /// Footer slot text — hidden when empty.
  final String footerText;

  /// Overlay badge label.
  final String badgeText;

  /// Whether the media placeholder is shown.
  final bool showMedia;

  /// Whether the overlay badge is shown.
  final bool showOverlayBadge;
}

/// Media placeholder for the card media slot.
class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kMediaBackground,
      height: _kMediaHeight,
      child: const Center(
        child: Icon(
          LucideIcons.image,
          iconStyle: CoreIconStyle(
            size: _kMediaIconSize,
            color: _kMediaIconColor,
          ),
        ),
      ),
    );
  }
}

/// Navigation metadata for the Card component.
const kComponentMeta = ComponentMeta(name: 'Card', path: 'layout');

/// Story metadata for [Card].
const kMeta = Meta(Card.new, argsType: CardInput.new);

/// Default builder mapping [CardInput] args to a [Card].
final CardDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kCardWidth, child: child),
  builder: (context, args) => Card(
    variant: args.variant,
    media: args.showMedia ? const _MediaPlaceholder() : null,
    header: args.headerText.isEmpty
        ? null
        : Text(args.headerText).bodySmall().bold(),
    body: Text(args.bodyText),
    footer: args.footerText.isEmpty
        ? null
        : Text(args.footerText).medium().bold(),
    overlay: args.showOverlayBadge
        ? Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const .all(CoreSpace.space8),
              child: Badge(child: Text(args.badgeText)),
            ),
          )
        : null,
    cardStyle: CoreCardStyle(elevation: args.elevation),
  ),
);

/// Outlined card with editable knobs.
final $Default = _Story();

/// Card with a header slot.
final $WithHeader = _Story(
  name: 'With Header',
  args: _Args(headerText: StringArg('Card Title')),
);

/// Filled variant card.
final $Filled = _Story(
  args: _Args(
    variant: EnumArg(CoreCardVariant.filled, values: CoreCardVariant.values),
    headerText: StringArg('Filled'),
    bodyText: StringArg('Filled variant card'),
  ),
);

/// Card with a soft shadow — tune the elevation knob to compare
/// every [CoreCardElevation] level per variant.
final $Elevated = _Story(
  args: _Args(
    elevation: EnumArg(
      CoreCardElevation.soft,
      values: CoreCardElevation.values,
    ),
    headerText: StringArg('Title'),
    bodyText: StringArg('elevation: soft'),
  ),
);

/// Product card composed from media / header / body / footer /
/// overlay slots.
final $ProductCard = _Story(
  name: 'Product Card',
  args: _Args(
    elevation: EnumArg(
      CoreCardElevation.soft,
      values: CoreCardElevation.values,
    ),
    headerText: StringArg('AirPods Pro 2nd Gen'),
    bodyText: StringArg('Apple'),
    footerText: StringArg('KRW 359,000'),
    badgeText: StringArg('NEW'),
    showMedia: BoolArg(true),
    // distinct story knobs share the same value.
    showOverlayBadge: BoolArg(true),
  ),
);

/// Travel card composed from media / header / body / footer slots.
final $TravelCard = _Story(
  name: 'Travel Card',
  args: _Args(
    elevation: EnumArg(
      CoreCardElevation.soft,
      values: CoreCardElevation.values,
    ),
    headerText: StringArg('Bukchon Hanok Stay'),
    bodyText: StringArg('Jongno-gu, Seoul'),
    footerText: StringArg('KRW 189,000/night'),
    showMedia: BoolArg(true),
  ),
);
