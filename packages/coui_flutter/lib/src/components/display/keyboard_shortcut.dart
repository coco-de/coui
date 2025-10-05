import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

typedef KeyboardShortcutDisplayBuilder =
    Widget Function(BuildContext context, LogicalKeyboardKey key);

/// Theme for keyboard shortcut displays.
class KeyboardShortcutTheme {
  /// Creates a [KeyboardShortcutTheme].
  const KeyboardShortcutTheme({
    this.keyPadding,
    this.keyShadow,
    this.spacing,
  });

  /// Spacing between keys.
  final double? spacing;

  /// Padding inside each key display.
  final EdgeInsetsGeometry? keyPadding;

  /// Shadow applied to key displays.
  final List<BoxShadow>? keyShadow;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KeyboardShortcutTheme &&
        other.spacing == spacing &&
        other.keyPadding == keyPadding &&
        listEquals(other.keyShadow, keyShadow);
  }

  @override
  int get hashCode => Object.hash(spacing, keyPadding, keyShadow);
}

class KeyboardShortcutDisplayHandle {
  const KeyboardShortcutDisplayHandle(this._builder);

  final KeyboardShortcutDisplayBuilder _builder;

  Widget buildKeyboardDisplay(BuildContext context, LogicalKeyboardKey key) {
    return _builder(context, key);
  }
}

class KeyboardShortcutDisplayMapper extends StatefulWidget {
  const KeyboardShortcutDisplayMapper({
    this.builder = _defaultBuilder,
    required this.child,
    super.key,
  });

  static Widget _defaultBuilder(BuildContext context, LogicalKeyboardKey key) {
    switch (key) {
      case LogicalKeyboardKey.control:
      case LogicalKeyboardKey.controlLeft:
      case LogicalKeyboardKey.controlRight:
        return const Text('Ctrl');

      case LogicalKeyboardKey.shift:
      case LogicalKeyboardKey.shiftLeft:
      case LogicalKeyboardKey.shiftRight:
        return const Text('Shift');

      case LogicalKeyboardKey.alt:
      case LogicalKeyboardKey.altLeft:
      case LogicalKeyboardKey.altRight:
        return const Text('Alt');

      case LogicalKeyboardKey.meta:
      case LogicalKeyboardKey.metaLeft:
      case LogicalKeyboardKey.metaRight:
        return const Text('⌘');

      case LogicalKeyboardKey.enter:
        return const Text('↵');

      case LogicalKeyboardKey.arrowLeft:
        return const Text('←');

      case LogicalKeyboardKey.arrowRight:
        return const Text('→');

      case LogicalKeyboardKey.arrowUp:
        return const Text('↑');

      case LogicalKeyboardKey.arrowDown:
        return const Text('↓');

      default:
        return Text(key.keyLabel);
    }
  }

  final KeyboardShortcutDisplayBuilder builder;

  final Widget child;

  @override
  State<KeyboardShortcutDisplayMapper> createState() =>
      _KeyboardShortcutDisplayMapperState();
}

class _KeyboardShortcutDisplayMapperState
    extends State<KeyboardShortcutDisplayMapper> {
  KeyboardShortcutDisplayHandle _handle;

  @override
  void initState() {
    super.initState();
    _handle = KeyboardShortcutDisplayHandle(widget.builder);
  }

  @override
  void didUpdateWidget(covariant KeyboardShortcutDisplayMapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builder != widget.builder) {
      _handle = KeyboardShortcutDisplayHandle(widget.builder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Data.inherit(data: _handle, child: widget.child);
  }
}

/// A widget that displays keyboard shortcuts in a visually appealing format.
///
/// Renders keyboard key combinations as styled keyboard key representations,
/// typically used in tooltips, help text, or UI elements that need to
/// communicate keyboard shortcuts to users. The display automatically
/// formats keys with appropriate spacing and visual styling.
///
/// Supports both direct key specification through a list of [LogicalKeyboardKey]
/// objects and automatic conversion from [ShortcutActivator] instances.
/// Keys are displayed as individual key representations with configurable
/// spacing between them.
///
/// The component integrates with the keyboard shortcut theming system
/// and adapts its appearance based on the current theme and scaling settings.
/// Visual styling matches platform conventions for keyboard key representations.
///
/// Example:
/// ```dart
/// KeyboardDisplay(
///   keys: [
///     LogicalKeyboardKey.controlLeft,
///     LogicalKeyboardKey.keyS,
///   ],
///   spacing: 4.0,
/// )
/// ```
class KeyboardDisplay extends StatelessWidget {
  /// Creates a [KeyboardDisplay] from a list of keyboard keys.
  ///
  /// Displays the specified keyboard keys as styled key representations
  /// with appropriate spacing. This constructor allows direct control
  /// over which keys are displayed.
  ///
  /// Parameters:
  /// - [keys] (List<LogicalKeyboardKey>, required): Keys to display
  /// - [spacing] (double?, optional): Gap between key displays
  ///
  /// Example:
  /// ```dart
  /// KeyboardDisplay(
  ///   keys: [LogicalKeyboardKey.alt, LogicalKeyboardKey.tab],
  ///   spacing: 6.0,
  /// )
  /// ```
  const KeyboardDisplay({
    super.key,
    required List<LogicalKeyboardKey> keys,
    this.spacing,
  }) : _keys = keys,
       _activator = null;

  /// Creates a [KeyboardDisplay] from a shortcut activator.
  ///
  /// Automatically extracts the keyboard keys from the provided
  /// [ShortcutActivator] and displays them as styled key representations.
  /// This constructor is convenient when working with Flutter's shortcut system.
  ///
  /// Parameters:
  /// - [activator] (ShortcutActivator, required): Shortcut to extract keys from
  /// - [spacing] (double?, optional): Gap between key displays
  ///
  /// Example:
  /// ```dart
  /// KeyboardDisplay.fromActivator(
  ///   activator: SingleActivator(LogicalKeyboardKey.keyS, control: true),
  ///   spacing: 4.0,
  /// )
  /// ```
  const KeyboardDisplay.fromActivator({
    required ShortcutActivator activator,
    super.key,
    this.spacing,
  }) : _keys = null,
       _activator = activator;

  /// List of keyboard keys to display when using direct key specification.
  final List<LogicalKeyboardKey>? _keys;

  /// Shortcut activator to convert to keyboard keys for display.
  final ShortcutActivator? _activator;

  /// Spacing between individual keyboard key displays.
  ///
  /// Controls the horizontal gap between adjacent key representations.
  /// When null, uses theme-appropriate default spacing.
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compTheme = ComponentTheme.maybeOf<KeyboardShortcutTheme>(context);
    final keys = _keys ?? shortcutActivatorToKeySet(_activator!);
    final spacing = styleValue(
      defaultValue: theme.scaling * 2,
      themeValue: compTheme?.spacing,
      widgetValue: this.spacing,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: keys
          .map((key) => KeyboardKeyDisplay(keyboardKey: key))
          .toList(),
    ).gap(spacing);
  }
}

