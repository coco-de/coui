import 'dart:async';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/roving_focus.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/form/file_input/file_input_dom.dart';
import 'package:coui_web/src/components/layout/tree/tree_style.dart';
import 'package:universal_web/web.dart' as web;

int _coTreeScopeCounter = 0;

/// Cursor for a display-only row. `Clickable` shows the pointer whenever it
/// is enabled, but a row with nothing to do on press is content — it takes
/// focus so a keyboard can read it, not so a pointer can act on it. Inline,
/// because a competing `cursor-*` class would lose to Clickable's by
/// stylesheet order. Not a design token.
const Styles _kDisplayOnlyRowCursor = Styles(cursor: Cursor.defaultCursor);

/// A row's context-menu wrapper stays a full-width block. The menu's own root
/// is `relative inline-block` (it hosts a free-standing region), which would
/// shrink the row to its content and add an inline line box under it; an
/// inline style, because a competing `block` class would lose by stylesheet
/// order. Not a design token.
const Styles _kRowContextMenuBox = Styles(
  display: Display.block,
  width: Unit.percent(100),
);

/// Leading or trailing content for a node, supplied by the consumer.
typedef TreeNodeBuilder =
    Component Function(
      BuildContext context,
      CoreTreeNode node, {
      required bool expanded,
    });

/// Content shown when a lazy child load fails.
typedef TreeLoadErrorBuilder =
    Component Function(BuildContext context, CoreTreeNode node, Object error);

/// Unified tree component for Web.
///
/// Displays a hierarchical tree structure with
/// expandable/collapsible nodes.
///
/// ```dart
/// Tree(
///   nodes: [
///     CoreTreeNode(label: 'Documents', children: [
///       CoreTreeNode(label: 'Resume.pdf'),
///     ]),
///   ],
///   onNodeSelect: (node) => print(node.label),
/// )
/// ```
class Tree extends UiStatefulComponent
    implements
        CoreTreeContract<Component>,
        CoreTreeFilesDropContract<web.FileList>,
        CoreTreeContextMenuContract<Component> {
  /// Creates a [Tree].
  const Tree({
    required this.nodes,
    this.showRoots = true,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.onNodeSelect,
    this.onNodeToggle,
    this.onNodeRename,
    this.canRenameNode,
    this.controller,
    this.nodeContextMenu,
    this.selectFolders = false,
    this.toggleFoldersOnSelect = false,
    this.expansionControlled = false,
    this.loadChildren,
    this.leadingBuilder,
    this.trailingBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.virtualRowHeight,
    this.virtualViewportHeight,
    this.nodeKeyPrefix,
    this.selectedId,
    this.onNodeDrop,
    this.canDrop,
    this.onFilesDroppedOnNode,
    this.onNodePlace,
    this.canPlace,
    this.canDragNode,
    this.onFilesPlaced,
    this.treeStyle,
  }) : assert(
         (virtualRowHeight == null) == (virtualViewportHeight == null),
         'Both virtual heights must be supplied together.',
       ),
       assert(
         virtualRowHeight == null || virtualRowHeight > 0,
         'The virtual row height must be positive.',
       ),
       assert(
         virtualViewportHeight == null || virtualViewportHeight > 0,
         'The virtual viewport height must be positive.',
       );

  @override
  final List<CoreTreeNode> nodes;

  @override
  final bool showRoots;

  @override
  final ValueChanged<CoreTreeNode>? onNodeSelect;

  @override
  final ValueChanged<CoreTreeNode>? onNodeToggle;

  /// Opt-in inline rename — double-click or F2 on the focused row.
  @override
  final CoreTreeRenameCallback? onNodeRename;

  @override
  final CoreTreeRenamePredicate? canRenameNode;

  /// Opens a row's rename field from outside the tree — for a consumer
  /// whose keyboard model lives outside the rows.
  @override
  final CoreTreeController? controller;

  /// Entries for a row's right-click menu (long-press on touch) — shown at
  /// the pointer with [ContextMenu].
  @override
  final CoreTreeNodeMenuBuilder<Component>? nodeContextMenu;

  @override
  final bool selectFolders;

  @override
  final bool toggleFoldersOnSelect;

  @override
  final bool expansionControlled;

  @override
  final Future<List<CoreTreeNode>> Function(CoreTreeNode node)? loadChildren;

  /// Overrides the folder/file glyph with content aware of expansion.
  @override
  final TreeNodeBuilder? leadingBuilder;

  /// Adds content after the node label.
  @override
  final TreeNodeBuilder? trailingBuilder;

  /// Supplies the loading row for a branch with unloaded children.
  @override
  final Component Function(BuildContext context, CoreTreeNode node)?
  loadingBuilder;

  /// Supplies the retryable error row for a failed child load.
  @override
  final TreeLoadErrorBuilder? errorBuilder;

  @override
  final double? virtualRowHeight;

  @override
  final double? virtualViewportHeight;

  @override
  final String? nodeKeyPrefix;

  @override
  final String? selectedId;

  @override
  final CoreTreeDropCallback? onNodeDrop;

  @override
  final CoreTreeDropPredicate? canDrop;

  /// Opt-in before/after/inside placement with a Sortable-style preview.
  @override
  final CoreTreePlaceCallback? onNodePlace;

  /// Additional consumer policy for exact placements.
  @override
  final CoreTreePlacePredicate? canPlace;

  /// Keeps non-movable nodes such as a synthetic root as drop targets.
  @override
  final CoreTreeDragPredicate? canDragNode;

  /// Browser files placed at an exact position between or inside rows.
  @override
  final CoreTreeFilesPlaceCallback<web.FileList>? onFilesPlaced;

  /// Receives browser files at the directory indicated by the hovered row.
  @override
  final CoreTreeFilesDropCallback<web.FileList>? onFilesDroppedOnNode;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `nodeTextStyle` / `chevronIconStyle` slots. See [CoreTreeStyle]
  /// for the merge chain.
  @override
  final CoreTreeStyle? treeStyle;

  /// Returns a copy of this [Tree] with the given fields replaced.
  Tree copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    List<CoreTreeNode>? nodes,
    bool? showRoots,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    ValueChanged<CoreTreeNode>? onNodeSelect,
    ValueChanged<CoreTreeNode>? onNodeToggle,
    CoreTreeRenameCallback? onNodeRename,
    CoreTreeRenamePredicate? canRenameNode,
    CoreTreeController? controller,
    CoreTreeNodeMenuBuilder<Component>? nodeContextMenu,
    bool? selectFolders,
    bool? toggleFoldersOnSelect,
    bool? expansionControlled,
    Future<List<CoreTreeNode>> Function(CoreTreeNode node)? loadChildren,
    TreeNodeBuilder? leadingBuilder,
    TreeNodeBuilder? trailingBuilder,
    Component Function(BuildContext context, CoreTreeNode node)? loadingBuilder,
    TreeLoadErrorBuilder? errorBuilder,
    double? virtualRowHeight,
    double? virtualViewportHeight,
    String? nodeKeyPrefix,
    String? selectedId,
    CoreTreeDropCallback? onNodeDrop,
    CoreTreeDropPredicate? canDrop,
    CoreTreePlaceCallback? onNodePlace,
    CoreTreePlacePredicate? canPlace,
    CoreTreeDragPredicate? canDragNode,
    CoreTreeFilesDropCallback<web.FileList>? onFilesDroppedOnNode,
    CoreTreeFilesPlaceCallback<web.FileList>? onFilesPlaced,
    CoreTreeStyle? treeStyle,
  }) {
    return Tree(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      nodes: nodes ?? this.nodes,
      showRoots: showRoots ?? this.showRoots,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      onNodeSelect: onNodeSelect ?? this.onNodeSelect,
      onNodeToggle: onNodeToggle ?? this.onNodeToggle,
      onNodeRename: onNodeRename ?? this.onNodeRename,
      canRenameNode: canRenameNode ?? this.canRenameNode,
      controller: controller ?? this.controller,
      nodeContextMenu: nodeContextMenu ?? this.nodeContextMenu,
      selectFolders: selectFolders ?? this.selectFolders,
      toggleFoldersOnSelect:
          toggleFoldersOnSelect ?? this.toggleFoldersOnSelect,
      expansionControlled: expansionControlled ?? this.expansionControlled,
      loadChildren: loadChildren ?? this.loadChildren,
      leadingBuilder: leadingBuilder ?? this.leadingBuilder,
      trailingBuilder: trailingBuilder ?? this.trailingBuilder,
      loadingBuilder: loadingBuilder ?? this.loadingBuilder,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      virtualRowHeight: virtualRowHeight ?? this.virtualRowHeight,
      virtualViewportHeight:
          virtualViewportHeight ?? this.virtualViewportHeight,
      nodeKeyPrefix: nodeKeyPrefix ?? this.nodeKeyPrefix,
      selectedId: selectedId ?? this.selectedId,
      onNodeDrop: onNodeDrop ?? this.onNodeDrop,
      canDrop: canDrop ?? this.canDrop,
      onNodePlace: onNodePlace ?? this.onNodePlace,
      canPlace: canPlace ?? this.canPlace,
      canDragNode: canDragNode ?? this.canDragNode,
      onFilesDroppedOnNode: onFilesDroppedOnNode ?? this.onFilesDroppedOnNode,
      onFilesPlaced: onFilesPlaced ?? this.onFilesPlaced,
      treeStyle: treeStyle ?? this.treeStyle,
    );
  }

  @override
  State<Tree> createState() => _TreeState();
}

