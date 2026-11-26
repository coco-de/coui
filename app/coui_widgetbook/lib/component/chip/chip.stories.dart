import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'chip.stories.g.dart';

/// Knob input for [Chip] stories.
///
/// Named `ChipStoryInput` because `ChipInput` is already a coui
/// component class.
class ChipStoryInput {
  /// Creates a [ChipStoryInput].
  const ChipStoryInput({
    this.text = 'Chip',
    this.chipColor = CoreChipColor.neutral,
    this.variant = CoreChipVariant.outlined,
    this.shape = CoreChipShape.rounded,
    this.selected = false,
    this.enabled = true,
    this.showLeadingIcon = false,
    this.showTrailingIcon = false,
  });

  /// Chip label text.
  final String text;

  /// Colour a selected chip takes on.
  final CoreChipColor chipColor;

  /// How an unselected chip is drawn.
  final CoreChipVariant variant;

  /// The outline — the size row's corner, or a pill.
  final CoreChipShape shape;

  /// Whether the chip is selected.
  final bool selected;

  /// Whether the chip is enabled.
  final bool enabled;

  /// Whether a leading icon is shown.
  final bool showLeadingIcon;

  /// Whether a trailing icon is shown.
  final bool showTrailingIcon;
}

/// Navigation metadata for the Chip component.
const kComponentMeta = ComponentMeta(name: 'Chip', path: 'display');

/// Story metadata for [Chip].
const kMeta = Meta(Chip.new, argsType: ChipStoryInput.new);

/// Default builder mapping [ChipStoryInput] args to a [Chip].
final ChipDefaults defaults = _Defaults(
  builder: (context, args) => Chip(
    label: args.text,
    chipColor: args.chipColor,
    variant: args.variant,
    selected: args.selected,
    enabled: args.enabled,
    shape: args.shape,
    // No explicit icon size: the chip's size row sets it (12 / 14 / 14), so
    // the story shows what the component draws.
    leading: args.showLeadingIcon ? const Icon(LucideIcons.star) : null,
    trailing: args.showTrailingIcon ? const Icon(LucideIcons.x) : null,
  ),
);

/// Neutral chip with editable knobs.
final $Default = _Story();

/// Selected primary chip.
final $Selected = _Story(
  args: _Args(
    chipColor: EnumArg(CoreChipColor.primary, values: CoreChipColor.values),
    selected: BoolArg(true),
  ),
);

/// Filled chip — a grey fill and no outline when unselected.
final $Filled = _Story(
  args: _Args(
    variant: EnumArg(CoreChipVariant.filled, values: CoreChipVariant.values),
  ),
);

/// Pill chip — both ends a half circle, on every size.
final $Pill = _Story(
  args: _Args(
    shape: EnumArg(CoreChipShape.pill, values: CoreChipShape.values),
  ),
);

/// Chip with leading and trailing icons.
final $WithIcons = _Story(
  name: 'With Icons',
  args: _Args(
    showLeadingIcon: BoolArg(true),
    // distinct story knobs share the same value.
    showTrailingIcon: BoolArg(true),
  ),
);
