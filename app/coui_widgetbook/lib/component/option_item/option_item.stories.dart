import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'option_item.stories.g.dart';

// OptionItem widgetbook constants.
//
// A row fills the width it is given, so the harness hands it a sheet's
// content width.
const double _kRowWidth = CoreLayout.layout320;

void _handleNoop() {}

/// Knob input for [OptionItem] stories.
class OptionItemInput {
  /// Creates an [OptionItemInput].
  const OptionItemInput({
    this.label = 'Newest first',
    this.description = '',
    this.selection = CoreOptionItemSelection.defaultSelection,
    this.selected = false,
    this.enabled = true,
  });

  /// Name of the option.
  final String label;

  /// Short line under the label (hidden when empty).
  final String description;

  /// How the chosen state is shown — a check, or a checkbox.
  final CoreOptionItemSelection selection;

  /// Whether the row is chosen.
  final bool selected;

  /// Whether the row accepts a tap.
  final bool enabled;
}

/// Builds an [OptionItem] from [args].
OptionItem _item(_Args args) => OptionItem(
  label: Text(args.label),
  description: args.description.isEmpty ? null : Text(args.description),
  selection: args.selection,
  selected: args.selected,
  enabled: args.enabled,
  onPressed: _handleNoop,
);

/// Navigation metadata for the OptionItem component.
const kComponentMeta = ComponentMeta(name: 'OptionItem', path: 'form');

/// Story metadata for [OptionItem].
const kMeta = Meta(OptionItem.new, argsType: OptionItemInput.new);

/// Default builder mapping [OptionItemInput] args to an [OptionItem].
final OptionItemDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kRowWidth, child: child),
  builder: (context, args) => _item(args),
);

/// A row that is not chosen.
final $Default = _Story();

/// A chosen single-selection row — a check at the end, the accent label.
final $Selected = _Story(
  name: 'Selected',
  args: _Args(selected: BoolArg(true)),
);

/// A multiple-selection row — a checkbox on every row.
final $Multiple = _Story(
  name: 'Multiple',
  args: _Args(
    selection: EnumArg(
      CoreOptionItemSelection.multiple,
      values: CoreOptionItemSelection.values,
    ),
    selected: BoolArg(true),
  ),
);

/// A row with a short line under the label.
final $WithDescription = _Story(
  name: 'With Description',
  args: _Args(description: StringArg('Sorted by date added')),
);

/// A row that does not accept a tap.
final $Disabled = _Story(
  name: 'Disabled',
  args: _Args(enabled: BoolArg(false), selected: BoolArg(true)),
);
