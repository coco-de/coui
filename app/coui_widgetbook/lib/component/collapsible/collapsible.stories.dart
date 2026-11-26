import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'collapsible.stories.g.dart';

// Collapsible widgetbook constants.
const _kContainerWidth = 350.0;
const _kTriggerText = 'Click to expand';
const _kContentText =
    'This is the collapsible content that can be shown or hidden.';
const _kCustomTriggerText = 'FAQ: What is Collapsible?';
const _kDescriptionText = 'A collapsible widget that toggles content on tap.';

/// Knob input for [Collapsible] stories.
class CollapsibleInput {
  /// Creates a [CollapsibleInput].
  const CollapsibleInput({
    this.expanded = false,
    this.customTrigger = false,
  });

  /// Whether the collapsible starts expanded.
  final bool expanded;

  /// Whether a custom FAQ-style row trigger is used instead of the
  /// plain text trigger.
  final bool customTrigger;
}

/// Navigation metadata for the Collapsible component.
const kComponentMeta = ComponentMeta(name: 'Collapsible', path: 'layout');

/// Story metadata for [Collapsible].
const kMeta = Meta(Collapsible.new, argsType: CollapsibleInput.new);

/// Default builder mapping [CollapsibleInput] args to a [Collapsible].
final CollapsibleDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: _kContainerWidth,
    child: child,
  ),
  builder: (context, args) => Collapsible(
    trigger: args.customTrigger
        ? const Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Expanded(child: Text(_kCustomTriggerText)),
              Icon(LucideIcons.chevronDown),
            ],
          )
        : const Text(_kTriggerText),
    content: Padding(
      padding: const .all(CoreSpace.space16),
      child: args.customTrigger
          ? const Text(_kDescriptionText)
          : const Text(_kContentText),
    ),
    expanded: args.expanded,
  ),
);

/// Plain text trigger that toggles the content on tap.
final $Default = _Story();

/// FAQ-style custom trigger row with a chevron icon.
final $CustomTrigger = _Story(
  name: 'Custom Trigger',
  args: _Args(customTrigger: BoolArg(true)),
);
