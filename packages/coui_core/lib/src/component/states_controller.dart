import 'package:coui_core/src/component/component_state.dart';

/// Platform-independent callback for state changes.
typedef CoreStateChangeCallback = void Function(Set<CoreComponentState> states);

/// Platform-independent controller for component interaction states.
///
/// Tracks hover, focus, pressed, disabled, and loading states.
/// Flutter maps to `WidgetStatesController`, Web maps to CSS class toggles.
abstract interface class CoreStatesController {
  /// The current set of active states.
  Set<CoreComponentState> get states;

  /// Updates the state set.
  set states(Set<CoreComponentState> value);

  /// Adds a listener for state changes.
  void addListener(CoreStateChangeCallback listener);

  /// Removes a state change listener.
  void removeListener(CoreStateChangeCallback listener);

  /// Releases resources.
  void dispose();
}
