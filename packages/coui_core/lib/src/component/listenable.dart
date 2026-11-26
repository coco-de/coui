/// Cross-platform `Listenable` contract — addListener / removeListener
/// pair without depending on Flutter's `package:flutter/foundation.dart`
/// `Listenable`. Lets observable contracts (`CoreColorHistoryStorage`,
/// future controllers) live in `coui_core` and be implemented by both
/// the Flutter `ChangeNotifier`-backed binding and the Web binding.
library;

/// Anything that fires `void` callbacks when its state changes.
///
/// Flutter implementations typically extend `ChangeNotifier` (which
/// already satisfies this surface). Web implementations keep an
/// internal listener bag (immutable copy-on-write) and call back on
/// every state change.
abstract interface class CoreListenable {
  /// Subscribes [listener] to change events.
  void addListener(void Function() listener);

  /// Unsubscribes a previously registered [listener].
  void removeListener(void Function() listener);
}
