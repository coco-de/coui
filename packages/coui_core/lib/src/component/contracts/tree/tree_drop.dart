/// Shared, data-only validation for a Tree node drop.
library;

import 'package:coui_core/src/component/contracts/tree/core_tree_node.dart';
import 'package:meta/meta.dart';

/// A consumer-owned mutation request. The Tree never changes [CoreTreeNode]s.
typedef CoreTreeDropCallback =
    void Function(CoreTreeNode source, CoreTreeNode destination);

/// Optional consumer policy in addition to the Tree's structural checks.
typedef CoreTreeDropPredicate =
    bool Function(CoreTreeNode source, CoreTreeNode destination);

/// Position relative to a visible row. [inside] inserts as its first child.
enum CoreTreeDropPosition {
  /// Immediately before the anchor in its parent.
  before,

  /// As the first child of the anchor folder.
  inside,

  /// Immediately after the anchor in its parent.
  after,
}

/// A stable placement intent. Only the consumer changes the underlying tree.
@immutable
class CoreTreeDropTarget {
  /// Creates a placement addressed by stable [CoreTreeNode.id] values.
  const CoreTreeDropTarget({
    required this.anchor,
    required this.directory,
    required this.position,
    required this.depth,
  });

  /// The visible row used as a drop reference.
  final CoreTreeNode anchor;

  /// Parent for before/after, or the folder itself for inside.
  final CoreTreeNode directory;

  /// Where to insert relative to [anchor].
  final CoreTreeDropPosition position;

  /// The depth of the previewed child, including the synthetic root if any.
  final int depth;

  @override
  bool operator ==(Object other) =>
      other is CoreTreeDropTarget &&
      other.anchor.id == anchor.id &&
      other.directory.id == directory.id &&
      other.position == position &&
      other.depth == depth;

  @override
  int get hashCode => Object.hash(anchor.id, directory.id, position, depth);
}

/// A node move/reorder request with an exact insertion position.
typedef CoreTreePlaceCallback =
    void Function(CoreTreeNode source, CoreTreeDropTarget target);

/// Application policy in addition to structural cycle checks.
typedef CoreTreePlacePredicate =
    bool Function(CoreTreeNode source, CoreTreeDropTarget target);

/// Optional gate for non-movable nodes (for example a synthetic root).
typedef CoreTreeDragPredicate = bool Function(CoreTreeNode node);

/// Files dropped at a specific insertion position, rather than just a folder.
typedef CoreTreeFilesPlaceCallback<Files> =
    void Function(Files files, CoreTreeDropTarget target);

/// Reports files supplied by the host platform and their intended directory.
/// The consumer validates and writes the files; the Tree does not mutate data.
typedef CoreTreeFilesDropCallback<Files> =
    void Function(Files files, CoreTreeNode directory);

/// Platform-specific file types share the same directory-target contract.
abstract interface class CoreTreeFilesDropContract<Files> {
  /// Receives host files together with the visible directory they target.
  CoreTreeFilesDropCallback<Files>? get onFilesDroppedOnNode;

  /// Receives host files with a before/after/inside placement intent.
  CoreTreeFilesPlaceCallback<Files>? get onFilesPlaced;
}

/// Prevents drops onto a leaf, onto self, or into a loaded descendant.
///
/// Unloaded descendants cannot be selected as targets until their parent is
/// expanded. `childrenOf` includes cached, lazily loaded children. Filesystem
/// permissions, locks and name collisions belong to the consumer.
abstract final class CoreTreeDropRules {
  /// Portion of a row reserved at each edge for sibling insertion.
  static const double edgeFraction = 0.25;

  /// Chooses a placement from the pointer within a visible row.
  static CoreTreeDropPosition positionAt({
    required double pointerY,
    required double rowTop,
    required double rowHeight,
    required bool isBranch,
    required bool hasParent,
  }) {
    if (!hasParent) return .inside;
    final fraction = rowHeight <= 0
        ? 0.5
        : ((pointerY - rowTop) / rowHeight).clamp(0.0, 1.0);
    if (fraction < edgeFraction) return .before;
    if (fraction > 1 - edgeFraction) return .after;
    if (isBranch) return .inside;

    return fraction < 0.5 ? .before : .after;
  }

  /// Validates a placement without interpreting ids as filesystem paths.
  static bool acceptsPlacement(
    CoreTreeNode source,
    CoreTreeDropTarget target, {
    required List<CoreTreeNode> Function(CoreTreeNode node) childrenOf,
  }) {
    if (source.id == null ||
        target.anchor.id == null ||
        source.id == target.anchor.id ||
        (target.position == .inside &&
            target.anchor.id != target.directory.id)) {
      return false;
    }
    return accepts(source, target.directory, childrenOf: childrenOf);
  }

  /// Whether [source] may be placed inside [destination]. Stable ids are
  /// required for draggable rows so reordering siblings cannot change intent.
  static bool accepts(
    CoreTreeNode source,
    CoreTreeNode destination, {
    required List<CoreTreeNode> Function(CoreTreeNode node) childrenOf,
  }) {
    final sourceId = source.id;
    final targetId = destination.id;
    if (sourceId == null || targetId == null || sourceId == targetId) {
      return false;
    }
    if (!destination.canHaveChildren && destination.children.isEmpty) {
      return false;
    }

    final visited = <String>{};
    bool containsTarget(CoreTreeNode node) {
      if (!visited.add(node.id ?? 'unidentified:${identityHashCode(node)}')) {
        return false;
      }
      for (final child in childrenOf(node)) {
        if (child.id == targetId || containsTarget(child)) return true;
      }
      return false;
    }

    return !containsTarget(source);
  }
}
