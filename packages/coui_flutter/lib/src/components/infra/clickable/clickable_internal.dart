import 'package:flutter/foundation.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Convenience boolean getters over a [WidgetState] set.
extension WidgetStateExtension on Set<WidgetState> {
  /// Whether the set contains [WidgetState.disabled].
  bool get disabled => contains(WidgetState.disabled);

  /// Whether the set contains [WidgetState.hovered].
  bool get hovered => contains(WidgetState.hovered);

  /// Whether the set contains [WidgetState.focused].
  bool get focused => contains(WidgetState.focused);
}

/// Ambient widget-state set shared down the tree via `Data.inherit` (e.g.
/// a button group publishing its state to descendant buttons).
class WidgetStatesData {
  const WidgetStatesData(this.states);

  final Set<WidgetState> states;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WidgetStatesData && setEquals(states, other.states);
  }

  @override
  String toString() => 'WidgetStatesData(states: $states)';

  @override
  int get hashCode => states.hashCode;
}
