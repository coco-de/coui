import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'kbd.stories.g.dart';

// Kbd widgetbook constants.
const _kDefaultKeysText = 'Ctrl+Shift+P';
const _kSingleKeyText = 'Cmd';
const _kTwoKeysText = 'Ctrl+S';

// An OS-defined shortcut (macOS: screenshot of a region to the clipboard) —
// the one place a fourth key belongs. Apps keep their own shortcuts to three.
const _kFourKeysText = '⌃+⇧+⌘+4';

/// Knob input for [Kbd] stories.
class KbdInput {
  /// Creates a [KbdInput].
  const KbdInput({this.keysText = _kDefaultKeysText});

  /// Key names separated by `+` in this knob only (e.g. `Ctrl+Shift+P`) —
  /// the number of names is the number of keys. The rendered [Kbd] draws no
  /// `+` between them.
  final String keysText;
}

/// Navigation metadata for the Kbd component.
const kComponentMeta = ComponentMeta(name: 'Kbd', path: 'display');

/// Story metadata for [Kbd].
const kMeta = Meta(Kbd.new, argsType: KbdInput.new);

/// Default builder mapping [KbdInput] args to a [Kbd].
final KbdDefaults defaults = _Defaults(
  builder: (context, args) => Kbd(keys: _toKeys(args.keysText)),
);

/// Three-key combo (the most an app-defined shortcut uses), with editable
/// knobs. The key caps sit side by side; nothing is drawn between them.
final $Default = _Story();

/// One key cap (the `Kbd.single` shape).
final $SingleKey = _Story(
  name: 'Single Key',
  args: _Args(keysText: StringArg(_kSingleKeyText)),
);

/// Two keys.
final $TwoKeys = _Story(
  name: 'Two Keys',
  args: _Args(keysText: StringArg(_kTwoKeysText)),
);

/// Four keys — only for a shortcut the OS defines (about 92 ~ 96 wide; it
/// overflows an 80 ~ 120 fixed box).
final $FourKeys = _Story(
  name: 'Four Keys',
  args: _Args(keysText: StringArg(_kFourKeysText)),
);

/// Splits a `+`-separated string of key names into a trimmed key list,
/// falling back to a single placeholder key when the input is blank.
List<String> _toKeys(String keysText) {
  final keys = keysText
      .split('+')
      .map((key) => key.trim())
      .where((key) => key.isNotEmpty)
      .toList();

  return keys.isEmpty ? const ['Key'] : keys;
}
