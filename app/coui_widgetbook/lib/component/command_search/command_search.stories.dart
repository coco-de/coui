import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'command_search.stories.g.dart';

// CommandSearch widgetbook constants.
//
// The trigger seats its hint in an `Expanded`, so the harness has to hand it
// a bounded width the way an app bar's centre slot would.
const double _kTriggerWidth = CoreLayout.layout320;

void _handleNoop() {}

/// Knob input for [CommandSearch] stories.
class CommandSearchInput {
  /// Creates a [CommandSearchInput].
  const CommandSearchInput({
    this.hint = '',
    this.size = CoreCommandSize.md,
    this.showShortcut = true,
    this.enabled = true,
  });

  /// Hint text — the active locale's palette placeholder when empty.
  final String hint;

  /// Trigger density — the 32 / 40 / 48 height ladder.
  final CoreCommandSize size;

  /// Whether a `⌘K` key cap sits in the shortcut seat.
  final bool showShortcut;

  /// Whether the trigger accepts activation. A disabled trigger leaves the
  /// tab order, like any disabled button.
  final bool enabled;
}

/// Builds a [CommandSearch] from [args].
CommandSearch _trigger(_Args args) => CommandSearch(
  size: args.size,
  hint: args.hint.isEmpty ? null : args.hint,
  shortcut: args.showShortcut ? const Kbd(keys: ['⌘K']) : null,
  enabled: args.enabled,
  onPressed: _handleNoop,
);

/// Navigation metadata for the CommandSearch component.
const kComponentMeta = ComponentMeta(name: 'CommandSearch', path: 'control');

/// Story metadata for [CommandSearch].
const kMeta = Meta(CommandSearch.new, argsType: CommandSearchInput.new);

/// Default builder mapping [CommandSearchInput] args to a [CommandSearch].
final CommandSearchDefaults defaults = _Defaults(
  setup: (context, child, args) =>
      SizedBox(width: _kTriggerWidth, child: child),
  builder: (context, args) => _trigger(args),
);

/// The trigger at rest with the locale placeholder and a `⌘K` key — tune
/// the size knob to walk the whole [CoreCommandSize] ladder.
final $Default = _Story();

/// A caller-stated hint in place of the locale placeholder.
final $WithHint = _Story(
  name: 'With Hint',
  args: _Args(hint: StringArg('Search docs')),
);

/// Dense 32px trigger for a desktop title bar.
final $Compact = _Story(
  args: _Args(
    size: EnumArg(CoreCommandSize.sm, values: CoreCommandSize.values),
  ),
);

/// 48px trigger for a touch layout.
final $Large = _Story(
  args: _Args(
    size: EnumArg(CoreCommandSize.lg, values: CoreCommandSize.values),
  ),
);

/// Disabled trigger — the disabled face and ink, no wash, no tab stop.
final $Disabled = _Story(args: _Args(enabled: BoolArg(false)));
