import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'accordion.stories.g.dart';

/// Knob input for [Accordion] stories.
class AccordionInput {
  /// Creates an [AccordionInput].
  const AccordionInput({
    this.expandedIndex = -1,
    this.allowMultiple = false,
  });

  /// Index of the initially expanded item (-1 expands none).
  final int expandedIndex;

  /// Whether multiple items may be expanded at once.
  final bool allowMultiple;
}

/// Navigation metadata for the Accordion component.
const kComponentMeta = ComponentMeta(name: 'Accordion', path: 'layout');

/// Story metadata for [Accordion].
const kMeta = Meta(Accordion.new, argsType: AccordionInput.new);

/// Default builder mapping [AccordionInput] args to an [Accordion].
final AccordionDefaults defaults = _Defaults(
  builder: (context, args) {
    final labels = t.widgetbook.accordion;
    final entries = [
      (labels.what_is_coui, labels.what_is_coui_answer),
      (labels.how_to_install, labels.how_to_install_answer),
      (labels.is_customizable, labels.is_customizable_answer),
    ];

    return Accordion(
      items: [
        for (final (index, (title, body)) in entries.indexed)
          AccordionItem(
            content: Text(body),
            expanded: args.expandedIndex == index,
            trigger: AccordionTrigger(child: Text(title)),
          ),
      ],
      allowMultiple: args.allowMultiple,
    );
  },
);

/// FAQ accordion with all items collapsed.
final $Default = _Story();

/// Accordion with the second item initially expanded.
final $WithInitialExpanded = _Story(
  name: 'With Initial Expanded',
  args: _Args(expandedIndex: IntArg(1)),
);
