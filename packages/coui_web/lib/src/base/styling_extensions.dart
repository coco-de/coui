import 'package:coui_web/src/base/styling.dart';

/// Extension methods for working with CoUI UI utility groups.
extension CoUiStylingIterableExt on Iterable<Styling> {
  /// Converts an iterable of [Styling] instances (general utilities like
  /// Spacing, Layout, TextUtil) into a single, space-separated string of CSS
  /// class names.
  ///
  /// This is useful for applying general CoUI utility modifiers to standard
  /// Jaspr
  /// DOM components that accept a `classes` string.
  ///
  /// Example:
  /// ```dart
  /// import 'package:coui_web/coui_web.dart';
  ///
  /// final utilities = [Spacing.mt(4), TextUtil.center];
  /// div(classes: utilities.toClasses(), [text('Hello')]);
  /// ```
  ///
  /// **Note:** This extension is intended for general utilities
  /// (`UtilityGroup`)
  /// and not for component-specific modifiers (like `Button.primary`).
  /// Component-specific modifiers should be passed to the `modifiers` property
  /// of CoUI components.
  String toClasses() {
    return map(
      (utility) => utility.asClass(),
    ).where((className) => className.isNotEmpty).join(' ');
  }
}

// Extension for a nullable iterable
extension CoUiNullableStylingIterableExt on Iterable<Styling>? {
  /// Converts an iterable of [Styling] instances into a single,
  /// space-separated string of CSS class names.
  /// Returns an empty string if the iterable is null or empty.
  String toClasses() {
    return (this ?? const <Styling>[])
        .map((utility) => utility.asClass())
        .where((className) => className.isNotEmpty)
        .join(' ');
  }
}

/// Extension methods for a single CoUI UI utility class.
extension CoUiStylingExtensions on Styling {
  /// Converts a single [Styling] instance into its CSS class string.
  ///
  /// While `toString()` already does this, this extension provides a more
  /// explicit method name if preferred for clarity in certain contexts,
  /// especially when dealing with potentially nullable utilities.
  ///
  /// Example:
  /// ```dart
  /// final utility = Spacing.mt(4);
  /// div(classes: utility.asClass(), [text('Hello')]);
  /// ```
  String asClass() {
    return toString();
  }
}
