import 'package:coui_web/src/base/styling.dart';

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
