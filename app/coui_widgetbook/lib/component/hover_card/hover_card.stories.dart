import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'hover_card.stories.g.dart';

/// Knob input for [HoverCard] stories.
class HoverCardInput {
  /// Creates a [HoverCardInput].
  const HoverCardInput({
    this.triggerText = 'Hover over me',
    this.contentText = 'This is the hover card content!',
    this.placement = CorePopoverPlacement.bottom,
  });

  /// Text shown on the hover trigger.
  final String triggerText;

  /// Text shown inside the hover card panel.
  final String contentText;

  /// Panel placement relative to the trigger.
  final CorePopoverPlacement placement;
}

/// Navigation metadata for the HoverCard component.
const kComponentMeta = ComponentMeta(name: 'HoverCard', path: 'overlay');

/// Story metadata for [HoverCard].
const kMeta = Meta(HoverCard.new, argsType: HoverCardInput.new);

/// Default builder mapping [HoverCardInput] args to a [HoverCard].
final HoverCardDefaults defaults = _Defaults(
  builder: (context, args) => HoverCard(
    trigger: Text(args.triggerText),
    content: Padding(
      padding: const .all(CoreSpace.space16),
      child: Text(args.contentText),
    ),
    placement: args.placement,
  ),
);

/// Hover the trigger text to reveal the card panel.
final $Default = _Story();
