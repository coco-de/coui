import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'definition_list.stories.g.dart';

// DefinitionList widgetbook constants.
const _kPreviewWidth = 360.0;

/// The registry pairs every story starts from.
///
/// Three digit runs of the same shape, so turning
/// [DefinitionList.numeric] on has something to line up.
const List<CoreDefinitionEntry<Widget>> _kRegistryEntries = [
  CoreDefinitionEntry(term: 'Business number', description: '000-00-00000'),
  CoreDefinitionEntry(term: 'Corporate number', description: '000000-0000000'),
  CoreDefinitionEntry(term: 'Issued', description: '2026-09-15'),
];

/// An entry whose description is a widget rather than a string, built
/// through [CoreDefinitionEntry.rich].
const CoreDefinitionEntry<Widget> _kLinkedEntry = CoreDefinitionEntry.rich(
  term: 'Email',
  description: Link(
    href: 'mailto:hello@example.com',
    child: Text('hello@example.com'),
  ),
);

/// Knob input for [DefinitionList] stories.
class DefinitionListInput {
  /// Creates a [DefinitionListInput].
  const DefinitionListInput({
    this.layout = CoreDefinitionLayout.stacked,
    this.numeric = false,
    this.showLinkedEntry = false,
  });

  /// How each term is arranged against its description. Visual only —
  /// every layout announces the same reading order.
  final CoreDefinitionLayout layout;

  /// Whether descriptions use tabular figures, so digits in successive
  /// entries occupy the same horizontal positions.
  final bool numeric;

  /// Whether a [CoreDefinitionEntry.rich] entry is appended, giving the
  /// list one description that is a widget instead of a string.
  final bool showLinkedEntry;
}

/// Navigation metadata for the DefinitionList component.
const kComponentMeta = ComponentMeta(name: 'DefinitionList', path: 'text');

/// Story metadata for [DefinitionList].
const kMeta = Meta(DefinitionList.new, argsType: DefinitionListInput.new);

/// Default builder mapping [DefinitionListInput] args to a
/// [DefinitionList].
final DefinitionListDefaults defaults = _Defaults(
  setup: (context, child, args) =>
      SizedBox(width: _kPreviewWidth, child: child),
  builder: (context, args) => DefinitionList(
    items: [..._kRegistryEntries, if (args.showLinkedEntry) _kLinkedEntry],
    layout: args.layout,
    numeric: args.numeric,
  ),
);

/// Term above description — the default layout, and the only one that
/// cannot overflow at any width.
final $Default = _Story();

/// Pairs running together on one line and wrapping onto the next, for
/// compact runs of short values.
final $Inline = _Story(
  args: _Args(
    layout: EnumArg(
      CoreDefinitionLayout.inline,
      values: CoreDefinitionLayout.values,
    ),
  ),
);

/// Two columns with tabular figures — every description starts at the
/// same edge, so successive digit runs line up vertically.
final $Columns = _Story(
  args: _Args(
    layout: EnumArg(
      CoreDefinitionLayout.columns,
      values: CoreDefinitionLayout.values,
    ),
    numeric: BoolArg(true),
  ),
);

/// A list whose last description is a link rather than plain text,
/// built through [CoreDefinitionEntry.rich].
final $RichDescription = _Story(
  name: 'Rich Description',
  args: _Args(showLinkedEntry: BoolArg(true)),
);
