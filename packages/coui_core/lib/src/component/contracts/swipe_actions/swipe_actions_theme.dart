/// Theme data for `SwipeActions` customisation.
library;

import 'package:coui_core/src/component/contracts/swipe_actions/swipe_actions_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `SwipeActions`.
///
/// Exposes a single `{ style: CoreSwipeActionsStyle? }` slot that
/// participates in the merge chain:
///
/// ```text
/// design system default
///   → CoreSwipeActionsTheme.style
///   → widget per-instance swipeActionsStyle
/// ```
///
/// There is no per-variant slot: a row's actions come in different variants
/// (`CoreSwipeActionVariant`), but each is drawn by the `Button` of that
/// variant, so a project restyles a destructive action through the button's
/// own theme, not here.
@immutable
class CoreSwipeActionsTheme {
  /// Creates a [CoreSwipeActionsTheme].
  const CoreSwipeActionsTheme({this.style});

  /// Project-wide style applied to every `SwipeActions`.
  final CoreSwipeActionsStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSwipeActionsTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
