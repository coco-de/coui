/// Platform-independent contract for unified empty-state components.
///
/// Defines the interface that all EmptyState implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/empty_state/empty_state_style.dart';
import 'package:coui_core/src/component/contracts/empty_state/empty_state_tone.dart';
import 'package:coui_core/src/component/contracts/empty_state/empty_state_variant.dart';

/// Contract for a unified empty-state component.
///
/// Displays a placeholder view when there is no content, with optional
/// icon, title, description, and action.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreEmptyStateContract<W> {
  /// The main title of the empty state.
  W get title;

  /// Visual density variant. Maps 1:1 to the legacy `compact: bool`
  /// — [CoreEmptyStateVariant.compact] equals `compact: true`.
  CoreEmptyStateVariant get variant;

  /// Why the region is empty — nothing yet, or something failed.
  ///
  /// Orthogonal to [variant], which is density. A failure announces
  /// itself to a screen reader AND tints its icon `error` red
  /// (`CoreEmptyStateStyle.defaultsByTone`) — an absence is ordinary
  /// content and stays quiet on both axes
  /// (`widget/failure-surfaces.md`: a field that only changed the
  /// announcement would be half an axis).
  CoreEmptyStateTone get tone;

  /// Optional icon displayed above the title.
  W? get icon;

  /// Whether [icon] renders when non-null. A caller that always builds
  /// an icon widget can toggle it off without restructuring — the same
  /// `showX` + nullable-slot pairing `Chip`'s leading/trailing uses.
  /// Effective visibility is `showIcon && icon != null`.
  bool get showIcon;

  /// Optional description providing more context.
  W? get description;

  /// Whether [description] renders when non-null. Effective visibility
  /// is `showDescription && description != null`.
  bool get showDescription;

  /// Optional action widget (typically a button).
  W? get action;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreEmptyStateStyle.defaults / defaultsByVariant
  ///   → CoreEmptyStateTheme.style
  ///   → CoreEmptyStateTheme.variantStyles[variant]
  ///   → widget.emptyStateStyle
  /// ```
  CoreEmptyStateStyle? get emptyStateStyle;
}
