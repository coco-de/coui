/// Platform-independent contract for unified accordion components.
///
/// Defines the interface that all Accordion implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/accordion/accordion_style.dart';

/// Contract for a unified accordion component.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [accordionStyle] field — see [CoreAccordionStyle] for
/// the merge chain. Behaviour fields stay flat on the contract.
///
/// Renders a vertically stacked list of collapsible sections,
/// each revealing its content when expanded.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreAccordionContract<W> {
  /// The list of accordion items to display.
  List<W> get items;

  /// Whether multiple sections can be expanded simultaneously.
  bool get allowMultiple;

  /// Per-instance accordion chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreAccordionTheme.style
  ///   → parent component slot override
  ///   → widget.accordionStyle
  /// ```
  CoreAccordionStyle? get accordionStyle;
}

/// Contract for a single accordion item.
///
/// Type parameters:
/// - [W] - platform widget type.
abstract interface class CoreAccordionItemContract<W> {
  /// Simple title string for the accordion header.
  String? get title;

  /// Custom trigger widget for the accordion header.
  W? get trigger;

  /// The collapsible content widget.
  W get content;

  /// Whether this item starts expanded.
  bool get expanded;
}
