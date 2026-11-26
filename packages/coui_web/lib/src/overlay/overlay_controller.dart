/// Imperative controller for [OverlayHost] / [OverlayPortal].
///
/// Stores the live overlay entries grouped by [CoreOverlayLayer]
/// (popover / tooltip / menu) and notifies listeners on mount /
/// unmount / update so the host re-renders. Mirrors Flutter's
/// `OverlayManagerLayer` slot model — three independent layers, each
/// carrying its own ordered list of entries.
library;

import 'package:coui_core/coui_core.dart';
import 'package:jaspr/jaspr.dart';

/// Web binding for [CoreOverlayHandler] — manages the entries
/// rendered inside the root [OverlayHost]. Floating components
/// (Popover / Tooltip / DropdownMenu / HoverCard) call
/// `mount(layer: ..., panel: ...)` to portal their panel up to the
/// root overlay layer instead of rendering inline as a sibling of
/// the trigger.
class OverlayController implements CoreOverlayHandler<Component, int> {
  /// Creates a controller. The owning [OverlayHost] subscribes via
  /// [addListener] / [removeListener] in its `initState` / `dispose`
  /// to schedule re-renders when entries change.
  OverlayController();

  /// Per-layer entry maps — token → panel. Stored as `Map<int,
  /// Component>` (immutable copy-on-write semantics) so listener
  /// callbacks see a stable snapshot during dispatch and the
  /// `avoid-collection-mutating-methods` lint stays satisfied.
  Map<int, Component> _popovers = const {};
  Map<int, Component> _tooltips = const {};
  Map<int, Component> _menus = const {};
  Map<int, Component> _dialogs = const {};

  /// Tokens of the entries that asked for modality.
  ///
  /// A set rather than a counter: overlays can stack (a dialog opening
  /// a confirm dialog), and a counter that a double-unmount decrements
  /// twice would leave the page permanently inert. Membership is
  /// idempotent.
  Set<int> _modalTokens = const {};

  /// Process-level token counter. Tokens are unique across all
  /// layers so callers can hold a single `int` and the controller
  /// knows where to look up by walking the maps.
  int _nextToken = 0;

  /// Listener bag — owning host subscribes to schedule a re-render
  /// when entries change.
  List<void Function()> _listeners = const [];
  bool _disposed = false;

  /// Snapshot of entries on the popover layer in insertion order.
  Iterable<Component> get popoverEntries => _popovers.values;

  /// Snapshot of entries on the tooltip layer in insertion order.
  Iterable<Component> get tooltipEntries => _tooltips.values;

  /// Snapshot of entries on the menu layer in insertion order.
  Iterable<Component> get menuEntries => _menus.values;

  /// Snapshot of entries on the dialog layer in insertion order.
  Iterable<Component> get dialogEntries => _dialogs.values;

  /// Whether any open entry asked for the background to be inert.
  bool get hasModalEntry => _modalTokens.isNotEmpty;

  @override
  int mount({
    required CoreOverlayLayer layer,
    required Component panel,
    bool modal = false,
  }) {
    if (_disposed) return -1;
    final token = _nextToken++;
    _writeLayer(layer, token, panel);
    if (modal) _modalTokens = {..._modalTokens, token};
    _notify();
    return token;
  }

  @override
  void update(int token, Component panel) {
    if (_disposed) return;
    final layer = _layerOf(token);
    if (layer == null) return;
    _writeLayer(layer, token, panel);
    _notify();
  }

  @override
  void unmount(int token) {
    if (_disposed) return;
    if (_popovers.containsKey(token)) {
      _popovers = {..._popovers}..remove(token);
    } else if (_tooltips.containsKey(token)) {
      _tooltips = {..._tooltips}..remove(token);
    } else if (_menus.containsKey(token)) {
      _menus = {..._menus}..remove(token);
    } else if (_dialogs.containsKey(token)) {
      _dialogs = {..._dialogs}..remove(token);
    } else {
      return;
    }
    if (_modalTokens.contains(token)) {
      _modalTokens = {..._modalTokens}..remove(token);
    }
    _notify();
  }

  /// Subscribe to mount / unmount transitions. Owning [OverlayHost]
  /// State registers a listener that calls `setState`.
  void addListener(void Function() listener) {
    if (_disposed) return;
    _listeners = [..._listeners, listener];
  }

  /// Remove a previously registered listener.
  void removeListener(void Function() listener) {
    if (_disposed) return;
    _listeners = _listeners.where((entry) => entry != listener).toList();
  }

  /// Detach all listeners and clear entries. Called by the owning
  /// [OverlayHost] State on dispose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _popovers = const {};
    _tooltips = const {};
    _menus = const {};
    _dialogs = const {};
    _listeners = const [];
  }

  // ─── internals ───────────────────────────────────────────────

  void _writeLayer(CoreOverlayLayer layer, int token, Component panel) {
    switch (layer) {
      case .popover:
        _popovers = {..._popovers, token: panel};
      case .tooltip:
        _tooltips = {..._tooltips, token: panel};
      case .menu:
        _menus = {..._menus, token: panel};
      case .dialog:
        _dialogs = {..._dialogs, token: panel};
    }
  }

  CoreOverlayLayer? _layerOf(int token) {
    if (_popovers.containsKey(token)) return .popover;
    if (_tooltips.containsKey(token)) return .tooltip;
    if (_menus.containsKey(token)) return .menu;
    if (_dialogs.containsKey(token)) return .dialog;
    return null;
  }

  void _notify() {
    final snapshot = List.of(_listeners);
    for (final listener in snapshot) {
      listener();
    }
  }
}
