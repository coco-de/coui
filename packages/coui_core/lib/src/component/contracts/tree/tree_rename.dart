/// Shared, data-only rules for renaming a Tree node in place.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/contracts/tree/core_tree_node.dart';
import 'package:coui_core/src/component/contracts/tree/tree_style.dart';
import 'package:coui_core/src/size/control_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/text_style_token.dart';

/// A consumer-owned rename request. The Tree never changes [CoreTreeNode]s —
/// it reports the edited [label] and the consumer passes the renamed node
/// back, exactly like a drop.
///
/// [label] has already passed [CoreTreeRenameRules.committedLabel]: it is
/// trimmed, non-empty and different from the node's current label.
typedef CoreTreeRenameCallback = void Function(CoreTreeNode node, String label);

/// Optional consumer policy — `false` keeps a row's label read-only.
typedef CoreTreeRenamePredicate = bool Function(CoreTreeNode node);

/// The rename decisions both platforms must make identically.
///
/// They live here, not in each widget, because they are not rendering: a
/// Flutter tree that reports a whitespace-only name while the Web twin drops
/// it would be two products, not one component on two platforms.
abstract final class CoreTreeRenameRules {
  /// The label to report for [input], or `null` when the edit reports
  /// nothing and simply closes the field.
  ///
  /// Surrounding whitespace is trimmed — a trailing space typed by accident
  /// is never what a name was meant to end with. An empty result or the
  /// node's current label is not a rename, so the consumer is not asked to
  /// perform one.
  static String? committedLabel(CoreTreeNode node, String input) {
    final label = input.trim();

    return label.isEmpty || label == node.label ? null : label;
  }

  /// Where the initial selection ends when the field opens.
  ///
  /// A leaf keeps the part after its last dot unselected
  /// (`main.dart` → `main`), so typing replaces the name and not the type —
  /// the file-explorer idiom. A branch, a name without a dot and a dot-file
  /// such as `.gitignore` (whose only dot starts the name) select the whole
  /// label.
  static int selectionEnd(String label, {required bool isBranch}) {
    if (isBranch) return label.length;
    final dot = label.lastIndexOf('.');

    return dot > 0 ? dot : label.length;
  }

  /// The colour of the text typed into the rename field — `onSurface`.
  ///
  /// Pinned, not inherited: the row's unselected label is `onSurfaceVariant`
  /// (a quieter colour for a name that is only being read), and a name that
  /// is being edited is not only being read. The field takes the label's
  /// role and size so the name does not change shape when editing starts, but
  /// its colour is stated here so a change to the label colour cannot dim
  /// the text being typed.
  static const CoreColor fieldTextColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// The nested `TextField` style both platforms compose for the field.
  ///
  /// The box is the `xs` control height (24) with horizontal-only padding,
  /// and the text takes the row's own [labelStyle] — role and size, so the
  /// name does not change shape — in [fieldTextColor] rather than the label's
  /// colour. The row's label line box is 21, so the field is taller than the
  /// line it replaces and the row grows by the difference while its label is
  /// edited. A virtualised row is shorter still when its extent says so — the
  /// field fits the row, never the other way round.
  ///
  /// The corner is the row's own (`CoreTreeStyle.defaultBorderRadius`, 6),
  /// stated here because the field is composed without a size: the `md`
  /// row of the field's ladder would draw 10 inside the row's 6 — a field
  /// rounder than the row it sits in (designer decision — inner ≤ outer).
  static CoreTextFieldStyle fieldStyle(CoreTextStyle labelStyle) =>
      CoreTextFieldStyle(
        borderRadius: CoreTreeStyle.defaultBorderRadius,
        height: CoreControlSize.heightXs,
        padding: const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space4),
        baseTextStyle: labelStyle.copyWith(color: fieldTextColor),
      );
}
