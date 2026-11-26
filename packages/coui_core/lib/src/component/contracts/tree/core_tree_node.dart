/// A single node within a tree component.
library;

/// A single node within a tree.
///
/// Represents one item in a hierarchical tree structure
/// with optional children for nesting.
///
/// [id] and [selected] are optional extension fields that let a single
/// `CoreTreeContract` serve both plain trees and richer tree-view
/// style displays (stable addressing by id, visual selection state)
/// without introducing a second contract.
class CoreTreeNode {
  /// Creates a [CoreTreeNode] with the given [label]
  /// and optional [children].
  const CoreTreeNode({
    required this.label,
    this.children = const [],
    this.expanded = false,
    this.id,
    this.selected = false,
    this.canHaveChildren = false,
  });

  /// The text label displayed for this node.
  final String label;

  /// The child nodes nested under this node.
  final List<CoreTreeNode> children;

  /// Whether this node is expanded to show its children.
  final bool expanded;

  /// Optional stable identifier for the node. Useful when callbacks
  /// need to address a specific node by id rather than by reference.
  final String? id;

  /// Whether this node is visually highlighted as selected.
  final bool selected;

  /// Whether this node is a branch whose children have not been loaded yet.
  /// An empty branch remains expandable after a successful empty load.
  final bool canHaveChildren;
}
