import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'command.stories.g.dart';

// Command widgetbook constants.
const _kCommandWidth = 510.0;
const _kCommandHeight = 400.0;
const _kDefaultItemCount = 5;
// Command key symbol (U+2318) for keyboard shortcuts (macOS) —
// written as a unicode escape to keep the source ASCII-only.
// keyboard glyph is intentional UI copy.
const _kCommandKey = '\u2318';

/// Categorized sample groups for the "With Categories" story.
const List<CoreCommandGroup<Widget>> _kCategorizedGroups = [
  CoreCommandGroup(
    items: [
      CoreCommandItem(
        value: 'recent-1',
        label: 'Open recent file',
        icon: Icon(LucideIcons.history),
      ),
      CoreCommandItem(
        value: 'recent-2',
        label: 'View last project',
        icon: Icon(LucideIcons.history),
      ),
    ],
    heading: 'Recent',
  ),
  CoreCommandGroup(
    items: [
      CoreCommandItem(
        value: 'new',
        label: 'New File',
        icon: Icon(LucideIcons.plus),
        shortcut: '${_kCommandKey}N',
      ),
      CoreCommandItem(
        value: 'open',
        label: 'Open File',
        icon: Icon(LucideIcons.folderOpen),
        shortcut: '${_kCommandKey}O',
      ),
      CoreCommandItem(
        value: 'save',
        label: 'Save File',
        icon: Icon(LucideIcons.save),
        shortcut: '${_kCommandKey}S',
      ),
    ],
    heading: 'Actions',
  ),
];

List<CoreCommandItem<Widget>> _buildItems(int itemCount) {
  return List.generate(itemCount, (i) {
    return CoreCommandItem(
      value: 'item-${i + 1}',
      label: 'Command Item ${i + 1}',
      icon: const Icon(LucideIcons.star),
      shortcut: '$_kCommandKey${i + 1}',
    );
  });
}

/// Knob input for [Command] stories.
class CommandInput {
  /// Creates a [CommandInput].
  const CommandInput({
    this.placeholder = 'Search commands...',
    this.itemCount = _kDefaultItemCount,
    this.categorized = false,
  });

  /// Search field placeholder text.
  final String placeholder;

  /// Number of generated items in the flat (uncategorized) list.
  final int itemCount;

  /// Whether categorized sample groups are shown instead of the
  /// generated flat list.
  final bool categorized;
}

/// Navigation metadata for the Command component.
const kComponentMeta = ComponentMeta(name: 'Command', path: 'control');

/// Story metadata for [Command].
const kMeta = Meta(Command.new, argsType: CommandInput.new);

/// Default builder mapping [CommandInput] args to a [Command].
final CommandDefaults defaults = _Defaults(
  setup: (context, child, args) => Center(
    child: SizedBox(
      width: _kCommandWidth,
      height: _kCommandHeight,
      child: child,
    ),
  ),
  builder: (context, args) => Command(
    groups: args.categorized
        ? _kCategorizedGroups
        : [CoreCommandGroup(items: _buildItems(args.itemCount))],
    placeholder: args.placeholder,
    onSelect: (value) => debugPrint('Selected: $value'),
  ),
);

/// Flat command palette with a generated item list.
final $Default = _Story();

/// Command palette with "Recent" / "Actions" category headings.
final $WithCategories = _Story(
  name: 'With Categories',
  args: _Args(categorized: BoolArg(true)),
);

/// Dialog chrome — footer on, 640 max width, large shadow. Host still owns
/// the scrim (`Dialog`).
final $Dialog = _Story(
  name: 'Dialog',
  builder: (context, args) => Command(
    presentation: CoreCommandPresentation.dialog,
    groups: _kCategorizedGroups,
    placeholder: args.placeholder,
    onSelect: (value) => debugPrint('Selected: $value'),
  ),
);

/// Fullscreen chrome — no radius/border/shadow, list fills remaining height.
final $Fullscreen = _Story(
  name: 'Fullscreen',
  builder: (context, args) => Command(
    presentation: CoreCommandPresentation.fullscreen,
    groups: _kCategorizedGroups,
    placeholder: args.placeholder,
    onSelect: (value) => debugPrint('Selected: $value'),
  ),
);

/// Compact density (`sm`).
final $SizeSm = _Story(
  name: 'Size Sm',
  builder: (context, args) => Command(
    size: CoreCommandSize.sm,
    groups: _kCategorizedGroups,
    placeholder: args.placeholder,
    onSelect: (value) => debugPrint('Selected: $value'),
  ),
);

/// Touch density (`lg`).
final $SizeLg = _Story(
  name: 'Size Lg',
  builder: (context, args) => Command(
    size: CoreCommandSize.lg,
    groups: _kCategorizedGroups,
    placeholder: args.placeholder,
    onSelect: (value) => debugPrint('Selected: $value'),
  ),
);
