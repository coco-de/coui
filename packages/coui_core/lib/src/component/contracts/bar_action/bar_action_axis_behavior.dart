/// The axes a bar action may be laid out along.
library;

import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';

/// Where a bar's action may stand when the bar's actions move to a column.
///
/// A screen that reserves a strip at its side for bar controls draws the
/// bar's icon actions there, in a column, and leaves the actions that need
/// a row's width — a text button — in the bar. An action says which of the
/// two it is with this value.
enum CoreBarActionAxisBehavior {
  /// The action goes where the bar's actions go: in the bar's row, or in
  /// the column when they stand there. What an icon button is.
  automatic,

  /// The action stays in the bar's row and is never drawn in a column —
  /// a text button, or any control wider than one glyph.
  horizontalOnly;

  /// Whether an action with this behaviour may be laid out along [axis].
  bool allows(CoreAxis axis) => switch (this) {
    automatic => true,
    horizontalOnly => axis == CoreAxis.horizontal,
  };
}
