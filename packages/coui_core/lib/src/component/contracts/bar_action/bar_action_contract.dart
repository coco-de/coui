/// Platform-independent contract for the bar action marker.
///
/// `BarAction` wraps one action of a bar and states the axes it may be
/// laid out along. The containers that lay actions out — `AppBar`, and a
/// `ToolbarGroup` standing them in a column — read it; on its own it draws
/// its [CoreBarActionContract.child] and nothing else, so the contract has
/// no `Style` slot.
library;

import 'package:coui_core/src/component/contracts/bar_action/bar_action_axis_behavior.dart';

/// Contract for an action that states where it may be laid out.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
abstract interface class CoreBarActionContract<W> {
  /// What an action no `BarAction` wraps answers: it goes where the bar's
  /// actions go.
  ///
  /// The kit cannot tell an icon button from a text button — an action is
  /// any widget — so the one that must stay in the bar is the one that
  /// says so.
  static const CoreBarActionAxisBehavior unmarkedAxisBehavior =
      CoreBarActionAxisBehavior.automatic;

  /// The action.
  W get child;

  /// The axes the action may be laid out along.
  CoreBarActionAxisBehavior get axisBehavior;
}
