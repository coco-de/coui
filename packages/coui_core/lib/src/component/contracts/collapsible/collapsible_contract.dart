/// Platform-independent contract for unified collapsible components.
///
/// Defines the interface that all Collapsible implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/collapsible/collapsible_style.dart';

/// Contract for a unified collapsible component.
///
/// Provides a trigger element and collapsible content that can
/// be toggled between expanded and collapsed states.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
abstract interface class CoreCollapsibleContract<W> {
  /// The trigger widget that controls expand/collapse.
  W get trigger;

  /// The content to show/hide.
  W get content;

  /// Whether the collapsible is currently expanded.
  bool get expanded;

  /// Callback when the expanded state changes.
  void Function(bool)? get onExpandedChanged;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreCollapsibleTheme (legacy flat fields)
  ///   → CoreCollapsibleTheme.style
  ///   → parent component slot override
  ///   → widget.collapsibleStyle
  /// ```
  CoreCollapsibleStyle? get collapsibleStyle;
}