/// One row the tree currently shows, in reading order.
///
/// The DOM is flat — every visible row is a sibling under `role="tree"` —
/// so the hierarchy the arrow keys walk (parent, first child) and the
/// position a screen reader announces (`aria-level` / `aria-posinset` /
/// `aria-setsize`) are carried here rather than read off nesting.
class _VisibleRow {
  const _VisibleRow({
    required this.node,
    required this.key,
    required this.depth,
    required this.parent,
    required this.parentNode,
    required this.expanded,
    required this.position,
    required this.setSize,
  });

  final CoreTreeNode node;

  /// Expansion-state key — `Object.hash(depth, index, label)`.
  final int key;

  final int depth;

  /// Index of the parent row in the visible list, `-1` at the top level.
  final int parent;

  /// Structural parent, including a root omitted from visible/focus rows.
  final CoreTreeNode? parentNode;

  final bool expanded;

  /// 1-based position among its siblings.
  final int position;

  final int setSize;

  bool get hasChildren => node.canHaveChildren || node.children.isNotEmpty;
}

class _TreeState extends State<Tree> {
  late final String _generatedScopeId;
  late final String _dragPrefix = 'co-tree-${identityHashCode(this)}';
  late final DragScopeController _placementDragController =
      DragScopeController();
  void Function()? _unsubscribePlacement;
  CoreTreeDropTarget? _placement;
  CoreTreeDropTarget? _externalPlacement;
  CoreDragOffset _dragTransform = .zero;
  double _rowSpacing = 0;
  double? _authoredRowSpacing;
  bool _spacingPending = false;
  int? _pendingFocusKey;

  CoreTreeDropTarget? get _preview => _placement ?? _externalPlacement;

  CoreTreeDropTarget? _targetAt(
    _VisibleRow row,
    double pointerY,
    double rowTop,
    double rowHeight,
  ) {
    final position = CoreTreeDropRules.positionAt(
      pointerY: pointerY,
      rowTop: rowTop,
      rowHeight: rowHeight,
      isBranch: row.hasChildren,
      hasParent: row.parentNode != null,
    );
    final directory = position == .inside ? row.node : row.parentNode;
    if (directory == null) return null;
    return CoreTreeDropTarget(
      anchor: row.node,
      directory: directory,
      position: position,
      depth: row.depth + (position == .inside ? 1 : 0),
    );
  }

  CoreTreeDropTarget? _placementFor(
    CoreDragSession session,
    CoreDragId? overId,
  ) {
    final source = _nodeForDragId(session.activeId, 'item');
    final targetNode = _nodeForDragId(overId, 'zone');
    final row = _rows
        .where((visible) => visible.node.id == targetNode?.id)
        .firstOrNull;
    final rect = overId == null
        ? null
        : _placementDragController.registry.dropZoneRects[overId];
    if (source == null || row == null || rect == null) return null;
    final target = _targetAt(row, session.pointer.y, rect.top, rect.height);
    if (target == null ||
        !CoreTreeDropRules.acceptsPlacement(
          source,
          target,
          childrenOf: (node) => _childrenOf(_keyOf(node, 0, 0), node),
        ) ||
        !(component.canPlace?.call(source, target) ?? true)) {
      return null;
    }
    return target;
  }

  void _handlePlacementChange() {
    if (!mounted || component.onNodePlace == null) return;
    final session = _placementDragController.session;
    final next = session == null
        ? null
        : _placementFor(session, _placementDragController.overId);
    final transform = session?.transform ?? CoreDragOffset.zero;
    if (next == _placement && transform == _dragTransform) return;
    setState(() {
      _placement = next;
      _dragTransform = transform;
    });
  }

