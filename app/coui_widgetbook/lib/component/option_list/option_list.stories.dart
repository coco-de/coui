import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'option_list.stories.g.dart';

// OptionList widgetbook constants.
//
// The list fills the width it is given, so the harness hands it a sheet's
// content width.
const double _kListWidth = CoreLayout.layout320;
const int _kDefaultCount = 4;

void _handleNoop() {}

/// Knob input for [OptionList] stories.
class OptionListInput {
  /// Creates an [OptionListInput].
  const OptionListInput({
    this.count = _kDefaultCount,
    this.selection = CoreOptionItemSelection.defaultSelection,
    this.selectedIndex = 0,
  });

  /// How many rows the list holds.
  final int count;

  /// How each row shows its chosen state.
  final CoreOptionItemSelection selection;

  /// Index of the chosen row.
  final int selectedIndex;
}

/// Builds an [OptionList] from [args].
OptionList _list(_Args args) => OptionList(
  children: [
    for (var index = 0; index < args.count; index++)
      OptionItem(
        label: Text('Option ${index + 1}'),
        selection: args.selection,
        selected: index == args.selectedIndex,
        onPressed: _handleNoop,
      ),
  ],
);

/// Navigation metadata for the OptionList component.
const kComponentMeta = ComponentMeta(name: 'OptionList', path: 'form');

/// Story metadata for [OptionList].
const kMeta = Meta(OptionList.new, argsType: OptionListInput.new);

/// Default builder mapping [OptionListInput] args to an [OptionList].
final OptionListDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kListWidth, child: child),
  builder: (context, args) => _list(args),
);

/// Four single-selection rows, the first one chosen.
final $Default = _Story();

/// Four multiple-selection rows — a checkbox on each.
final $Multiple = _Story(
  name: 'Multiple',
  args: _Args(
    selection: EnumArg(
      CoreOptionItemSelection.multiple,
      values: CoreOptionItemSelection.values,
    ),
  ),
);
