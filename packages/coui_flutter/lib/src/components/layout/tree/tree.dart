import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;

/// Platform-native leading content for a tree node.
typedef TreeNodeBuilder =
    Widget Function(
      BuildContext context,
      CoreTreeNode node, {
      required bool expanded,
    });

/// Platform-native content for a failed lazy load.
typedef TreeLoadErrorBuilder =
    Widget Function(
      BuildContext context,
      CoreTreeNode node,
      Object error,
    );

/// Unified tree component.
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
class Tree extends StatefulWidget
    implements
        CoreTreeContract<Widget>,
        CoreTreeFilesDropContract<List<XFile>>,
        CoreTreeContextMenuContract<Widget> {
  /// Creates a [Tree].
  const Tree({
    required this.nodes,
    this.showRoots = true,
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
    this.scrollController,
    this.onNodeDrop,
    this.canDrop,
    this.onFilesDroppedOnNode,
    this.onNodePlace,
    this.canPlace,
    this.canDragNode,
    this.onFilesPlaced,
    super.key,
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

  /// Opt-in inline rename — double-click or F2 on a focused row.
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
  final CoreTreeNodeMenuBuilder<Widget>? nodeContextMenu;

  @override
  final bool selectFolders;

  @override
  final bool toggleFoldersOnSelect;

  @override
  final bool expansionControlled;

  @override
  final Future<List<CoreTreeNode>> Function(CoreTreeNode node)? loadChildren;

  /// Overrides the default folder/file icon, with the current expansion state.
  @override
  final TreeNodeBuilder? leadingBuilder;

  /// Additional content after the label (for example a status badge).
  @override
  final TreeNodeBuilder? trailingBuilder;

  /// Content shown while children load. Defaults to the CoUI loading indicator.
  @override
  final Widget Function(BuildContext context, CoreTreeNode node)?
  loadingBuilder;

  /// Content shown on load failure. Keep the branch open to allow a retry.
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

  /// Optional controller for an opt-in virtual viewport (Flutter runtime).
  final ScrollController? scrollController;

  @override
  final CoreTreeDropCallback? onNodeDrop;

  @override
  final CoreTreeDropPredicate? canDrop;

  /// Receives OS files at the directory indicated by the hovered tree row.
  @override
  final CoreTreeFilesDropCallback<List<XFile>>? onFilesDroppedOnNode;

  /// Opt-in before/after/inside placement with a Sortable-style preview.
  @override
  final CoreTreePlaceCallback? onNodePlace;

  /// Additional consumer policy for exact placements.
  @override
  final CoreTreePlacePredicate? canPlace;

  /// Nodes like a synthetic workspace root can accept drops without moving.
  @override
  final CoreTreeDragPredicate? canDragNode;

  /// OS files placed at a precise position between or inside tree rows.
  @override
  final CoreTreeFilesPlaceCallback<List<XFile>>? onFilesPlaced;

  /// Per-instance composite style — chrome flat fields plus nested
  /// `nodeTextStyle` / `chevronIconStyle` slots. See [CoreTreeStyle]
  /// for the merge chain.
  @override
  final CoreTreeStyle? treeStyle;

  /// Returns a copy of this [Tree] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Tree copyWith({
    Key? key,
    List<CoreTreeNode>? nodes,
    bool? showRoots,
    ValueChanged<CoreTreeNode>? onNodeSelect,
    ValueChanged<CoreTreeNode>? onNodeToggle,
    CoreTreeRenameCallback? onNodeRename,
    CoreTreeRenamePredicate? canRenameNode,
    CoreTreeController? controller,
    CoreTreeNodeMenuBuilder<Widget>? nodeContextMenu,
    bool? selectFolders,
    bool? toggleFoldersOnSelect,
    bool? expansionControlled,
    Future<List<CoreTreeNode>> Function(CoreTreeNode node)? loadChildren,
    TreeNodeBuilder? leadingBuilder,
    TreeNodeBuilder? trailingBuilder,
    Widget Function(BuildContext context, CoreTreeNode node)? loadingBuilder,
    TreeLoadErrorBuilder? errorBuilder,
    double? virtualRowHeight,
    double? virtualViewportHeight,
    String? nodeKeyPrefix,
    String? selectedId,
    ScrollController? scrollController,
    CoreTreeDropCallback? onNodeDrop,
    CoreTreeDropPredicate? canDrop,
    CoreTreeFilesDropCallback<List<XFile>>? onFilesDroppedOnNode,
    CoreTreePlaceCallback? onNodePlace,
    CoreTreePlacePredicate? canPlace,
    CoreTreeDragPredicate? canDragNode,
    CoreTreeFilesPlaceCallback<List<XFile>>? onFilesPlaced,
    CoreTreeStyle? treeStyle,
  }) {
    return Tree(
      key: key ?? this.key,
      nodes: nodes ?? this.nodes,
      showRoots: showRoots ?? this.showRoots,
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
      scrollController: scrollController ?? this.scrollController,
      onNodeDrop: onNodeDrop ?? this.onNodeDrop,
      canDrop: canDrop ?? this.canDrop,
      onFilesDroppedOnNode: onFilesDroppedOnNode ?? this.onFilesDroppedOnNode,
      onNodePlace: onNodePlace ?? this.onNodePlace,
      canPlace: canPlace ?? this.canPlace,
      canDragNode: canDragNode ?? this.canDragNode,
      onFilesPlaced: onFilesPlaced ?? this.onFilesPlaced,
      treeStyle: treeStyle ?? this.treeStyle,
    );
  }

  @override
  State<Tree> createState() => _TreeState();
}

