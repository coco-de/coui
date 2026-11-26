/// Web binding for the unified recent-colors history scope.
///
/// Mirrors Flutter `RecentColorsScope` 1:1 — same constructor
/// parameters (`initialRecentColors` / `maxRecentColors` /
/// `onRecentColorsChanged`), same imperative surface
/// (`addHistory` / `setHistory` / `clear`), same observation
/// pattern (`addListener` / `removeListener`).
///
/// `ColorPicker` (Web) looks the storage up via
/// `RecentColorsScope.maybeOf(context)` and pushes / reads the user's
/// recent picks; the host application installs one near the top of
/// the tree (typically through `CoUIWeb.initialRecentColors`).
library;

import 'package:coui_core/coui_core.dart';
import 'package:jaspr/jaspr.dart';

/// Default cap when the host doesn't override. Matches Flutter
/// `_kMaxRecentColors`.
const int _kDefaultMaxRecentColors = 10;

/// Recent-color history scope. Wrap the application tree so any
/// descendant `ColorPicker` can persist / read the user's recent
/// picks.
///
/// Usually installed by `CoUIWeb` so app authors only configure the
/// initial colors / cap — manual scope wrapping is rarely needed.
class RecentColorsScope extends StatefulComponent {
  /// Creates a scope.
  const RecentColorsScope({
    required this.child,
    super.key,
    this.initialRecentColors = const [],
    this.maxRecentColors = _kDefaultMaxRecentColors,
    this.onRecentColorsChanged,
  });

  /// The application subtree.
  final Component child;

  /// Initial history (most-recent-first). Applied once at mount.
  final List<CoreColor> initialRecentColors;

  /// Maximum retained entries.
  final int maxRecentColors;

  /// Fired whenever the history mutates so the host app can persist
  /// it (e.g. write to local storage).
  final void Function(List<CoreColor> colors)? onRecentColorsChanged;

  /// Returns the nearest [RecentColorsScopeStorage] in the ancestor
  /// chain, or `null` if no scope is wrapped above [context].
  static CoreColorHistoryStorage? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<_RecentColorsInherited>()
        ?.storage;
  }

  @override
  State<RecentColorsScope> createState() => _RecentColorsScopeState();
}

class _RecentColorsScopeState extends State<RecentColorsScope> {
  late _RecentColorsStorage _storage;

  @override
  void initState() {
    super.initState();
    _storage = _RecentColorsStorage(
      onChanged: component.onRecentColorsChanged,
      capacity: component.maxRecentColors,
      colors: List.of(component.initialRecentColors),
    );
  }

  @override
  void didUpdateComponent(covariant RecentColorsScope oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.maxRecentColors != component.maxRecentColors) {
      _storage.capacity = component.maxRecentColors;
    }
    if (oldComponent.onRecentColorsChanged != component.onRecentColorsChanged) {
      _storage.onChanged = component.onRecentColorsChanged;
    }
  }

  @override
  void dispose() {
    _storage.disposeListeners();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return _RecentColorsInherited(
      storage: _storage,
      child: component.child,
    );
  }
}

class _RecentColorsInherited extends InheritedComponent {
  const _RecentColorsInherited({
    required this.storage,
    required super.child,
  });

  final CoreColorHistoryStorage storage;

  @override
  bool updateShouldNotify(covariant _RecentColorsInherited oldComponent) {
    return storage != oldComponent.storage;
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
  /// `didUpdateComponent`.
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
