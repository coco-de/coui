import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'menu_item.stories.g.dart';

// MenuItem widgetbook constants.
//
// A menu row seats its label in an `Expanded`, so the harness has to hand
// it a bounded width the way a menu panel would.
const _kRowWidth = 280.0;

void _handleNoop() {}

/// Knob input for [MenuItem] stories.
class MenuItemInput {
  /// Creates a [MenuItemInput].
  const MenuItemInput({
    this.label = 'Rename',
    this.size = CoreMenuItemSize.md,
    this.tone = CoreMenuItemTone.neutral,
    this.description = '',
    this.shortcut = '',
    this.trailingBadge = '',
    this.showLeadingIcon = true,
    this.showMark = false,
    this.reserveMark = false,
    this.hasSubmenu = false,
    this.selected = false,
    this.enabled = true,
  });

  /// Row label text.
  final String label;

  /// Row density — the 32 / 40 / 48 height ladder.
  final CoreMenuItemSize size;

  /// Whether the row reads as an ordinary or a destructive action.
  final CoreMenuItemTone tone;

  /// Second line under the label — hidden when empty.
  final String description;

  /// Keyboard hint drawn after the label — hidden when empty, and
  /// replaced by the chevron when [hasSubmenu] is set.
  final String shortcut;

  /// Trailing badge label — hidden when empty.
  final String trailingBadge;

  /// Whether the leading glyph seat is filled.
  final bool showLeadingIcon;

  /// Whether the mark seat holds a check glyph.
  final bool showMark;

  /// Whether an empty mark column is reserved so unmarked rows line up
  /// with marked siblings. Has no effect while [showMark] is set.
  final bool reserveMark;

  /// Whether the row opens a submenu — draws the chevron in place of the
  /// shortcut hint.
  final bool hasSubmenu;

  /// Whether the row is selected.
  final bool selected;

  /// Whether the row accepts activation. A disabled row stays a focus
  /// stop and is announced as disabled.
  final bool enabled;
}

/// Builds a [MenuItem] from [args] with [leadingIcon] in the leading seat.
MenuItem _menuRow(_Args args, IconName leadingIcon) => MenuItem(
  onPressed: _handleNoop,
  label: Text(args.label),
  size: args.size,
  tone: args.tone,
  description: args.description.isEmpty ? null : Text(args.description),
  shortcut: args.shortcut.isEmpty ? null : Text(args.shortcut),
  leading: args.showLeadingIcon ? Icon(leadingIcon) : null,
  trailing: args.trailingBadge.isEmpty
      ? null
      : Badge(
          variant: CoreBadgeVariant.filled,
          form: CoreBadgeForm.count,
          size: CoreComponentSize.xs,
          child: Text(args.trailingBadge),
        ),
  mark: args.showMark ? const Icon(LucideIcons.check) : null,
  reserveMark: args.reserveMark,
  hasSubmenu: args.hasSubmenu,
  selected: args.selected,
  enabled: args.enabled,
);

/// Navigation metadata for the MenuItem component.
const kComponentMeta = ComponentMeta(name: 'MenuItem', path: 'menu');

/// Story metadata for [MenuItem].
const kMeta = Meta(MenuItem.new, argsType: MenuItemInput.new);

/// Default builder mapping [MenuItemInput] args to a [MenuItem].
final MenuItemDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(width: _kRowWidth, child: child),
  builder: (context, args) => _menuRow(args, LucideIcons.pencil),
);

/// Ordinary action row with editable knobs — tune the size knob to walk
/// the whole [CoreMenuItemSize] ladder.
final $Default = _Story();

/// Row with a keyboard hint in the seat after the label.
final $WithShortcut = _Story(
  name: 'With Shortcut',
  args: _Args(shortcut: StringArg('F2')),
);

/// Row with a second line — the description grows the row past its
/// height floor and top-aligns the label against the leading glyph.
final $WithDescription = _Story(
  name: 'With Description',
  args: _Args(
    label: StringArg('Export'),
    description: StringArg('Write the current view to a file'),
  ),
  builder: (context, args) => _menuRow(args, LucideIcons.download),
);

/// Row with a check in the mark seat — how a menu draws a toggled item.
/// Turn on the reserveMark knob to see the empty column unmarked
/// siblings keep so their labels stay aligned.
final $WithMark = _Story(
  name: 'With Mark',
  args: _Args(
    label: StringArg('Show grid'),
    showMark: BoolArg(true),
    showLeadingIcon: BoolArg(false),
  ),
);

/// Row carrying a count in the trailing seat, after the shortcut seat.
final $WithTrailingBadge = _Story(
  name: 'With Trailing Badge',
  args: _Args(label: StringArg('Notifications'), trailingBadge: StringArg('3')),
  builder: (context, args) => _menuRow(args, LucideIcons.bell),
);

/// Row that opens a submenu — the chevron takes the seat the shortcut
/// hint would have used.
final $Submenu = _Story(
  args: _Args(label: StringArg('Share'), hasSubmenu: BoolArg(true)),
  builder: (context, args) => _menuRow(args, LucideIcons.share2),
);

/// Selected row — a distinct fill and foreground, not just a mark.
final $Selected = _Story(args: _Args(selected: BoolArg(true)));

/// Destructive row — the tone moves the foreground only, so the hover
/// and pressed wash stays the same ramp as a neutral row.
final $Critical = _Story(
  args: _Args(
    label: StringArg('Delete'),
    tone: EnumArg(
      CoreMenuItemTone.critical,
      values: CoreMenuItemTone.values,
    ),
  ),
  builder: (context, args) => _menuRow(args, LucideIcons.trash2),
);

/// Disabled row — inert, but still reachable by keyboard.
final $Disabled = _Story(args: _Args(enabled: BoolArg(false)));

/// Dense 32px row for desktop menus.
final $Compact = _Story(
  args: _Args(
    size: EnumArg(CoreMenuItemSize.sm, values: CoreMenuItemSize.values),
  ),
);