class _TreeState extends State<Tree> {
  late final String _dragPrefix = 'co-tree-${identityHashCode(this)}';
  var _expandedNodes = <int>{};
  final Map<int, List<CoreTreeNode>> _loaded = {};
  final Set<int> _loading = {};
  final Map<int, Object> _loadErrors = {};
  List<CoreTreeNode>? _cachedRoots;
  List<({CoreTreeNode? node, int depth, int key})>? _cachedVisibleRows;
  final Map<String, CoreTreeNode> _visibleParents = {};
  final Map<String, int> _visibleIndices = {};
  String? _externalOverId;
  CoreTreeDropTarget? _externalPlacement;
  CoreTreeDropTarget? _placement;
  late final DragScopeController _placementDragController =
      DragScopeController()..addListener(_handlePlacementChange);

  /// Key of the row whose label is being edited — at most one at a time.
  int? _renamingKey;

  /// The node as it was when the edit began; reported with the new label.
  CoreTreeNode? _renamingNode;

  late final TextEditingController _renameController = TextEditingController();
  late final FocusNode _renameFocusNode = FocusNode(debugLabel: 'Tree rename')
    ..addListener(_handleRenameFocusChange);

  /// Whether the field has held focus since it opened. Leaving it commits,
  /// but only once it was entered — not while it is still being mounted.
  bool _renameHadFocus = false;

  /// What had focus when the edit began, so Enter and Escape hand focus back
  /// to it instead of dropping it on the route.
  FocusNode? _focusBeforeRename;

  CoreTreeDropTarget? get _preview => _placement ?? _externalPlacement;

  CoreTreeDropTarget? _targetFor(
    CoreTreeNode node,
    CoreTreeDropPosition position,
    int depth,
  ) {
    final parent = _visibleParents[node.id];
    final directory = position == .inside ? node : parent;
    if (directory == null) return null;
    return CoreTreeDropTarget(
      anchor: node,
      directory: directory,
      position: position,
      depth: depth + (position == .inside ? 1 : 0),
    );
  }

  CoreTreeDropTarget? _targetAt(
    CoreTreeNode node,
    double pointerY,
    double rowTop,
    double rowHeight,
  ) {
    final index = _visibleIndices[node.id];
    if (index == null) return null;
    final depth = _visibleRows()[index].depth;
    final position = CoreTreeDropRules.positionAt(
      pointerY: pointerY,
      rowTop: rowTop,
      rowHeight: rowHeight,
      isBranch: _isBranch(node),
      hasParent: _visibleParents.containsKey(node.id),
    );
    return _targetFor(node, position, depth);
  }

  CoreTreeDropTarget? _placementFor(
    CoreDragSession session,
    CoreDragId? overId,
  ) {
    final node = _nodeForDragId(overId, 'zone');
    final source = _nodeForDragId(session.activeId, 'item');
    final rect = overId == null
        ? null
        : _placementDragController.registry.dropZoneRects[overId];
    if (node == null || source == null || rect == null) return null;
    final target = _targetAt(node, session.pointer.y, rect.top, rect.height);
    if (target == null ||
        !CoreTreeDropRules.acceptsPlacement(
          source,
          target,
          childrenOf: (row) => _childrenOf(_keyOf(row, 0, 0), row),
        ) ||
        !(widget.canPlace?.call(source, target) ?? true)) {
      return null;
    }
    return target;
  }

  void _handlePlacementChange() {
    if (!mounted || widget.onNodePlace == null) return;
    final session = _placementDragController.session;
    final next = session == null
        ? null
        : _placementFor(session, _placementDragController.overId);
    if (next != _placement) setState(() => _placement = next);
  }

  int? _previewInsertionIndex() {
    final preview = _preview;
    if (preview == null) return null;
    final rows = _visibleRows();
    final index = _visibleIndices[preview.anchor.id];
    if (index == null) return null;
    if (preview.position == .before) return index;
    if (preview.position == .inside) return index + 1;
    var after = index + 1;
    final depth = rows[index].depth;
    while (after < rows.length && rows[after].depth > depth) {
      after++;
    }
    return after;
  }

  double _previewHeight(double rowSpacing) {
    if (_preview == null) return 0;
    final height =
        (widget.virtualRowHeight ??
            CoreTreeContract.defaultEstimatedRowHeight) +
        rowSpacing;
    final source = _placementDragController.session;
    if (source == null) return height;
    final id = _nodeForDragId(source.activeId, 'item')?.id;
    final index = _visibleIndices[id];
    if (index == null) return height;
    final rows = _visibleRows();
    final depth = rows[index].depth;
    var end = index + 1;
    while (end < rows.length && rows[end].depth > depth) {
      end++;
    }
    return (end - index) * height;
  }

  @override
  void dispose() {
    widget.controller?.removeRenameListener(_handleRenameRequest);
    _placementDragController
      ..removeListener(_handlePlacementChange)
      ..dispose();
    _renameFocusNode
      ..removeListener(_handleRenameFocusChange)
      ..dispose();
    _renameController.dispose();
    super.dispose();
  }

