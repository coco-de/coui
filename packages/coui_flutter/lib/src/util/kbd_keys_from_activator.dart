import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

/// The labels a `Kbd` shows for a Flutter [ShortcutActivator].
///
/// ```dart
/// Kbd(
///   keys: kbdKeysFromActivator(
///     const SingleActivator(LogicalKeyboardKey.keyS, control: true),
///   ),
/// ) // Ctrl S
/// ```
///
/// Modifiers come first in the order Apple's Human Interface Guidelines
/// write them — Control, Option, Shift, Command (`Ctrl` → `Alt` → `Shift` →
/// `⌘`) — then the trigger key. The order belongs to this function, not to
/// the activator: a [LogicalKeySet] holds its keys in a set, which keeps no
/// order of its own.
///
/// Flutter-only: [ShortcutActivator] has no counterpart on the Web side,
/// where a shortcut is already a list of key labels.
List<String> kbdKeysFromActivator(ShortcutActivator activator) {
  final modifiers = _Modifiers();
  final triggers = <LogicalKeyboardKey>[];

  switch (activator) {
    case CharacterActivator():
      modifiers
        ..control = activator.control
        ..alt = activator.alt
        ..meta = activator.meta;
      return [
        ...modifiers.labels,
        activator.character.toUpperCase(),
      ];
    case SingleActivator():
      modifiers
        ..control = activator.control
        ..alt = activator.alt
        ..shift = activator.shift
        ..meta = activator.meta;
      triggers.add(activator.trigger);
    case LogicalKeySet():
      // A set carries no order, so the non-modifier keys are put in a stable
      // one rather than whichever the set happens to iterate.
      final others = <LogicalKeyboardKey>[];
      for (final key in activator.triggers) {
        if (!modifiers.take(key)) others.add(key);
      }
      triggers.addAll(others..sort((a, b) => a.keyId.compareTo(b.keyId)));
    default:
      break;
  }

  return [
    ...modifiers.labels,
    for (final key in triggers) _triggerLabel(key),
  ];
}

/// Label of a non-modifier trigger key. A trigger that is itself a modifier
/// (`SingleActivator(LogicalKeyboardKey.shift)`) keeps its modifier label.
String _triggerLabel(LogicalKeyboardKey key) {
  return switch (key) {
    .control || .controlLeft || .controlRight => _kCtrl,
    .shift || .shiftLeft || .shiftRight => _kShift,
    .alt || .altLeft || .altRight => _kAlt,
    .meta || .metaLeft || .metaRight => _kMeta,
    .enter => '↵',
    .arrowLeft => '←',
    .arrowRight => '→',
    .arrowUp => '↑',
    .arrowDown => '↓',
    _ => key.keyLabel,
  };
}

const _kCtrl = 'Ctrl';
const _kAlt = 'Alt';
const _kShift = 'Shift';
const _kMeta = '⌘';

/// Which modifiers an activator asks for, written out in display order.
class _Modifiers {
  bool control = false;
  bool alt = false;
  bool shift = false;
  bool meta = false;

  /// Records [key] when it is a modifier. Returns whether it was one.
  bool take(LogicalKeyboardKey key) {
    switch (key) {
      case .control || .controlLeft || .controlRight:
        control = true;
      case .alt || .altLeft || .altRight:
        alt = true;
      case .shift || .shiftLeft || .shiftRight:
        shift = true;
      case .meta || .metaLeft || .metaRight:
        meta = true;
      default:
        return false;
    }
    return true;
  }

  /// The set modifiers, Ctrl → Alt → Shift → ⌘.
  List<String> get labels => [
    if (control) _kCtrl,
    if (alt) _kAlt,
    if (shift) _kShift,
    if (meta) _kMeta,
  ];
}
