/// Singleton registry that enforces at most one open floating panel.
///
/// When a new [OverlayPositionEntry] opens, any previously active entry
/// is closed. This mirrors the Flutter `OverlayManager` single-popover
/// semantics and avoids visually overlapping drop-downs.
library;

/// An object that can be closed by [OverlayPositionRegistry] when another entry
/// requests the exclusive open slot.
abstract interface class OverlayPositionEntry {
  /// Invoked by the registry when this entry should yield its open slot.
  void requestClose();
}

/// Global registry holding the currently-open floating entry.
///
/// Keeping this at package scope (rather than per [OverlayPositionEntry])
/// guarantees no two Form popovers are visually open at the same time,
/// regardless of which consumer opened them.
abstract final class OverlayPositionRegistry {
  static OverlayPositionEntry? _active;

  /// Registers [entry] as the currently open floating panel and, if a
  /// different entry was already open, asks it to close first.
  static void open(OverlayPositionEntry entry) {
    final previous = _active;
    if (identical(previous, entry)) return;
    _active = entry;
    previous?.requestClose();
  }

  /// Clears [entry] from the active slot if it currently holds it.
  ///
  /// Safe to call even if [entry] is not the active one.
  static void close(OverlayPositionEntry entry) {
    if (identical(_active, entry)) {
      _active = null;
    }
  }

  /// Whether any entry is currently open.
  static bool get hasActive => _active != null;

  /// Test-only hook that clears the active entry without invoking
  /// [OverlayPositionEntry.requestClose]. Do not use in production code.
  static void debugReset() {
    _active = null;
  }
}
