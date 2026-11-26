import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'multi_answer_card.stories.g.dart';

/// Interactive demo host for [MultiAnswerCard] stories.
class MultiAnswerCardDemo extends StatefulWidget {
  /// Creates a [MultiAnswerCardDemo].
  const MultiAnswerCardDemo({super.key, this.enabled = true});

  /// Whether the answer cards accept toggling.
  final bool enabled;

  @override
  State<MultiAnswerCardDemo> createState() => _MultiAnswerCardDemoState();
}

class _MultiAnswerCardDemoState extends State<MultiAnswerCardDemo> {
  Set<String> _selected = {'a'};

  void handleToggle(String value) {
    setState(() {
      _selected = _selected.contains(value)
          ? _selected.where((selected) => selected != value).toSet()
          : {..._selected, value};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space8,
      children: [
        MultiAnswerCard<String>(
          onChanged: handleToggle,
          value: 'a',
          selected: _selected.contains('a'),
          enabled: widget.enabled,
          child: const Text('Answer A'),
        ),
        MultiAnswerCard<String>(
          onChanged: handleToggle,
          value: 'b',
          selected: _selected.contains('b'),
          enabled: widget.enabled,
          child: const Text('Answer B'),
        ),
      ],
    );
  }
}

/// Navigation metadata for the MultiAnswerCard component.
const kComponentMeta = ComponentMeta(name: 'MultiAnswerCard', path: 'form');

/// Story metadata for [MultiAnswerCardDemo].
const kMeta = Meta(MultiAnswerCardDemo.new);

/// Toggleable multi-answer cards with editable enabled knob.
final $Default = _Story();

/// Disabled multi-answer cards.
final $Disabled = _Story(
  args: _Args(enabled: BoolArg(false)),
);
