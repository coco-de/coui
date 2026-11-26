/// Platform-independent contract for unified tree components.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/tree/core_tree_controller.dart';
import 'package:coui_core/src/component/contracts/tree/core_tree_node.dart';
import 'package:coui_core/src/component/contracts/tree/tree_drop.dart';
import 'package:coui_core/src/component/contracts/tree/tree_node_builders.dart';
import 'package:coui_core/src/component/contracts/tree/tree_rename.dart';
import 'package:coui_core/src/component/contracts/tree/tree_style.dart';
import 'package:coui_core/src/size/size.dart';

/// Contract for a unified tree component.
///
/// `W` is the platform widget type (Flutter `Widget`, Web `Component`) — the
/// node builders return it.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [treeStyle] field — see [CoreTreeStyle].
abstract interface class CoreTreeContract<W> {
  /// The height a row is taken to have where the tree measures none — the
  /// gap the drop preview opens, and the zones a dropped file is sorted
  /// into, while [virtualRowHeight] is absent.
  ///
  /// Not a control row and not spacing: an estimate of the tree's own row,
  /// near a label line (the `codeSm` role's fixed 21px line box) inside the
  /// node padding's 4px block inset (29px) — a round number a little above
  /// it rather than a derivation, so a role change does not move it. A theme
  /// density does not move that row — the inset sits on the density's
  /// floor — so this does not move either, on both platforms; a ladder rung
  /// here would open a preview gap taller or shorter than the rows around
  /// it.
  static const double defaultEstimatedRowHeight = CoreSize.size32;

  /// Root nodes of the tree.
  List<CoreTreeNode> get nodes;

  /// Whether the supplied root rows are visible. Defaults to true.
  ///
  /// When false, children of expanded roots start at visual depth zero.
  /// Hidden roots retain their identity for placement and file drops.
  bool get showRoots;

  /// Called when a node is selected.
  ///
  /// Default: leaf nodes only. When [selectFolders] is true, parent
  /// labels also fire this callback (the disclosure chevron still
  /// toggles expansion).
  CoreValueChanged<CoreTreeNode>? get onNodeSelect;

  /// Called when a parent node is expanded or collapsed.
  CoreValueChanged<CoreTreeNode>? get onNodeToggle;

  /// When true, a parent label click selects ([onNodeSelect]) instead
  /// of toggling. Disclosure still toggles. Default false.
  bool get selectFolders;

  /// When true together with [selectFolders], a parent row press selects
  /// ([onNodeSelect]) **and** toggles the branch — the file-explorer idiom
  /// where the whole row opens a folder that is also a selection target.
  /// The disclosure chevron still only toggles. Without [selectFolders]
  /// the row already toggles, so this has no effect. Default false.
  bool get toggleFoldersOnSelect;

  /// Opt-in inline rename.
  ///
  /// Double-clicking a row, or pressing F2 while a row has focus, swaps its
  /// label for a text field holding the current label. Enter or moving focus
  /// away commits; Escape cancels. Only a label that passes
  /// [CoreTreeRenameRules.committedLabel] is reported — the consumer owns the
  /// rename and passes the renamed node back. A double-click still delivers
  /// its first press as usual, so single clicks are never delayed.
  CoreTreeRenameCallback? get onNodeRename;

  /// Consumer policy for [onNodeRename]. Absent means every row may be
  /// renamed.
  CoreTreeRenamePredicate? get canRenameNode;

  /// Commands from outside the tree — [CoreTreeController.startRename] opens
  /// a row's rename field for a consumer whose keyboard model lives outside
  /// the rows. Absent means only a double-click or row-focus F2 starts one.
  CoreTreeController? get controller;

  /// When true, expansion follows [CoreTreeNode.expanded] every build
  /// and is not stored inside the widget. Default false (internal set,
  /// seeded once from `expanded`).
  bool get expansionControlled;

  /// Called on first expansion of a branch without supplied children.
  /// Loaded children are cached by [CoreTreeNode.id] (or node identity).
  Future<List<CoreTreeNode>> Function(CoreTreeNode node)? get loadChildren;

  /// Replaces the folder / file glyph before a row's label, given whether
  /// the node's branch is open.
  CoreTreeNodeBuilder<W>? get leadingBuilder;

  /// Content after a row's label — a status mark such as a file's
  /// version-control state.
  CoreTreeNodeBuilder<W>? get trailingBuilder;

  /// The row a branch shows while [loadChildren] runs. Absent shows the
  /// kit's loading indicator.
  CoreTreeLoadingBuilder<W>? get loadingBuilder;

  /// The row a branch shows when [loadChildren] fails. The branch stays
  /// open so a retry can run.
  CoreTreeLoadErrorBuilder<W>? get errorBuilder;

  /// Fixed row height and viewport height for opt-in windowed rendering.
  /// Both must be supplied together; absent values retain the original tree.
  ///
  /// The caller's statement of the row extent, which the windowed layout
  /// computes positions from — it stays as stated under every density.
  double? get virtualRowHeight;

  /// Height of the windowed viewport in logical pixels.
  double? get virtualViewportHeight;

  /// Prefix used for stable node keys when [CoreTreeNode.id] is supplied.
  String? get nodeKeyPrefix;

  /// Controlled selection by stable node id. When null, each node's
  /// [CoreTreeNode.selected] value keeps its original meaning.
  String? get selectedId;

  /// Reports a valid node-to-branch drop. The consumer owns any mutation.
  CoreTreeDropCallback? get onNodeDrop;

  /// Additional consumer policy (permissions, locked nodes, etc.).
  CoreTreeDropPredicate? get canDrop;

  /// Opt-in exact before/after/inside move or reorder intent.
  CoreTreePlaceCallback? get onNodePlace;

  /// Consumer policy for the exact placement intent.
  CoreTreePlacePredicate? get canPlace;

  /// Whether the node can begin a drag (independent of destination policy).
  CoreTreeDragPredicate? get canDragNode;

  /// Per-instance tree chrome / dimensional / slot style.
  CoreTreeStyle? get treeStyle;
}
