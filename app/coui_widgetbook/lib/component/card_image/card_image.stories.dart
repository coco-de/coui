import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'card_image.stories.g.dart';

// CardImage widgetbook constants.
const _kCardWidth = 240.0;
const _kImageWidth = 240.0;
const _kImageHeight = 160.0;
const _kIconSize = 16.0;
const _kImageUrl = 'https://picsum.photos/seed/coui/240/160';

/// Knob input for [CardImage] stories.
class CardImageInput {
  /// Creates a [CardImageInput].
  const CardImageInput({
    this.title = 'Mountain View',
    this.subtitle = 'Captured at sunrise',
    this.enabled = true,
    this.showLeadingIcon = false,
    this.showTrailingIcon = false,
  });

  /// Title text.
  final String title;

  /// Subtitle text.
  final String subtitle;

  /// Whether the card reacts to taps.
  final bool enabled;

  /// Whether a leading icon is shown.
  final bool showLeadingIcon;

  /// Whether a trailing icon is shown.
  final bool showTrailingIcon;
}

/// Navigation metadata for the CardImage component.
const kComponentMeta = ComponentMeta(name: 'Card Image', path: 'layout');

/// Story metadata for [CardImage].
const kMeta = Meta(CardImage.new, argsType: CardImageInput.new);

void _handleNoop() {}

/// Default builder mapping [CardImageInput] args to a [CardImage].
final CardImageDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kCardWidth, child: child),
  builder: (context, args) => CardImage(
    onPressed: _handleNoop,
    image: Image.network(
      _kImageUrl,
      semanticLabel: args.title,
      width: _kImageWidth,
      height: _kImageHeight,
      fit: .cover,
    ),
    title: Text(args.title),
    subtitle: Text(args.subtitle),
    leading: args.showLeadingIcon
        ? const Icon(
            LucideIcons.mapPin,
            iconStyle: CoreIconStyle(size: _kIconSize),
          )
        : null,
    trailing: args.showTrailingIcon
        ? const Icon(
            LucideIcons.heart,
            iconStyle: CoreIconStyle(size: _kIconSize),
          )
        : null,
    enabled: args.enabled,
  ),
);

/// Tappable image card with editable knobs.
final $Default = _Story();

/// Card image with leading and trailing icon slots.
final $WithLeadingAndTrailing = _Story(
  name: 'With Leading & Trailing',
  args: _Args(
    title: StringArg('Jeju Island'),
    subtitle: StringArg('South Korea'),
    showLeadingIcon: BoolArg(true),
    // distinct story knobs share the same value.
    showTrailingIcon: BoolArg(true),
  ),
);