  int? _previewInsertionIndex() {
    final preview = _preview;
    if (preview == null) return null;
    final index = _rows.indexWhere((r) => r.node.id == preview.anchor.id);
    if (index < 0) return null;
    if (preview.position == .before) return index;
    if (preview.position == .inside) return index + 1;
    var after = index + 1;
    while (after < _rows.length && _rows[after].depth > _rows[index].depth) {
      after++;
    }
    return after;
  }

  double _previewHeight(double rowSpacing) {
    if (_preview == null) return 0;
    final height =
        (component.virtualRowHeight ??
            CoreTreeContract.defaultEstimatedRowHeight) +
        rowSpacing;
    final source = _placementDragController.session;
    if (source == null) return height;
    final id = _nodeForDragId(source.activeId, 'item')?.id;
    final index = _rows.indexWhere((r) => r.node.id == id);
    if (index < 0) return height;
    var end = index + 1;
    while (end < _rows.length && _rows[end].depth > _rows[index].depth) {
      end++;
    }
    return (end - index) * height;
  }

  @override
  void dispose() {
    component.controller?.removeRenameListener(_handleRenameRequest);
    _unsubscribePlacement?.call();
    _placementDragController.dispose();
    super.dispose();
  }

  var _expandedKeys = <int>{};
  final Map<int, List<CoreTreeNode>> _loaded = {};
  final Set<int> _loading = {};
  final Map<int, Object> _loadErrors = {};

  /// Key of the row whose label is being edited — at most one at a time.
  int? _renamingKey;

  /// The node as it was when the edit began; reported with the new label.
  CoreTreeNode? _renamingNode;

  /// The field's text as last typed. The `<input>` holds it while the edit
  /// is open; a commit by blur or an outside press reads it from here.
  String _renameText = '';

  bool _canRename(CoreTreeNode node) =>
      component.onNodeRename != null &&
      (component.canRenameNode?.call(node) ?? true);

  /// The caller's id, else one stable across rebuilds via the State's
  /// identity — see `build` for what it scopes.
  String get _scopeId => component.id ?? _generatedScopeId;

  String _renameFieldId(String scopeId) => '$scopeId-rename';

  void _startRename(int key, CoreTreeNode node, String scopeId) {
    if (!_canRename(node) || _renamingKey == key) return;
    // One field at a time — an edit still open elsewhere keeps its text.
    if (_renamingKey != null) _handleRenameCommit();
    final end = CoreTreeRenameRules.selectionEnd(
      node.label,
      isBranch: _isBranch(node),
    );
    setState(() {
      _renamingKey = key;
      _renamingNode = node;
      _renameText = node.label;
    });
    // The field mounts with the next render, itself a microtask queued by
    // `setState` above — so this one runs after it and finds the input.
    scheduleMicrotask(() {
      if (mounted && _renamingKey == key) {
        focusInputRangeWithin(_renameFieldId(scopeId), 0, end);
      }
    });
  }

  /// [CoreTreeController.startRename] — the path F2 on the row takes. Only a
  /// row of the last build can open: its field must mount to take focus.
  void _handleRenameRequest(String nodeId) {
    for (final row in _rows) {
      if (row.node.id == nodeId) {
        _startRename(row.key, row.node, _scopeId);
        return;
      }
    }
  }

  void _handleRenameCommit() {
    final node = _renamingNode;
    if (node == null) return;
    final label = CoreTreeRenameRules.committedLabel(node, _renameText);
    _endRename();
    if (label != null) component.onNodeRename?.call(node, label);
  }

  void _endRename() {
    if (_renamingKey == null) return;
    setState(() {
      _renamingKey = null;
      _renamingNode = null;
    });
  }

  /// Enter or Escape ended the edit from the keyboard — the field is about
  /// to unmount with focus inside it, so the row it stood in takes the tab
  /// stop back instead of focus falling to the document.
  void _finishRenameByKey(String scopeId, {required bool commit}) {
    final key = _renamingKey;
    final index = _rows.indexWhere((row) => row.key == key);
    if (commit) {
      _handleRenameCommit();
    } else {
      _endRename();
    }
    if (index < 0) return;
    scheduleMicrotask(() {
      if (!mounted || _rows.isEmpty) return;
      // A rename the consumer applied can re-key the row; the position it
      // held is the best remaining address for it.
      final current = _rows.indexWhere((row) => row.key == key);
      _focusRow(
        current >= 0 ? current : index.clamp(0, _rows.length - 1),
        scopeId,
      );
    });
  }

  int _keyOf(CoreTreeNode node, int depth, int index) => node.id == null
      ? Object.hash(depth, index, node.label)
      : Object.hash('tree-node', node.id);

  List<CoreTreeNode> _childrenOf(int key, CoreTreeNode node) =>
      node.children.isNotEmpty ? node.children : (_loaded[key] ?? const []);

  bool _isBranch(CoreTreeNode node) =>
      node.canHaveChildren || node.children.isNotEmpty;

  bool _isSelected(CoreTreeNode node) => component.selectedId == null
      ? node.selected
      : node.id == component.selectedId;

  CoreDragId _itemId(String id) => CoreDragId('$_dragPrefix:item:$id');
  CoreDragId _zoneId(String id) => CoreDragId('$_dragPrefix:zone:$id');

  CoreTreeNode? _nodeForDragId(CoreDragId? id, String kind) {
    final prefix = '$_dragPrefix:$kind:';
    if (id == null || !id.value.startsWith(prefix)) return null;
    final nodeId = id.value.substring(prefix.length);
    for (final row in _rows) {
      if (row.node.id == nodeId) return row.node;
    }
    return null;
  }

  bool _acceptsDrop(CoreTreeNode source, CoreTreeNode destination) {
    final structurallyAllowed = CoreTreeDropRules.accepts(
      source,
      destination,
      childrenOf: (node) => _childrenOf(_keyOf(node, 0, 0), node),
    );
    return structurallyAllowed &&
        (component.canDrop?.call(source, destination) ?? true);
  }

  CoreTreeNode? _dropDirectory(_VisibleRow row) =>
      row.hasChildren ? row.node : row.parentNode;

  CoreTreeNode? _directoryForNode(CoreTreeNode node) {
    for (final row in _rows) {
      if (row.node.id == node.id) return _dropDirectory(row);
    }
    return null;
  }

  void _handleDrop(CoreTreeNode source, CoreDragEndEvent event) {
    if (component.onNodePlace != null) {
      final target = _placementFor(event.session, event.overId);
      if (target != null) component.onNodePlace?.call(source, target);
      return;
    }
    final row = _nodeForDragId(event.overId, 'zone');
    final destination = row == null ? null : _directoryForNode(row);
    if (destination != null && _acceptsDrop(source, destination)) {
      component.onNodeDrop?.call(source, destination);
    }
  }

