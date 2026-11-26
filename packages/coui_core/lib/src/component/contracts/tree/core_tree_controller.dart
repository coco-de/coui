/// Listener type for [CoreTreeController.startRename] requests.
typedef CoreTreeRenameRequestListener = void Function(String nodeId);

/// Cross-platform commands for a `Tree` that its props cannot express.
///
/// A tree whose keyboard model lives outside its rows — an IDE explorer whose
/// own focus moves a cursor and never focuses a row — cannot reach the
/// row-level F2 shortcut, and the rename state lives inside the tree. It asks
/// the tree through this controller instead. Flutter and Web `Tree` subscribe
/// identically; like `CoreDraggablePanelController` it is a minimal,
/// `dart:ui`-free notifier.
class CoreTreeController {
  List<CoreTreeRenameRequestListener> _renameListeners =
      const <CoreTreeRenameRequestListener>[];

  /// Opens the inline rename field on the visible node whose `id` is
  /// [nodeId] — exactly what a double-click or F2 on that row does, focus
  /// hand-back included.
  ///
  /// Ignored when the tree has no `onNodeRename`, `canRenameNode` refuses
  /// the node, or no visible row carries [nodeId] (an unknown id, or a
  /// collapsed ancestor).
  void startRename(String nodeId) {
    for (final listener in _renameListeners) {
      listener(nodeId);
    }
  }

  /// Registers a tree to receive [startRename] requests.
  void addRenameListener(CoreTreeRenameRequestListener listener) {
    _renameListeners = [..._renameListeners, listener];
  }

  /// Removes a listener added with [addRenameListener].
  void removeRenameListener(CoreTreeRenameRequestListener listener) {
    _renameListeners = _renameListeners.where((l) => l != listener).toList();
  }

  /// Releases all listeners.
  void dispose() {
    _renameListeners = const <CoreTreeRenameRequestListener>[];
  }
}
