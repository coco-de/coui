/// Per-node content builders for the unified tree.
library;

import 'package:coui_core/src/component/contracts/tree/core_tree_node.dart';

// Each builder takes the platform's build context first. `coui_core` cannot
// name either framework's context type, so the contract states that
// parameter as `Never`: a platform builder that takes its own `BuildContext`
// is a subtype, so each platform keeps its own typed signature (a caller's
// closure reads `context` as a `BuildContext`, not an `Object` to cast) while
// the contract still fixes the builder's name, the node and the rest of the
// arguments for both. Only the platform calls the builder.

/// Content one row supplies beside its label, given whether the node's
/// branch is open — the leading glyph, a trailing status mark.
///
/// `W` is the platform widget type (Flutter `Widget`, Web `Component`).
typedef CoreTreeNodeBuilder<W> =
    W Function(Never context, CoreTreeNode node, {required bool expanded});

/// The row a branch shows while its children load.
typedef CoreTreeLoadingBuilder<W> =
    W Function(Never context, CoreTreeNode node);

/// The row a branch shows when loading its children failed, with the error.
typedef CoreTreeLoadErrorBuilder<W> =
    W Function(Never context, CoreTreeNode node, Object error);