  /// Key of the row holding the tree's single tab stop, or `null` for the
  /// first row.
  ///
  /// A tree is one stop from the outside and the arrow keys walk it (the
  /// WAI-ARIA tree pattern). Tracked by row key rather than position so the
  /// stop stays on its row when a sibling above expands or collapses.
  int? _activeKey;

  final _typeahead = RovingTypeahead();

  /// Visible rows of the last build — what the keydown handler walks.
  List<_VisibleRow> _rows = const [];
  String? _externalOverId;
  final Map<String, int> _externalDragDepth = {};

  @override
  void initState() {
    super.initState();
    _generatedScopeId =
        'co-tree-${kIsWeb ? 'web' : 'ssr'}-${_coTreeScopeCounter++}';
    _unsubscribePlacement = _placementDragController.addListener(
      _handlePlacementChange,
    );
    _initExpanded(component.nodes, 0);
    _scheduleInitialLoads();
    component.controller?.addRenameListener(_handleRenameRequest);
  }

  @override
  void didUpdateComponent(Tree oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!identical(oldComponent.controller, component.controller)) {
      oldComponent.controller?.removeRenameListener(_handleRenameRequest);
      component.controller?.addRenameListener(_handleRenameRequest);
    }
    if (!identical(oldComponent.nodes, component.nodes)) {
      _scheduleInitialLoads();
    }
  }

  void _scheduleInitialLoads() {
    scheduleMicrotask(() {
      if (!mounted) return;
      void visit(List<CoreTreeNode> nodes, int depth) {
        for (var i = 0; i < nodes.length; i++) {
          final node = nodes[i];
          final key = _keyOf(node, depth, i);
          if (!_isExpanded(key, node)) continue;
          if (node.children.isEmpty && !_loaded.containsKey(key)) {
            unawaited(_loadNode(key, node));
          }
          visit(_childrenOf(key, node), depth + 1);
        }
      }

      visit(component.nodes, 0);
    });
  }

  void _initExpanded(List<CoreTreeNode> nodes, int depth) {
    for (var i = 0; i < nodes.length; i++) {
      final key = _keyOf(nodes[i], depth, i);
      if (nodes[i].expanded && _isBranch(nodes[i])) {
        _expandedKeys = {..._expandedKeys, key};
      }
      if (nodes[i].children.isNotEmpty) {
        _initExpanded(nodes[i].children, depth + 1);
      }
    }
  }

  bool _isExpanded(int key, CoreTreeNode node) => component.expansionControlled
      ? node.expanded
      : _expandedKeys.contains(key);

  /// Flattens the visible part of the tree into reading order.
  void _collectRows(
    List<CoreTreeNode> nodes,
    int depth,
    int parent,
    List<_VisibleRow> into, {
    CoreTreeNode? parentNode,
    int siblingOffset = 0,
    int? siblingCount,
  }) {
    var promotedCount = 0;
    if (!component.showRoots && depth == 0) {
      for (var index = 0; index < nodes.length; index++) {
        final node = nodes[index];
        final key = _keyOf(node, depth, index);
        if (_isBranch(node) && _isExpanded(key, node)) {
          promotedCount += _childrenOf(key, node).length;
        }
      }
    }
    var promotedOffset = 0;
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final key = _keyOf(node, depth, i);
      final expanded = _isBranch(node) && _isExpanded(key, node);
      if (!component.showRoots && depth == 0) {
        if (expanded) {
          _collectRows(
            _childrenOf(key, node),
            depth + 1,
            -1,
            into,
            parentNode: node,
            siblingOffset: promotedOffset,
            siblingCount: promotedCount,
          );
          promotedOffset += _childrenOf(key, node).length;
        }
        continue;
      }
      final index = into.length;
      into.add(
        _VisibleRow(
          node: node,
          key: key,
          depth: component.showRoots ? depth : depth - 1,
          parent: parent,
          parentNode: parentNode,
          expanded: expanded,
          position: siblingOffset + i + 1,
          setSize: siblingCount ?? nodes.length,
        ),
      );
      if (expanded) {
        _collectRows(
          _childrenOf(key, node),
          depth + 1,
          index,
          into,
          parentNode: node,
        );
      }
    }
  }

  int get _activeIndex {
    final index = _rows.indexWhere((row) => row.key == _activeKey);
    return index < 0 ? 0 : index;
  }

  void _focusRow(int index, String scopeId) {
    setState(() => _activeKey = _rows[index].key);
    if (component.virtualRowHeight case final height?) {
      _pendingFocusKey = _rows[index].key;
      scrollElementTo('$scopeId-viewport', y: index * (height + _rowSpacing));
      // The scroll event mounts a distant row after this turn. Focus is
      // committed by renderWindow once the destination is actually included.
    } else {
      focusRovingItem(scopeId, index);
    }
  }

  /// The WAI-ARIA tree keys. Up/Down/Home/End and typeahead walk the
  /// visible rows without wrapping (a tree is scanned, not cycled); Right
  /// opens a closed parent or steps into an open one; Left closes an open
  /// parent or steps out to its parent. Enter/Space stay with the row's
  /// `Clickable` — select or toggle, exactly as a press would. F2 opens the
  /// active row's label for renaming when [Tree.onNodeRename] is set.
  void _handleKeyDown(web.KeyboardEvent event, String scopeId) {
    final rows = _rows;
    // Keys typed into the rename field are text, not tree navigation —
    // typeahead would otherwise jump rows on every letter of the new name.
    if (rows.isEmpty || event.defaultPrevented || _renamingKey != null) {
      return;
    }
    final current = _activeIndex;
    final row = rows[current];
    switch (event.key) {
      case 'F2':
        if (!_canRename(row.node)) return;
        preventDefault(event);
        _startRename(row.key, row.node, scopeId);
      case 'ArrowRight':
        preventDefault(event);
        if (!row.hasChildren) return;
        if (row.expanded) {
          _focusRow(current + 1, scopeId);
        } else {
          handleToggle(row.key, row.node);
        }
      case 'ArrowLeft':
        preventDefault(event);
        if (row.expanded) {
          handleToggle(row.key, row.node);
        } else if (row.parent >= 0) {
          _focusRow(row.parent, scopeId);
        }
      default:
        final target = rovingKeyTarget(
          event,
          current: current,
          count: rows.length,
          vertical: true,
          wrap: false,
          labels: [for (final visible in rows) visible.node.label],
          typeahead: _typeahead,
        );
        if (target != null) _focusRow(target, scopeId);
    }
  }

  /// The inline rename field that stands in for the label.
  Component _renameField(String scopeId, ResolvedTree resolved) => div(
    [
      TextField(
        id: _renameFieldId(scopeId),
        initialValue: _renamingNode?.label ?? '',
        textFieldStyle: resolved.renameFieldStyle,
        onChanged: (value) => _renameText = value,
        onSubmitted: (value) {
          _renameText = value;
          _finishRenameByKey(scopeId, commit: true);
        },
        // Pressing anywhere else keeps what was typed — the file-explorer
        // idiom, and the Flutter twin's `onTapOutside`.
        onTapOutside: _handleRenameCommit,
        onKeyDown: (event) {
          // Keys typed here are text: neither the tree's navigation nor a
          // row's activation may see them while the user types a name.
          event.stopPropagation();
          if (event.key == 'Escape') {
            preventDefault(event);
            _finishRenameByKey(scopeId, commit: false);
          }
        },
        eventHandlers: {
          // Tabbing away commits as well, like a press outside.
          'focusout': [(_) => _handleRenameCommit()],
        },
      ),
    ],
    // Takes the label's place in the row: fills the remaining width and may
    // shrink below its content, like the truncating label it replaces.
    classes: '${WebLayout.flex1} ${WebLayout.minWZero}',
  );

  Component _buildRow(
    BuildContext context, {
    required _VisibleRow row,
    required int index,
    required int activeIndex,
    required ResolvedTree resolved,
    required String scopeId,
  }) {
    final node = row.node;
    final key = row.key;
    final isExpanded = row.expanded;
    final hasKids = row.hasChildren;
    final dropDirectory = _dropDirectory(row);
    final hasLeafHandler = !hasKids && component.onNodeSelect != null;
    final selectOnRow =
        hasLeafHandler ||
        (hasKids && component.selectFolders && component.onNodeSelect != null);
    // A selectable folder row toggles too only when asked — mirrors the
    // Flutter twin.
    final toggleOnRow =
        hasKids &&
        (!component.selectFolders || component.toggleFoldersOnSelect);
    final toggleOnChevron = hasKids && component.selectFolders;
    final rowPress = _loadErrors.containsKey(key)
        ? () => unawaited(_loadNode(key, node))
        : selectOnRow && toggleOnRow
        ? () {
            component.onNodeSelect!(node);
            handleToggle(key, node);
          }
        : selectOnRow
        ? () => component.onNodeSelect!(node)
        : toggleOnRow
        ? () => handleToggle(key, node)
        : null;
    final isRenaming = _renamingKey == key;
    final renamable = _canRename(node);
    final interactive = rowPress != null || renamable;

    final treeNode = resolveTreeNode(
      context: context,
      resolved: resolved,
      depth: row.depth,
      selected: _isSelected(node),
      isExpanded: isExpanded,
      scopeId: scopeId,
      hasTrailing: component.trailingBuilder != null,
    );

    Component rowContent = div(
      [
        // Chevron wrapper span carries the content colour and the
        // rotation; the wrapped icon inherits the colour through
        // currentColor.
        if (hasKids && toggleOnChevron)
          Clickable(
            onPressed: () => handleToggle(key, node),
            // A pointer target only: the keyboard toggles the row with
            // Right/Left, so the chevron is neither a second tab stop
            // inside the tree's single one nor a button nested in a
            // treeitem.
            semanticsButton: false,
            attributes: const {'tabindex': '-1', 'aria-hidden': 'true'},
            clickableStyle: resolved.clickableStyle,
            child: span(
              [
                Icon(
                  LucideIcons.chevronRight,
                  iconStyle: resolved.chevronIconStyle,
                ),
              ],
              classes: treeNode.chevron.className,
              styles: treeNode.chevron.inlineStyles,
            ),
          )
        else if (hasKids)
          span(
            [
              Icon(
                LucideIcons.chevronRight,
                iconStyle: resolved.chevronIconStyle,
              ),
            ],
            classes: treeNode.chevron.className,
            styles: treeNode.chevron.inlineStyles,
          )
        else
          span(
            const [],
            classes: resolved.chevronSpacer.className,
            styles: resolved.chevronSpacer.inlineStyles,
          ),
        span(
          const [],
          classes: resolved.iconGap.className,
          styles: resolved.iconGap.inlineStyles,
        ),
        // Folder / file icon wrapper span carries the content
        // colour; the wrapped icon inherits it through currentColor.
        span(
          [
            if (component.leadingBuilder case final builder?)
              builder(context, node, expanded: isExpanded)
            else
              Icon(
                hasKids
                    ? (isExpanded
                          ? LucideIcons.folderOpen
                          : LucideIcons.folderClosed)
                    : LucideIcons.file,
                iconStyle: hasKids
                    ? resolved.iconStyle
                    : resolved.leafIconStyle,
              ),
          ],
          // A caller's `leadingBuilder` widget is not the kit's file glyph, so
          // it keeps the folder wrapper's colour; only the default file glyph
          // takes the leaf colour (Flutter does not wrap a builder at all).
          classes: (hasKids || component.leadingBuilder != null)
              ? resolved.icon.className
              : resolved.leafIcon.className,
          styles: (hasKids || component.leadingBuilder != null)
              ? resolved.icon.inlineStyles
              : resolved.leafIcon.inlineStyles,
        ),
        span(
          const [],
          classes: resolved.labelGap.className,
          styles: resolved.labelGap.inlineStyles,
        ),
        if (isRenaming)
          _renameField(scopeId, resolved)
        else
          span(
            [Text(node.label)],
            classes: treeNode.label.className,
            styles: treeNode.label.inlineStyles,
          ),
        if (component.trailingBuilder case final builder?) ...[
          span(
            const [],
            classes: resolved.labelGap.className,
            styles: resolved.labelGap.inlineStyles,
          ),
          builder(context, node, expanded: isExpanded),
        ],
        if (_loading.contains(key))
          component.loadingBuilder?.call(context, node) ??
              Text(CouiLocalizations.of(context).loadingLabel),
        if (_loadErrors[key] case final error?)
          component.errorBuilder?.call(context, node, error) ??
              const Text('Unable to load · Retry'),
      ],
      classes: treeNode.root.className,
      styles: treeNode.root.inlineStyles,
    );

    // Only paint shifts; measured DragItem/DropZone rectangles remain fixed.
    if (component.onNodePlace != null || component.onFilesPlaced != null) {
      final insertion = _previewInsertionIndex();
      final gapHeight = _previewHeight(_rowSpacing);
      if (insertion != null && index >= insertion) {
        rowContent = div(
          [rowContent],
          attributes: {'data-tree-gap-shift': '$gapHeight'},
          styles: Styles(
            raw: {
              'transform': 'translateY(${gapHeight / kRemDivisor}rem)',
              'transition':
                  'transform ${CoreDuration.fast}ms '
                  '${CoreEasing.move.toVarCss()}',
            },
          ),
        );
      }
      if (insertion != null && index == insertion) {
        final indent = spaceCss(
          resolved.merged.indent ?? CoreTreeStyle.defaultIndent,
        );
        rowContent = div(
          [
            div(
              const [],
              styles: Styles.combine([
                ?resolved.dropIndicator.inlineStyles,
                Styles(
                  raw: {'margin-left': 'calc(${_preview!.depth} * $indent)'},
                ),
              ]),
            ),
            rowContent,
          ],
          attributes: const {'data-tree-placement-gap': 'true'},
        );
      }
    }

    // Every visible row is a `treeitem` in the roving rotation — a row a
    // keyboard cannot land on is a row a screen reader cannot read.
    // `aria-selected` is stated only where selection means something (a
    // selectable row, or one the caller marked selected): "not selected"
    // on every row of a tree nobody selects in is noise the reader repeats
    // row after row.
    final treeItemAttributes = {
      'role': 'treeitem',
      'aria-level': '${row.depth + 1}',
      'aria-posinset': '${row.position}',
      'aria-setsize': '${row.setSize}',
      if (hasKids) 'aria-expanded': isExpanded ? 'true' : 'false',
      if (selectOnRow || _isSelected(node))
        'aria-selected': _isSelected(node) ? 'true' : 'false',
      ...rovingItemAttributes(scopeId, index, active: index == activeIndex),
    };

    // Rows compose Clickable, which owns tap, Enter/Space activation and
    // the focus ring; the treeitem role replaces its button role. A
    // display-only row (a leaf with no onNodeSelect) still has to take
    // focus, but it is content, not a disabled control (chip and dock
    // precedent) — so it gives no press feedback and keeps the row's own
    // cursor rather than the pointer an actionable row shows.
    final rowId = node.id == null
        ? null
        : '${component.nodeKeyPrefix ?? 'tree-node'}.${node.id}';
    // A row being renamed renders bare: the field owns the pointer and the
    // keys until the edit ends, and a press, an Enter activation or a drag
    // starting under it would act on the row instead (Flutter does the
    // same).
    var result = isRenaming
        ? div(
            [rowContent],
            id: rowId,
            classes: WebLayout.wFull,
            attributes: treeItemAttributes,
          )
        : Clickable(
            onPressed: rowPress,
            onDoubleTap: renamable
                ? () => _startRename(key, node, scopeId)
                : null,
            onFocus: (focused) {
              // Clicking or tabbing onto a row moves the tab stop with it.
              if (focused && _activeKey != key) {
                setState(() => _activeKey = key);
              }
            },
            enableFeedback: interactive,
            semanticsButton: false,
            attributes: treeItemAttributes,
            id: rowId,
            // Clickable's root is `inline-flex` (shrink-to-fit), so without
            // an explicit width a row tracks its content and escapes a
            // narrower tree instead of letting the label truncate — `w-full`
            // pins the wrapper to the tree width.
            classes: WebLayout.wFull,
            css: !component.showRoots || resolved.rowSpacingBox != null
                ? Styles.combine([
                    if (!interactive) _kDisplayOnlyRowCursor,
                    // Inside drag/drop wrappers, inline-flex otherwise leaves
                    // a baseline descender below the row, outside its spacing.
                    const Styles(raw: {'vertical-align': 'top'}),
                  ])
                : interactive
                ? null
                : _kDisplayOnlyRowCursor,
            clickableStyle: resolved.clickableStyle,
            child: rowContent,
          );
    // Present whenever a builder is given and enabled only with entries, as on
    // Flutter — a wrapper that came and went would remount the row's
    // Clickable. A row being renamed has none: its field's right-click is
    // text editing's.
    if (component.nodeContextMenu case final menu?) {
      final items = isRenaming ? const <CoreMenuItem<Component>>[] : menu(node);
      result = ContextMenu(
        items: items,
        enabled: items.isNotEmpty,
        css: _kRowContextMenuBox,
        child: result,
      );
    }
    if ((component.onNodeDrop != null || component.onNodePlace != null) &&
        node.id != null &&
        !isRenaming) {
      final id = node.id!;
      if (dropDirectory != null || component.onNodePlace != null) {
        result = DropZone(
          id: _zoneId(id),
          data: node,
          builder: (context, dropDetails, child) {
            final source = _nodeForDragId(dropDetails.activeId, 'item');
            final isValid =
                component.onNodePlace == null &&
                dropDetails.isOver &&
                source != null &&
                dropDirectory != null &&
                _acceptsDrop(source, dropDirectory);
            return div(
              [child],
              attributes: {'data-tree-drop-over': '$isValid'},
              styles: isValid
                  ? (hasKids
                        ? resolved.dropTarget.inlineStyles
                        : resolved.dropIndicator.inlineStyles)
                  : null,
            );
          },
          child: result,
        );
      }
      if (component.canDragNode?.call(node) ?? true) {
        result = DragItem(
          id: _itemId(id),
          data: node,
          label: node.label,
          onDragEnd: (event) => _handleDrop(node, event),
          child:
              component.onNodePlace != null &&
                  _placementDragController.activeId == _itemId(id)
              ? div([result], styles: const Styles(raw: {'opacity': '0'}))
              : result,
        );
      }
    }
    if ((component.onFilesDroppedOnNode != null ||
            component.onFilesPlaced != null) &&
        dropDirectory != null &&
        node.id != null &&
        !isRenaming) {
      final id = node.id!;
      result = div(
        [result],
        attributes: {'data-tree-file-drop-over': '${_externalOverId == id}'},
        styles: _externalOverId == id
            ? (hasKids
                  ? resolved.dropTarget.inlineStyles
                  : resolved.dropIndicator.inlineStyles)
            : null,
        events: {
          'dragenter': (event) {
            event.preventDefault();
            _externalDragDepth[id] = (_externalDragDepth[id] ?? 0) + 1;
            if (_externalOverId != id) setState(() => _externalOverId = id);
          },
          'dragover': (event) {
            event.preventDefault();
            if (event case final web.DragEvent dragEvent) {
              final target = _externalTargetAt(row, dragEvent);
              if (_externalPlacement != target) {
                setState(() => _externalPlacement = target);
              }
            }
          },
          'dragleave': (event) {
            event.preventDefault();
            final depth = (_externalDragDepth[id] ?? 1) - 1;
            if (depth > 0) {
              _externalDragDepth[id] = depth;
            } else {
              _externalDragDepth.remove(id);
              if (_externalOverId == id) {
                setState(() {
                  _externalOverId = null;
                  _externalPlacement = null;
                });
              }
            }
          },
          'drop': (event) {
            if (event case final web.DragEvent dragEvent) {
              dragEvent.preventDefault();
              final target = _externalTargetAt(row, dragEvent);
              _externalDragDepth.remove(id);
              if (_externalOverId == id) {
                setState(() {
                  _externalOverId = null;
                  _externalPlacement = null;
                });
              }
              final transfer = dragEvent.dataTransfer;
              if (transfer == null) return;
              unawaited(
                collectAcceptedFiles(transfer, const []).then((files) {
                  if (mounted && files != null && files.length > 0) {
                    if (component.onFilesPlaced case final callback?) {
                      if (target != null) callback(files, target);
                    } else {
                      component.onFilesDroppedOnNode?.call(
                        files,
                        dropDirectory,
                      );
                    }
                  }
                }),
              );
            }
          },
        },
      );
    }
    return result;
  }

  CoreTreeDropTarget? _externalTargetAt(_VisibleRow row, web.DragEvent event) {
    if (component.onFilesPlaced == null) return null;
    final element = event.currentTarget as web.Element?;
    final rect = element?.getBoundingClientRect();
    if (rect == null) return null;
    return _targetAt(row, event.clientY.toDouble(), rect.top, rect.height);
  }

  Component _buildDragProxy(
    CoreDragSession session,
    String scopeId,
    ResolvedTree resolved,
  ) {
    final node = _nodeForDragId(session.activeId, 'item');
    final rect = _placementDragController.registry.itemRects[session.activeId];
    final row = _rows
        .where((visible) => visible.node.id == node?.id)
        .firstOrNull;
    if (node == null || rect == null || row == null) return const div([]);
    final expanded = row.expanded;
    // The ghost is the row lifted off the tree, so its corner and left inset
    // are the row's own — resolved from the merged `borderRadius`,
    // `nodePadding` and `indent` at the row's depth, not stated again here.
    final ghost = resolveTreeNode(
      context: context,
      resolved: resolved,
      depth: row.depth,
      selected: false,
      isExpanded: expanded,
      scopeId: scopeId,
    ).dragGhost;
    return div(
      [
        if (component.leadingBuilder case final builder?)
          builder(context, node, expanded: expanded)
        else
          span(
            [
              Icon(
                row.hasChildren
                    ? (expanded
                          ? LucideIcons.folderOpen
                          : LucideIcons.folderClosed)
                    : LucideIcons.file,
                iconStyle: row.hasChildren
                    ? resolved.iconStyle
                    : resolved.leafIconStyle,
              ),
            ],
            classes: row.hasChildren
                ? resolved.icon.className
                : resolved.leafIcon.className,
            styles: row.hasChildren
                ? resolved.icon.inlineStyles
                : resolved.leafIcon.inlineStyles,
          ),
        span([Text(node.label)], classes: 'truncate'),
      ],
      classes: 'flex items-center w-full',
      styles: Styles.combine([
        Styles(
          raw: {
            'width': '${rect.width / kRemDivisor}rem',
            'height': '${rect.height / kRemDivisor}rem',
            'background-color': 'rgb(var(--coui-surface))',
            'box-shadow':
                '0 0.375rem 0.75rem rgba(0, 0, 0, ${CoreOpacity.opacity20})',
          },
        ),
        ?ghost.inlineStyles,
      ]),
    );
  }

  /// Whether the row holding the tab stop sits inside the subtree of the
  /// visible row keyed [key] — collapsing that row would remove it.
  bool _activeIsDescendantOf(int key) {
    final rows = _rows;
    final active = rows.indexWhere((row) => row.key == _activeKey);
    if (active < 0) return false;
    for (var parent = rows[active].parent; parent >= 0;) {
      if (rows[parent].key == key) return true;
      parent = rows[parent].parent;
    }
    return false;
  }

  void handleToggle(int key, CoreTreeNode node) {
    final opening = !_isExpanded(key, node);
    // Collapsing a row that contains the tab stop would take the stop away
    // with the hidden rows; it moves to the row being collapsed instead, so
    // Tab still lands inside the tree where the user left it.
    if (_activeIsDescendantOf(key)) setState(() => _activeKey = key);
    if (!component.expansionControlled) {
      setState(() {
        if (_expandedKeys.contains(key)) {
          _expandedKeys = {
            ..._expandedKeys.where((e) => e != key),
          };
        } else {
          _expandedKeys = {..._expandedKeys, key};
        }
      });
    }
    component.onNodeToggle?.call(node);
    if (opening && node.children.isEmpty && !_loaded.containsKey(key)) {
      unawaited(_loadNode(key, node));
    }
  }

  Future<void> _loadNode(int key, CoreTreeNode node) async {
    final loader = component.loadChildren;
    if (loader == null || !_loading.add(key)) return;
    setState(() => _loadErrors.remove(key));
    try {
      final children = await loader(node);
      if (!mounted) return;
      setState(() {
        _loaded[key] = children;
        _loading.remove(key);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading.remove(key);
        _loadErrors[key] = error;
      });
    }
  }

  double? _measuredRowSpacing() {
    if (!const bool.fromEnvironment('dart.library.js_interop')) return null;
    final element = web.document.querySelector(
      '[data-tree-spacing="$_scopeId"]',
    );
    if (element == null) return null;
    return double.tryParse(
      web.window.getComputedStyle(element).paddingBottom.replaceAll('px', ''),
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveTree(context, treeStyle: component.treeStyle);
    final authored = resolveTreeRuntime(
      context,
      treeStyle: component.treeStyle,
    ).rowSpacing;
    final changed = _authoredRowSpacing != authored;
    _authoredRowSpacing = authored;
    _spacingPending = changed && authored > 0;
    _rowSpacing = !changed && authored > 0
        ? _measuredRowSpacing() ?? authored
        : authored;
    if (_spacingPending) {
      // A changed style still has the preceding DOM during build. Read its
      // computed CSS after commit, so an 8 -> 0/4 change cannot keep the old gap.
      scheduleMicrotask(() {
        if (!mounted || _authoredRowSpacing != authored) return;
        _spacingPending = false;
        final measured = _measuredRowSpacing();
        if (measured != null && measured != _rowSpacing) {
          setState(() => _rowSpacing = measured);
        }
      });
    }
    // Scope id for the per-instance pseudo-state scoped rule — used to
    // build a unique `.co-tree-h-<id>` class shared by every row and the
    // `<style>` rule (the caller's id wins, else a generated one stable
    // across rebuilds via the State's identity). It also scopes the
    // roving-focus row markers, so a tree nested in another collection
    // never answers the outer one's focus query.
    final scopeId = _scopeId;
    final rules = resolveTreeRules(
      context,
      scopeId: scopeId,
      treeStyle: component.treeStyle,
    );

    final rows = <_VisibleRow>[];
    _collectRows(component.nodes, 0, -1, rows);
    _rows = rows;
    final activeIndex = _activeIndex;
    final previewIndent = spaceCss(
      resolved.merged.indent ?? CoreTreeStyle.defaultIndent,
    );

    Component renderWindow(int first, int end, {double? rowHeight}) {
      if (_pendingFocusKey == _activeKey &&
          activeIndex >= first &&
          activeIndex < end) {
        final pendingKey = _pendingFocusKey;
        if (pendingKey != null) {
          scheduleMicrotask(() {
            if (!mounted || _pendingFocusKey != pendingKey) return;
            _pendingFocusKey = null;
            focusRovingItem(scopeId, activeIndex);
          });
        }
      }
      final hiddenTail = rowHeight == null
          ? 0.0
          : (rows.length - end) * rowHeight - _rowSpacing;
      final visibleActive = activeIndex >= first && activeIndex < end
          ? activeIndex
          : first;
      return div(
        [
          if (rules.css.isNotEmpty)
            Component.element(tag: 'style', children: [RawText(rules.css)]),
          if (rowHeight != null && first > 0)
            div(
              const [],
              styles: Styles(
                raw: {'height': '${first * rowHeight / kRemDivisor}rem'},
              ),
            ),
          for (var index = first; index < end; index++)
            if (resolved.rowSpacingBox case final spacingBox?
                when index + 1 != rows.length)
              div(
                [
                  _buildRow(
                    context,
                    row: rows[index],
                    index: index,
                    activeIndex: visibleActive,
                    resolved: resolved,
                    scopeId: scopeId,
                  ),
                ],
                styles: spacingBox.inlineStyles,
                attributes: {'data-tree-spacing': scopeId},
              )
            else
              _buildRow(
                context,
                row: rows[index],
                index: index,
                activeIndex: visibleActive,
                resolved: resolved,
                scopeId: scopeId,
              ),
          if (_preview != null && end == rows.length)
            div(
              [
                div(
                  const [],
                  styles: Styles.combine([
                    ?resolved.dropIndicator.inlineStyles,
                    Styles(
                      raw: {
                        'margin-left':
                            'calc(${_preview!.depth} * $previewIndent)',
                      },
                    ),
                  ]),
                ),
              ],
              styles: Styles(
                raw: {
                  'height': '${_previewHeight(_rowSpacing) / kRemDivisor}rem',
                },
              ),
              attributes: const {'aria-hidden': 'true'},
            ),
          if (rowHeight != null && end < rows.length)
            div(
              const [],
              styles: Styles(
                raw: {
                  'height':
                      '${hiddenTail / kRemDivisor}'
                      'rem',
                },
              ),
            ),
        ],
        id:
            component.id ??
            (component.onNodeDrop == null && component.onNodePlace == null
                ? null
                : scopeId),
        classes: component.rootClasses(resolved.root.className),
        styles: component.css != null
            ? Styles.combine([?resolved.root.inlineStyles, component.css!])
            : resolved.root.inlineStyles,
        attributes: {...component.componentAttributes, 'role': 'tree'},
        events: {
          ...component.events,
          'keydown': EventHandlers.chain(
            component.events['keydown'],
            EventHandlers.createKeyboardEventHandler(
              (event) => _handleKeyDown(event, scopeId),
            ),
          ),
        },
      );
    }

    final Component tree;
    if (component.virtualRowHeight case final height?) {
      tree = ScrollableClient(
        id: '$scopeId-viewport',
        // The treeitem owns this composite's one tab stop.
        attributes: const {'tabindex': '-1'},
        css: Styles(
          raw: {
            'height': '${component.virtualViewportHeight! / kRemDivisor}rem',
          },
        ),
        builder: (context, offset, size, _) {
          if (!_spacingPending && authored > 0) {
            _rowSpacing = _measuredRowSpacing() ?? _rowSpacing;
          }
          final extent = height + _rowSpacing;
          final first = (offset.dy / extent).floor().clamp(0, rows.length);
          final visibleCount =
              ((size.height > 0
                          ? size.height
                          : component.virtualViewportHeight!) /
                      extent)
                  .ceil() +
              2;
          final end = (first + visibleCount).clamp(0, rows.length);
          return renderWindow(first, end, rowHeight: extent);
        },
      );
    } else {
      tree = renderWindow(0, rows.length);
    }
    if (component.onNodePlace != null) {
      return DragScope(
        controller: _placementDragController,
        originElementId: component.virtualRowHeight == null
            ? scopeId
            : '$scopeId-viewport',
        child: div([
          tree,
          DragOverlay(
            builder: (_, session) =>
                _buildDragProxy(session, scopeId, resolved),
          ),
        ]),
      );
    }
    if (component.onNodeDrop == null || DragScope.maybeOf(context) != null) {
      return tree;
    }
    return DragScope(
      originElementId: component.virtualRowHeight == null
          ? scopeId
          : '$scopeId-viewport',
      child: tree,
    );
  }
}