  /// Key of the node row currently under the pointer — drives the real
  /// per-node hover background (Web `hover:bg-` parity). `null` when no
  /// row is hovered.
  int? _hoveredKey;

  int _keyOf(CoreTreeNode node, int depth, int index) => node.id == null
      ? Object.hash(depth, index, node.label)
      : Object.hash('tree-node', node.id);

  List<CoreTreeNode> _childrenOf(int key, CoreTreeNode node) =>
      node.children.isNotEmpty ? node.children : (_loaded[key] ?? const []);

  bool _isBranch(CoreTreeNode node) =>
      node.canHaveChildren || node.children.isNotEmpty;

  bool _isSelected(CoreTreeNode node) =>
      widget.selectedId == null ? node.selected : node.id == widget.selectedId;

  CoreDragId _itemId(String id) => CoreDragId('$_dragPrefix:item:$id');
  CoreDragId _zoneId(String id) => CoreDragId('$_dragPrefix:zone:$id');

  CoreTreeNode? _nodeForDragId(CoreDragId? id, String kind) {
    final prefix = '$_dragPrefix:$kind:';
    if (id == null || !id.value.startsWith(prefix)) return null;
    final nodeId = id.value.substring(prefix.length);
    for (final row in _visibleRows()) {
      if (row.node?.id == nodeId) return row.node;
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
        (widget.canDrop?.call(source, destination) ?? true);
  }

  CoreTreeNode? _dropDirectory(CoreTreeNode row) {
    if (_isBranch(row)) return row;
    _visibleRows();
    return row.id == null ? null : _visibleParents[row.id];
  }

  void _handleDrop(CoreTreeNode source, CoreDragEndEvent event) {
    if (widget.onNodePlace != null) {
      final target = _placementFor(event.session, event.overId);
      if (target != null) widget.onNodePlace?.call(source, target);
      return;
    }
    final row = _nodeForDragId(event.overId, 'zone');
    final destination = row == null ? null : _dropDirectory(row);
    if (destination != null && _acceptsDrop(source, destination)) {
      widget.onNodeDrop?.call(source, destination);
    }
  }

  @override
  void initState() {
    super.initState();
    _initExpanded(widget.nodes, 0);
    _scheduleInitialLoads();
    widget.controller?.addRenameListener(_handleRenameRequest);
  }

  @override
  void didUpdateWidget(Tree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showRoots != widget.showRoots) _cachedVisibleRows = null;
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?.removeRenameListener(_handleRenameRequest);
      widget.controller?.addRenameListener(_handleRenameRequest);
    }
    if (!identical(oldWidget.nodes, widget.nodes)) {
      _cachedVisibleRows = null;
      _scheduleInitialLoads();
    }
    // The consumer withdrew rename while a field was open — close it
    // without reporting; there is no one left to report to. A build
    // follows this call, so the fields are reset without `setState`.
    if (widget.onNodeRename == null && _renamingKey != null) {
      _renameHadFocus = false;
      _focusBeforeRename = null;
      _renamingKey = null;
      _renamingNode = null;
    }
  }

  void _scheduleInitialLoads() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

      visit(widget.nodes, 0);
    });
  }

  void _initExpanded(List<CoreTreeNode> nodes, int depth) {
    for (var i = 0; i < nodes.length; i++) {
      final key = _keyOf(nodes[i], depth, i);
      if (nodes[i].expanded && _isBranch(nodes[i])) {
        _expandedNodes = {..._expandedNodes, key};
      }
      if (nodes[i].children.isNotEmpty) {
        _initExpanded(nodes[i].children, depth + 1);
      }
    }
  }

  bool _isExpanded(int key, CoreTreeNode node) {
    if (widget.expansionControlled) {
      return node.expanded;
    }
    return _expandedNodes.contains(key);
  }

  void _handleToggle(int key, CoreTreeNode node) {
    final opening = !_isExpanded(key, node);
    _cachedVisibleRows = null;
    if (!widget.expansionControlled) {
      setState(() {
        if (_expandedNodes.contains(key)) {
          _expandedNodes = {..._expandedNodes.where((e) => e != key)};
        } else {
          _expandedNodes = {..._expandedNodes, key};
        }
      });
    }
    widget.onNodeToggle?.call(node);
    if (opening && node.children.isEmpty && !_loaded.containsKey(key)) {
      unawaited(_loadNode(key, node));
    }
  }

  bool _canRename(CoreTreeNode node) =>
      widget.onNodeRename != null && (widget.canRenameNode?.call(node) ?? true);

  /// [CoreTreeController.startRename] — the path a double-click takes, so the
  /// opening selection and the focus hand-back are the same. Only a visible
  /// row can open: its field must mount to take focus.
  void _handleRenameRequest(String nodeId) {
    final rows = _visibleRows();
    final index = _visibleIndices[nodeId];
    if (index == null) return;
    final row = rows[index];
    final node = row.node;
    if (node != null) _startRename(row.key, node);
  }

  void _startRename(int key, CoreTreeNode node) {
    if (!_canRename(node) || _renamingKey == key) return;
    // One field at a time — an edit still open elsewhere keeps its text.
    if (_renamingKey != null) _handleRenameCommit();
    final label = node.label;
    _renameController.value = TextEditingValue(
      text: label,
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: CoreTreeRenameRules.selectionEnd(
          label,
          isBranch: _isBranch(node),
        ),
      ),
    );
    _renameHadFocus = false;
    _focusBeforeRename = FocusManager.instance.primaryFocus;
    setState(() {
      _renamingKey = key;
      _renamingNode = node;
      _hoveredKey = null;
    });
    // The field mounts with this frame; focus can only land after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _renamingKey == key) _renameFocusNode.requestFocus();
    });
  }

  void _handleRenameFocusChange() {
    if (_renameFocusNode.hasFocus) {
      if (_renameHadFocus) return;
      _renameHadFocus = true;
      // On desktop and web, EditableText selects the whole text when focus
      // arrives (its platform default) — from a listener that runs after
      // this one. Put the opening selection back once it has: typing must
      // replace the stem, not the extension too.
      final opening = _renameController.selection;
      scheduleMicrotask(() {
        if (_renameFocusNode.hasFocus && _renamingKey != null) {
          _renameController.selection = opening;
        }
      });
    } else if (_renameHadFocus) {
      // Clicking elsewhere keeps what was typed — the file-explorer idiom.
      _handleRenameCommit();
    }
  }

  void _handleRenameCommit() {
    final node = _renamingNode;
    if (node == null) return;
    final label = CoreTreeRenameRules.committedLabel(
      node,
      _renameController.text,
    );
    _endRename();
    if (label != null) widget.onNodeRename?.call(node, label);
  }

  void _endRename() {
    if (_renamingKey == null) return;
    // Cleared first: handing focus back below blurs the field, and that
    // blur must not commit a second time.
    _renameHadFocus = false;
    final restore = _renameFocusNode.hasFocus ? _focusBeforeRename : null;
    _focusBeforeRename = null;
    setState(() {
      _renamingKey = null;
      _renamingNode = null;
    });
    if (restore != null && restore.context != null) restore.requestFocus();
  }

  Future<void> _loadNode(int key, CoreTreeNode node) async {
    final loader = widget.loadChildren;
    if (loader == null || !_loading.add(key)) return;
    _cachedVisibleRows = null;
    setState(() => _loadErrors.remove(key));
    try {
      final children = await loader(node);
      if (!mounted) return;
      _cachedVisibleRows = null;
      setState(() {
        _loaded[key] = children;
        _loading.remove(key);
      });
    } on Object catch (error) {
      if (!mounted) return;
      _cachedVisibleRows = null;
      setState(() {
        _loading.remove(key);
        _loadErrors[key] = error;
      });
    }
  }

  Widget _chevron({
    required ResolvedTree resolved,
    required bool isExpanded,
    required VoidCallback? onToggle,
    required Key toggleKey,
  }) {
    final icon = AnimatedRotation(
      turns: isExpanded ? resolved.expandedTurns : 0,
      duration: resolved.transitionDuration,
      curve: CoreEasing.move.toValue(),
      child: Icon(
        LucideIcons.chevronRight,
        iconStyle: resolved.chevronIconStyle,
      ),
    );
    if (onToggle == null) {
      return icon;
    }
    return Clickable(
      key: toggleKey,
      onPressed: onToggle,
      clickableStyle: resolved.clickableStyle,
      child: icon,
    );
  }

  /// F2 on a focused row opens rename — the keyboard path to what a
  /// double-click does, so renaming is not pointer-only.
  Widget _renameShortcut(VoidCallback? start, Widget row) => start == null
      ? row
      : CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.f2): start},
          child: row,
        );

  /// The inline rename field that stands in for the label.
  Widget _renameField(ResolvedTree resolved) {
    final field = TextField(
      controller: _renameController,
      focusNode: _renameFocusNode,
      textFieldStyle: resolved.renameFieldStyle,
      onSubmitted: (_) => _handleRenameCommit(),
      // A desktop field keeps focus when the pointer goes down elsewhere;
      // without this, clicking away would leave the edit hanging open.
      onTapOutside: (_) => _handleRenameCommit(),
    );

    // Keys typed into the field belong to the field. Without this stop an
    // ancestor's key handler — a consumer's tree keyboard model, a row's
    // activation shortcuts — turns Space into a selection and the arrows
    // into navigation while the user is typing a name. The text-editing
    // shortcuts are provided again below the stop, because their app-level
    // copy now sits above it. Everything left unhandled still reaches the
    // platform text input, so typing, IME composition and Enter are intact.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _endRename();

          return KeyEventResult.handled;
        }

        return KeyEventResult.skipRemainingHandlers;
      },
      // On macOS, Escape in a text field never arrives here as a key: the
      // text-editing shortcuts hand it to the platform, which answers with
      // the `cancelOperation:` selector — delivered as a DismissIntent from
      // the field (as Return comes back as a submit). Catch it here too.
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              _endRename();

              return null;
            },
          ),
        },
        child: DefaultTextEditingShortcuts(child: field),
      ),
    );
  }

  Widget _buildRow(
    CoreTreeNode node,
    int depth,
    int key,
    ResolvedTree resolved,
  ) {
    final indent = resolved.indent;
    final itemPadding = resolved.itemPadding;
    final nodeBg = resolved.nodeBackgroundColor;
    final nodeHover = resolved.nodeHoverColor;

    final isExpanded = _isExpanded(key, node);
    final hasKids = _isBranch(node);
    final dropDirectory =
        node.id != null &&
            (widget.onNodeDrop != null ||
                widget.onNodePlace != null ||
                widget.onFilesDroppedOnNode != null ||
                widget.onFilesPlaced != null)
        ? _dropDirectory(node)
        : null;

    final hasLeafHandler = !hasKids && widget.onNodeSelect != null;
    final selectOnRow =
        hasLeafHandler ||
        (hasKids && widget.selectFolders && widget.onNodeSelect != null);
    // A selectable folder row toggles too only when asked — selecting a
    // delegation target must not reflow the tree unless the consumer opted
    // into the file-explorer idiom.
    final toggleOnRow =
        hasKids && (!widget.selectFolders || widget.toggleFoldersOnSelect);
    final toggleOnChevron = hasKids && widget.selectFolders;
    final rowPress = selectOnRow && toggleOnRow
        ? () {
            widget.onNodeSelect!(node);
            _handleToggle(key, node);
          }
        : selectOnRow
        ? () => widget.onNodeSelect!(node)
        : toggleOnRow
        ? () => _handleToggle(key, node)
        : null;
    final isRenaming = _renamingKey == key;
    final renamable = _canRename(node);
    final clickable = rowPress != null || renamable;

    // Paint-ready per-state style — the resolver composed the
    // typography, colours and the chevron plus leading-icon slots; the
    // build below only picks selected or unselected and renders.
    final textStyle = _isSelected(node)
        ? resolved.nodeSelectedTextStyle
        : resolved.nodeTextStyle;

    // Row background — the selected face wins; otherwise the hover fill
    // (real per-node hover via Clickable.onHover, mirroring the Web
    // row's `hover:bg-` CSS) when this row is hovered and a hover colour
    // is set, else the plain node background.
    final isHovered = _hoveredKey == key;
    final Color? backgroundColor;
    if (_isSelected(node)) {
      backgroundColor = resolved.nodeSelectedColor;
    } else if (isHovered && nodeHover != null) {
      backgroundColor = nodeHover;
    } else {
      backgroundColor = nodeBg;
    }

    Widget rowContent = Container(
      constraints: BoxConstraints(minHeight: resolved.nodeMinHeight),
      padding: itemPadding + .only(left: indent * depth),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: resolved.borderRadius,
      ),
      child: Row(
        children: [
          if (hasKids)
            _chevron(
              resolved: resolved,
              isExpanded: isExpanded,
              onToggle: toggleOnChevron ? () => _handleToggle(key, node) : null,
              toggleKey: Key(
                node.id == null
                    ? 'tree-chevron-${node.label}'
                    : '${widget.nodeKeyPrefix ?? 'tree-node'}'
                          '.toggle.${node.id}',
              ),
            )
          else
            // A leaf has no chevron, so it keeps the chevron's place — a
            // glyph-wide slot, not a gap, so the density moves only the
            // gaps on either side and the leaf stays in line with its
            // parent siblings.
            SizedBox(width: resolved.chevronSlotWidth),
          Gap(gapStyle: resolved.iconGapStyle),
          if (widget.leadingBuilder case final builder?)
            builder(context, node, expanded: isExpanded)
          else if (hasKids)
            Icon(
              isExpanded ? LucideIcons.folderOpen : LucideIcons.folderClosed,
              iconStyle: resolved.iconStyle,
            )
          else
            Icon(LucideIcons.file, iconStyle: resolved.leafIconStyle),
          Gap(gapStyle: resolved.labelGapStyle),
          // Single-line + ellipsis (file-explorer idiom): wrapping a
          // node name degrades into per-letter stacks in narrow trees
          // and balloons the tree height. `Flexible` bounds the label
          // to the remaining row width so the ellipsis can engage —
          // mirrors the Web twin's `min-w-0 truncate`.
          // With a trailing widget the name takes the remaining width, so
          // the trailing sits at the row's end; without one the name only
          // takes what it needs (`Flexible`).
          if (isRenaming)
            Expanded(child: _renameField(resolved))
          else if (widget.trailingBuilder != null)
            Expanded(
              child: Text(
                node.label,
                style: textStyle,
                overflow: .ellipsis,
                maxLines: 1,
              ),
            )
          else
            Flexible(
              child: Text(
                node.label,
                style: textStyle,
                overflow: .ellipsis,
                maxLines: 1,
              ),
            ),
          if (widget.trailingBuilder case final builder?) ...[
            Gap(gapStyle: resolved.labelGapStyle),
            builder(context, node, expanded: isExpanded),
          ],
        ],
      ),
    );

    // Move the painted row, not the measured DropZone/DragItem wrapper.
    // Otherwise the hit rectangle follows the gap and the target jitters.
    if (widget.onNodePlace != null || widget.onFilesPlaced != null) {
      final index = _visibleIndices[node.id];
      final insert = _previewInsertionIndex();
      if (index != null && insert != null && index >= insert) {
        rowContent = AnimatedContainer(
          transform: Matrix4.translationValues(
            0,
            _previewHeight(resolved.rowSpacing),
            0,
          ),
          duration: const Duration(milliseconds: CoreDuration.fast),
          curve: CoreEasing.move.toValue(),
          child: rowContent,
        );
      }
      if (index != null && index == insert) {
        rowContent = Stacks(
          children: [
            rowContent,
            Position(
              top: 0,
              left: resolved.indent * _preview!.depth,
              right: 0,
              child: ColoredBox(
                color: resolved.dropIndicatorColor,
                child: const SizedBox(height: CoreStrokeWidth.stroke2),
              ),
            ),
          ],
        );
      }
    }

    Widget row = KeyedSubtree(
      key: node.id == null
          ? null
          : Key('${widget.nodeKeyPrefix ?? 'tree-node'}.${node.id}'),
      child:
          // Non-interactive rows (a leaf with no onNodeSelect) render bare
          // — no Clickable, so they keep the default cursor and never fade.
          // A display-only tree is content, not a disabled control (chip
          // and dock precedent). Interactive rows compose Clickable, which
          // owns tap, keyboard activation, cursor and focus ring
          // (press-shrink stays off via the tree's partial clickableStyle
          // so the full-width row does not jump). Hover flows back through
          // onHover so the row picks the pre-resolved hover fill — the
          // Flutter twin of the Web row's hover:bg- CSS.
          //
          // A row being renamed renders bare too: the field owns the
          // pointer and the keys until the edit ends, and a press or a
          // drag starting under it would act on the row instead.
          clickable && !isRenaming
          ? _renameShortcut(
              renamable ? () => _startRename(key, node) : null,
              Clickable(
                // A rename-only row still needs a press: Clickable counts
                // taps inside its press handler, so without one the second
                // tap of a double-tap is never seen.
                onPressed: rowPress ?? () {},
                onDoubleTap: renamable ? () => _startRename(key, node) : null,
                onHover: nodeHover != null
                    ? (hovered) {
                        setState(() {
                          if (hovered) {
                            _hoveredKey = key;
                          } else if (_hoveredKey == key) {
                            _hoveredKey = null;
                          }
                        });
                      }
                    : null,
                clickableStyle: resolved.clickableStyle,
                child: rowContent,
              ).expandedWhen(expanded: hasKids ? isExpanded : null),
            )
          : rowContent,
    );
    // Always present, flag only when selected (`null` states nothing): the
    // row's subtree must not change shape when selection moves onto it. A
    // wrapper that appears on selection rebuilds the row's Clickable from
    // scratch, so with a controlled `selectedId` the first press of a
    // double-tap reset the tap count and the second never reached
    // `onDoubleTap` — and a focused row lost its focus the same way.
    row = CoUISemantics(selected: _isSelected(node) ? true : null, child: row);
    // Present whenever a builder is given and enabled only with entries —
    // for the same reason: a wrapper that came and went with the entries
    // would rebuild the row's Clickable and drop its tap count. A row being
    // renamed has none: a right-click in its field is text editing's.
    if (widget.nodeContextMenu case final menu?) {
      final items = isRenaming ? const <CoreMenuItem<Widget>>[] : menu(node);
      row = ContextMenu(items: items, enabled: items.isNotEmpty, child: row);
    }
    if ((widget.onNodeDrop != null || widget.onNodePlace != null) &&
        node.id != null &&
        !isRenaming) {
      final id = node.id!;
      if (dropDirectory != null || widget.onNodePlace != null) {
        row = DropZone(
          id: _zoneId(id),
          data: node,
          builder: (context, details, child) {
            final source = _nodeForDragId(details.activeId, 'item');
            final isValid =
                widget.onNodePlace == null &&
                details.isOver &&
                source != null &&
                dropDirectory != null &&
                _acceptsDrop(source, dropDirectory);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: isValid && hasKids ? resolved.dropTargetColor : null,
                border: isValid && !hasKids
                    ? Border(
                        top: BorderSide(
                          color: resolved.dropIndicatorColor,
                          width: CoreStrokeWidth.stroke2,
                        ),
                      )
                    : null,
                borderRadius: hasKids ? resolved.borderRadius : null,
              ),
              child: child,
            );
          },
          child: row,
        );
      }
      if (widget.canDragNode?.call(node) ?? true) {
        row = DragItem(
          id: _itemId(id),
          data: node,
          label: node.label,
          onDragEnd: (event) => _handleDrop(node, event),
          child:
              widget.onNodePlace != null &&
                  _placementDragController.activeId == _itemId(id)
              ? Opacity(opacity: 0, child: row)
              : row,
        );
      }
    }
    if ((widget.onFilesDroppedOnNode != null || widget.onFilesPlaced != null) &&
        dropDirectory != null &&
        !isRenaming) {
      final id = node.id!;
      row = DropTarget(
        onDragEntered: (details) {
          final target = _externalTargetAt(node, details.localPosition.dy);
          setState(() {
            _externalOverId = id;
            _externalPlacement = target;
          });
        },
        onDragUpdated: (details) {
          final target = _externalTargetAt(node, details.localPosition.dy);
          if (_externalPlacement != target) {
            setState(() => _externalPlacement = target);
          }
        },
        onDragExited: (_) {
          if (_externalOverId == id) {
            setState(() {
              _externalOverId = null;
              _externalPlacement = null;
            });
          }
        },
        onDragDone: (details) {
          final target = _externalTargetAt(node, details.localPosition.dy);
          if (_externalOverId == id) {
            setState(() {
              _externalOverId = null;
              _externalPlacement = null;
            });
          }
          final files = details.files.whereType<DropItemFile>().toList();
          if (files.isNotEmpty) {
            if (widget.onFilesPlaced case final callback?) {
              if (target != null) callback(files, target);
            } else {
              widget.onFilesDroppedOnNode?.call(files, dropDirectory);
            }
          }
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _externalOverId == id && hasKids
                ? resolved.dropTargetColor
                : null,
            border: _externalOverId == id && !hasKids
                ? Border(
                    top: BorderSide(
                      color: resolved.dropIndicatorColor,
                      width: CoreStrokeWidth.stroke2,
                    ),
                  )
                : null,
            borderRadius: hasKids ? resolved.borderRadius : null,
          ),
          child: row,
        ),
      );
    }
    return row;
  }

  CoreTreeDropTarget? _externalTargetAt(CoreTreeNode node, double localY) {
    if (widget.onFilesPlaced == null) return null;
    return _targetAt(
      node,
      localY,
      0,
      widget.virtualRowHeight ?? CoreTreeContract.defaultEstimatedRowHeight,
    );
  }

  Widget _buildDragProxy(
    BuildContext scopeContext,
    CoreDragSession session,
    ResolvedTree resolved,
  ) {
    final node = _nodeForDragId(session.activeId, 'item');
    final rect = _placementDragController.registry.itemRects[session.activeId];
    if (node == null || rect == null) return const SizedBox.shrink();
    final index = _visibleIndices[node.id];
    if (index == null) return const SizedBox.shrink();
    final visible = _visibleRows()[index];
    final hasKids = _isBranch(node);
    return Theme(
      data: Theme.of(scopeContext),
      child: SizedBox(
        width: rect.width,
        height: rect.height,
        child: Container(
          constraints: BoxConstraints(minHeight: resolved.nodeMinHeight),
          decoration: BoxDecoration(
            color: Theme.of(scopeContext).colorScheme.surface.toValue(),
            borderRadius: resolved.borderRadius,
            boxShadow: [
              BoxShadow(
                color: Theme.of(scopeContext).colorScheme.shadow
                    .toValue()
                    .withValues(alpha: CoreOpacity.opacity20),
                blurRadius: CoreSpace.space8,
              ),
            ],
          ),
          padding:
              resolved.itemPadding +
              EdgeInsets.only(left: resolved.indent * visible.depth),
          child: Row(
            children: [
              if (hasKids)
                Icon(
                  _isExpanded(visible.key, node)
                      ? LucideIcons.folderOpen
                      : LucideIcons.folderClosed,
                  iconStyle: resolved.iconStyle,
                )
              else
                Icon(LucideIcons.file, iconStyle: resolved.leafIconStyle),
              Gap(gapStyle: resolved.labelGapStyle),
              Flexible(
                child: Text(
                  node.label,
                  style: resolved.nodeTextStyle,
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _statusRow(
    CoreTreeNode node,
    int key,
    int depth,
    ResolvedTree resolved,
  ) {
    final error = _loadErrors[key];
    if (!_loading.contains(key) && error == null) return null;
    return Padding(
      padding: EdgeInsets.only(left: resolved.indent * (depth + 1)),
      child: error == null
          ? (widget.loadingBuilder?.call(context, node) ??
                Text(CoUILocalizations.of(context).loadingLabel))
          : Clickable(
              onPressed: () => unawaited(_loadNode(key, node)),
              child:
                  widget.errorBuilder?.call(context, node, error) ??
                  const Text('Unable to load · Retry'),
            ),
    );
  }

  List<Widget> _buildNodes(
    List<CoreTreeNode> nodes,
    int depth,
    ResolvedTree resolved,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final key = _keyOf(node, depth, i);
      final hidden = !widget.showRoots && depth == 0;
      final visualDepth = widget.showRoots ? depth : depth - 1;
      if (!hidden) widgets.add(_buildRow(node, visualDepth, key, resolved));
      if (_isBranch(node) && _isExpanded(key, node)) {
        final status = _statusRow(
          node,
          key,
          hidden ? 0 : visualDepth,
          resolved,
        );
        if (status != null) widgets.add(status);
        widgets.addAll(
          _buildNodes(_childrenOf(key, node), depth + 1, resolved),
        );
      }
    }
    return widgets;
  }

  CoreTreeNode? _nodeForStatus(int wanted) {
    CoreTreeNode? visit(List<CoreTreeNode> nodes, int depth) {
      for (var index = 0; index < nodes.length; index++) {
        final node = nodes[index];
        final key = _keyOf(node, depth, index);
        if (key == wanted) return node;
        final found = visit(_childrenOf(key, node), depth + 1);
        if (found != null) return found;
      }
      return null;
    }

    return visit(widget.nodes, 0);
  }

  List<({CoreTreeNode? node, int depth, int key})> _visibleRows() {
    if (identical(_cachedRoots, widget.nodes) && _cachedVisibleRows != null) {
      return _cachedVisibleRows!;
    }
    final rows = <({CoreTreeNode? node, int depth, int key})>[];
    _visibleParents.clear();
    _visibleIndices.clear();
    void visit(List<CoreTreeNode> nodes, int depth, CoreTreeNode? parent) {
      for (var i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        final key = _keyOf(node, depth, i);
        if (node.id != null && parent != null) {
          _visibleParents[node.id!] = parent;
        }
        final hidden = !widget.showRoots && depth == 0;
        final visualDepth = widget.showRoots ? depth : depth - 1;
        if (!hidden) {
          if (node.id != null) _visibleIndices[node.id!] = rows.length;
          rows.add((node: node, depth: visualDepth, key: key));
        }
        if (_isBranch(node) && _isExpanded(key, node)) {
          if (_loading.contains(key) || _loadErrors.containsKey(key)) {
            rows.add((node: null, depth: hidden ? 0 : visualDepth, key: key));
          }
          visit(_childrenOf(key, node), depth + 1, node);
        }
      }
    }

    visit(widget.nodes, 0, null);
    _cachedRoots = widget.nodes;
    _cachedVisibleRows = rows;
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveTree(context, treeStyle: widget.treeStyle);

    if (widget.onNodePlace != null || widget.onFilesPlaced != null) {
      _visibleRows();
    }

    if (widget.virtualRowHeight case final height?) {
      final rows = _visibleRows();
      Widget rowAt(BuildContext context, int index) {
        final row = rows[index];
        final node = row.node;
        if (node == null) {
          final parent = _nodeForStatus(row.key)!;
          return _statusRow(parent, row.key, row.depth, resolved)!;
        }
        return _buildRow(node, row.depth, row.key, resolved);
      }

      final list = CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          if (resolved.rowSpacing == 0)
            SliverFixedExtentList.builder(
              itemExtent: height,
              itemCount: rows.length,
              itemBuilder: rowAt,
            )
          else
            SliverVariedExtentList.builder(
              itemCount: rows.length,
              itemExtentBuilder: (index, dimensions) =>
                  height + (index + 1 < rows.length ? resolved.rowSpacing : 0),
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index + 1 < rows.length ? resolved.rowSpacing : 0,
                ),
                child: rowAt(context, index),
              ),
            ),
          if (_preview != null)
            SliverToBoxAdapter(
              child: SizedBox(
                height: _previewHeight(resolved.rowSpacing),
                child: Stacks(
                  children: [
                    Position(
                      top: 0,
                      left: resolved.indent * _preview!.depth,
                      right: 0,
                      child: ColoredBox(
                        color: resolved.dropIndicatorColor,
                        child: const SizedBox(height: CoreStrokeWidth.stroke2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
      // In a windowed tree, the scroll view's mouse-drag recognizer
      // otherwise wins before the row's DragItem. Wheel/trackpad
      // scrolling remains available; touch scrolling keeps its own gesture.
      final Widget viewport;
      if (widget.onNodeDrop != null || widget.onNodePlace != null) {
        final behavior = ScrollConfiguration.of(context);
        viewport = ScrollConfiguration(
          behavior: behavior.copyWith(
            dragDevices: {...behavior.dragDevices}
              ..remove(PointerDeviceKind.mouse),
          ),
          child: list,
        );
      } else {
        viewport = list;
      }
      final tree = SizedBox(
        height: widget.virtualViewportHeight,
        child: viewport,
      );
      if (widget.onNodePlace != null) {
        return DragScope(
          controller: _placementDragController,
          child: Stacks(
            clipBehavior: .none,
            children: [
              tree,
              Builder(
                builder: (scopeContext) => DragOverlay(
                  builder: (_, session) =>
                      _buildDragProxy(scopeContext, session, resolved),
                ),
              ),
            ],
          ),
        );
      }
      return widget.onNodeDrop != null && DragScope.maybeOf(context) == null
          ? DragScope(child: tree)
          : tree;
    }
    final tree = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: resolved.rowSpacing,
      children: [
        ..._buildNodes(widget.nodes, 0, resolved),
        if (_preview != null)
          Stacks(
            children: [
              SizedBox(height: _previewHeight(resolved.rowSpacing)),
              Position(
                top: 0,
                left: resolved.indent * _preview!.depth,
                right: 0,
                child: ColoredBox(
                  color: resolved.dropIndicatorColor,
                  child: const SizedBox(height: CoreStrokeWidth.stroke2),
                ),
              ),
            ],
          ),
      ],
    );
    if (widget.onNodePlace != null) {
      return DragScope(
        controller: _placementDragController,
        child: Stacks(
          fit: .passthrough,
          clipBehavior: .none,
          children: [
            tree,
            Builder(
              builder: (scopeContext) => DragOverlay(
                builder: (_, session) =>
                    _buildDragProxy(scopeContext, session, resolved),
              ),
            ),
          ],
        ),
      );
    }
    return widget.onNodeDrop != null && DragScope.maybeOf(context) == null
        ? DragScope(child: tree)
        : tree;
  }
}

/// Chain sugar for merging a [CoreTreeStyle] patch into
/// [Tree.treeStyle] without hand-reconstructing every field. Mirrors
/// the Web `Tree.withStyle` extension so both platforms read
/// identically.
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

/// Sugar for the one place a tree row needs it.
///
/// Only a node with children expands; a leaf that states `false` would
/// announce "collapsed, activate to open" for something that opens
/// nothing, so the caller passes null there and this wraps nothing.
extension on Widget {
  Widget expandedWhen({required bool? expanded}) =>
      expanded == null ? this : CoUISemantics(expanded: expanded, child: this);
}