/// A widget that displays a single keyboard key in a styled format.
///
/// Renders an individual keyboard key as a styled representation that
/// resembles a physical keyboard key. Used internally by [KeyboardDisplay]
/// but can also be used standalone for displaying individual keys.
///
/// The key display automatically formats the key label based on the
/// [LogicalKeyboardKey] and applies appropriate styling including
/// padding, shadows, and theme-consistent appearance.
///
/// Example:
/// ```dart
/// KeyboardKeyDisplay(
///   keyboardKey: LogicalKeyboardKey.controlLeft,
///   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
/// )
/// ```
class KeyboardKeyDisplay extends StatelessWidget {
  /// Creates a [KeyboardKeyDisplay] for the specified keyboard key.
  ///
  /// The [keyboardKey] parameter is required and determines which
  /// key is displayed. Visual appearance can be customized through
  /// the optional padding and shadow parameters.
  ///
  /// Parameters:
  /// - [keyboardKey] (LogicalKeyboardKey, required): Key to display
  /// - [padding] (EdgeInsetsGeometry?, optional): Internal padding
  /// - [boxShadow] (List<BoxShadow>?, optional): Shadow effects
  ///
  /// Example:
  /// ```dart
  /// KeyboardKeyDisplay(
  ///   keyboardKey: LogicalKeyboardKey.escape,
  ///   padding: EdgeInsets.all(6),
  /// )
  /// ```
  const KeyboardKeyDisplay({
    super.key,
    required this.keyboardKey,
    this.padding,
  });

  /// The keyboard key to display.
  ///
  /// Specifies which keyboard key should be rendered. The display
  /// automatically formats the key label and applies appropriate styling.
  final LogicalKeyboardKey keyboardKey;

  /// Internal padding applied within the key display.
  ///
  /// Controls spacing around the key label text. When null,
  /// uses theme-appropriate default padding for key displays.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final displayMapper = Data.of<KeyboardShortcutDisplayHandle>(context);
    final theme = Theme.of(context);
    final directionality = Directionality.of(context);
    final compTheme = ComponentTheme.maybeOf<KeyboardShortcutTheme>(context);
    final padding =
        styleValue(
          defaultValue: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          themeValue: compTheme?.keyPadding,
          widgetValue: this.padding,
        ).resolve(directionality) *
        theme.scaling;

    return Card(
      borderRadius: theme.borderRadiusMd,
      fillColor: theme.colorScheme.background.scaleAlpha(0.7),
      filled: true,
      padding: padding,
      child: displayMapper.buildKeyboardDisplay(context, keyboardKey),
    );
  }
}

List<LogicalKeyboardKey> shortcutActivatorToKeySet(
  ShortcutActivator activator,
) {
  final keys = <LogicalKeyboardKey>[];
  if (activator is CharacterActivator) {
    if (activator.control) {
      keys.add(LogicalKeyboardKey.control);
    }
    if (activator.alt) {
      keys.add(LogicalKeyboardKey.alt);
    }
    if (activator.meta) {
      keys.add(LogicalKeyboardKey.meta);
    }
    keys.add(LogicalKeyboardKey(activator.character.codeUnitAt(0)));
  }
  if (activator is SingleActivator) {
    if (activator.control) {
      keys.add(LogicalKeyboardKey.control);
    }
    if (activator.alt) {
      keys.add(LogicalKeyboardKey.alt);
    }
    if (activator.meta) {
      keys.add(LogicalKeyboardKey.meta);
    }
    if (activator.shift) {
      keys.add(LogicalKeyboardKey.shift);
    }
    keys.add(activator.trigger);
  }
  if (activator is LogicalKeySet) {
    for (final trigger in activator.triggers) {
      keys.add(trigger);
    }
  }

  return keys;
}