/// Chain sugar mirroring the Flutter `Tree.withStyle` extension —
/// merges a [CoreTreeStyle] patch into [Tree.treeStyle] via the
/// existing [Tree.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTreeStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreTreeStyle.borderRadius]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Tree(nodes: nodes).radius4
/// ```
extension TreeStyleChain on Tree {
  /// Returns a copy of this [Tree] with [patch] merged into
  /// [treeStyle] (patch fields win on conflict).
  Tree withStyle(CoreTreeStyle patch) =>
      copyWith(treeStyle: (treeStyle ?? const CoreTreeStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  Tree get radius0 =>
      withStyle(const CoreTreeStyle(borderRadius: CoreBorderRadius.zero));

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Tree get radius2 => withStyle(
    const CoreTreeStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius2)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Tree get radius4 => withStyle(
    const CoreTreeStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Tree get radius6 => withStyle(
    const CoreTreeStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius6)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Tree get radius8 => withStyle(
    const CoreTreeStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius8)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Tree get radius10 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Tree get radius12 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Tree get radius14 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Tree get radius16 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Tree get radius20 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Tree get radius24 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Tree get radius28 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Tree get radius32 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Tree get radius36 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Tree get radius40 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Tree get radius48 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Tree get radius56 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Tree get radius64 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Tree get radius9999 => withStyle(
    const CoreTreeStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
