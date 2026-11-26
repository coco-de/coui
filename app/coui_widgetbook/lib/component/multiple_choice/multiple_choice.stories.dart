import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'multiple_choice.stories.g.dart';

// MultipleChoice widgetbook constants.
const _kContentWidth = 300.0;

/// Interactive demo host for [MultipleChoice] stories.
class MultipleChoiceDemo extends StatefulWidget {
  /// Creates a [MultipleChoiceDemo].
  const MultipleChoiceDemo({super.key, this.allowUnselect = false});

  /// Whether tapping the active option clears the selection.
  final bool allowUnselect;

  @override
  State<MultipleChoiceDemo> createState() => _MultipleChoiceDemoState();
}

class _MultipleChoiceDemoState extends State<MultipleChoiceDemo> {
  String? _selected;

  void handleChanged(String? value) {
    setState(() => _selected = value);
  }

  @override
  Widget build(BuildContext context) {
    final mcStrings = t.widgetbook.multiple_choice;

    return SizedBox(
      width: _kContentWidth,
      child: Column(
        mainAxisSize: .min,
        spacing: CoreSpace.space16,
        children: [
          MultipleChoice<String>(
            onChanged: handleChanged,
            options: [
              (value: 'A', label: mcStrings.option_a),
              (value: 'B', label: mcStrings.option_b),
              (value: 'C', label: mcStrings.option_c),
              (value: 'D', label: mcStrings.option_d),
            ],
            value: _selected,
            allowUnselect: widget.allowUnselect,
          ),
          Text(
            mcStrings.selected_value(value: _selected ?? '-'),
          ).bodySmall().onSurface(),
        ],
      ),
    );
  }
}

/// Navigation metadata for the MultipleChoice component.
const kComponentMeta = ComponentMeta(name: 'MultipleChoice', path: 'form');

/// Story metadata for [MultipleChoiceDemo].
const kMeta = Meta(MultipleChoiceDemo.new);

/// Single-select choice group (re-tapping keeps the selection).
final $SingleChoice = _Story(name: 'Single Choice');

/// Choice group where the active option can be unselected.
final $MultipleAnswer = _Story(
  name: 'Multiple Answer',
  args: _Args(allowUnselect: BoolArg(true)),
);
