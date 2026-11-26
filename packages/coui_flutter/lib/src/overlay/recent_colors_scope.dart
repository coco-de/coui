/// Flutter binding for the unified recent-colors history scope.
///
/// Mirrors the Web `RecentColorsScope` (`packages/coui_web/lib/src/
/// overlay/recent_colors_scope.dart`) 1:1 — same constructor
/// parameters (`initialRecentColors` / `maxRecentColors` /
/// `onRecentColorsChanged`), same imperative surface
/// (`addHistory` / `setHistory` / `clear`), same observation
/// pattern (`addListener` / `removeListener`).
///
/// `ColorPicker` (Flutter) looks the storage up via
/// `RecentColorsScope.maybeOf(context)` and pushes / reads the
/// user's recent picks; the host application installs one near the
/// top of the tree (typically through `CoUIApp.initialRecentColors`).
///
/// Replaces the legacy `RecentColorsScope` in
/// `components/form/color_picker/color_picker.dart` (`Color` /
/// `Listenable` based) with a `CoreColor` / `CoreListenable` based
/// flavor that shares the cross-platform contract.
library;

import 'package:coui_core/coui_core.dart';
import 'package:flutter/widgets.dart';

/// Default cap when the host doesn't override. Matches Web
/// `RecentColorsScope` so cross-platform demos / persistence stays
/// in lockstep.
const int _kDefaultMaxRecentColors = 10;

/// Recent-color history scope. Wrap the application tree so any
/// descendant `ColorPicker` can persist / read the user's recent
/// picks.
///
/// Usually installed by `CoUIApp` so app authors only configure the
/// initial colors / cap — manual scope wrapping is rarely needed.
class RecentColorsScope extends StatefulWidget {
  /// Creates a scope.
  const RecentColorsScope({
    required this.child,
    super.key,
    this.initialRecentColors = const [],
    this.maxRecentColors = _kDefaultMaxRecentColors,
    this.onRecentColorsChanged,
  });

  /// Returns the nearest [CoreColorHistoryStorage] in the ancestor
  /// chain, or `null` if no scope is wrapped above [context].
  static CoreColorHistoryStorage? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_RecentColorsInherited>()
        ?.storage;
  }

  /// The application subtree.
  final Widget child;

  /// Initial history (most-recent-first). Applied once at mount.
  final List<CoreColor> initialRecentColors;

  /// Maximum retained entries.
  final int maxRecentColors;

  /// Fired whenever the history mutates so the host app can persist
  /// it (e.g. write to local storage).
  final void Function(List<CoreColor> colors)? onRecentColorsChanged;

  @override
  State<RecentColorsScope> createState() => _RecentColorsScopeState();
}

class _RecentColorsScopeState extends State<RecentColorsScope> {
  late _RecentColorsStorage _storage;

  @override
  void initState() {
    super.initState();
    _storage = _RecentColorsStorage(
      onChanged: widget.onRecentColorsChanged,
      capacity: widget.maxRecentColors,
      colors: List.of(widget.initialRecentColors),
    );
  }

  @override
  void didUpdateWidget(covariant RecentColorsScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxRecentColors != widget.maxRecentColors) {
      _storage.capacity = widget.maxRecentColors;
    }
    if (oldWidget.onRecentColorsChanged != widget.onRecentColorsChanged) {
      _storage.onChanged = widget.onRecentColorsChanged;
    }
  }

  @override
  void dispose() {
    _storage.disposeListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RecentColorsInherited(
      storage: _storage,
      child: widget.child,
    );
  }
}

class _RecentColorsInherited extends InheritedWidget {
  const _RecentColorsInherited({
    required this.storage,
    required super.child,
  });

  final CoreColorHistoryStorage storage;

  @override
  bool updateShouldNotify(covariant _RecentColorsInherited oldWidget) {
    return storage != oldWidget.storage;
  }
}

class _RecentColorsStorage implements CoreColorHistoryStorage {
  _RecentColorsStorage({
    required this.capacity,
    required List<CoreColor> colors,
    this.onChanged,
  }) : _colors = List.of(colors);

  @override
  int capacity;

  /// Notification callback — set by the owning State on mount /
  /// `didUpdateWidget`.
  void Function(List<CoreColor> colors)? onChanged;

  List<CoreColor> _colors;

  /// Listener bag — copy-on-write so dispatch can iterate a snapshot
  /// while a listener calls `removeListener`.
  List<void Function()> _listeners = const [];
  bool _disposed = false;

  @override
  List<CoreColor> get recentColors => .unmodifiable(_colors);

  @override
  void addHistory(CoreColor color) {
    if (_disposed) return;
    final next = _colors.where((c) => c != color).toList();
    next.insert(0, color);
    if (next.length > capacity) {
      _colors = next.sublist(0, capacity);
    } else {
      _colors = next;
    }
    onChanged?.call(_colors);
    _notify();
  }

  @override
  void setHistory(List<CoreColor> colors) {
    if (_disposed) return;
    _colors = List.of(colors);
    onChanged?.call(_colors);
    _notify();
  }

  @override
  void clear() {
    if (_disposed) return;
    _colors = const [];
    onChanged?.call(_colors);
    _notify();
  }

  @override
  void addListener(void Function() listener) {
    if (_disposed) return;
    _listeners = [..._listeners, listener];
  }

  @override
  void removeListener(void Function() listener) {
    if (_disposed) return;
    _listeners = _listeners.where((entry) => entry != listener).toList();
  }

  /// Detach all listeners — called by owning State on dispose.
  void disposeListeners() {
    _disposed = true;
    _listeners = const [];
  }

  void _notify() {
    final snapshot = List.of(_listeners);
    for (final listener in snapshot) {
      listener();
    }
  }
}
