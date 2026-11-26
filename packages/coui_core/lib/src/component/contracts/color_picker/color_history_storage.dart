/// Cross-platform color-history storage contract for `ColorPicker`.
///
/// Mirrors Flutter `ColorHistoryStorage` so the CoUI Web binding
/// (`RecentColorsScope` / `CoUIWeb.initialRecentColors`) and the
/// Flutter binding share a single interface — color pickers consume
/// only the contract via `OverlayPortal` / `Data.of` lookup.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/listenable.dart';

/// Recent-color history persisted across `ColorPicker` instances.
///
/// Implementations on Flutter (Stateful + ChangeNotifier) and Web
/// (OverlayHost-installed scope) hold the user's recently-picked
/// colors and notify listeners on every change so palette UIs
/// rebuild.
abstract interface class CoreColorHistoryStorage implements CoreListenable {
  /// Pushes [color] to the front of history. Existing entry for the
  /// same color is removed first so the most recently-used color
  /// always sits at index 0.
  void addHistory(CoreColor color);

  /// Replaces the entire history with [colors]. Used when restoring
  /// from persistence layer.
  void setHistory(List<CoreColor> colors);

  /// Empties history.
  void clear();

  /// Maximum retained entries. Mirrors Flutter `RecentColorsScope.
  /// maxRecentColors`.
  int get capacity;

  /// Current ordered history (most-recent-first), unmodifiable.
  List<CoreColor> get recentColors;
}
