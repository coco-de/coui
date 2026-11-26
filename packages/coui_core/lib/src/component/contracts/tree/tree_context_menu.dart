/// Per-node context menu for the unified tree.
library;

import 'package:coui_core/src/component/contracts/menu/menu_contract.dart';
import 'package:coui_core/src/component/contracts/tree/core_tree_node.dart';

/// Builds the context-menu entries for one tree node — `W` is the platform
/// widget type (Flutter `Widget`, Web `Component`).
typedef CoreTreeNodeMenuBuilder<W> =
    List<CoreMenuItem<W>> Function(CoreTreeNode node);

/// Platform-specific menu entries share one per-node contract.
abstract interface class CoreTreeContextMenuContract<W> {
  /// Entries for a row's context menu — right-click, or long-press on touch,
  /// shows them at the pointer with the unified `ContextMenu`.
  ///
  /// The press neither selects nor toggles the row. An empty list leaves that
  /// row without a menu; absent means no row has one. A row being renamed has
  /// no menu — a right-click in its field belongs to text editing.
  CoreTreeNodeMenuBuilder<W>? get nodeContextMenu;
}
