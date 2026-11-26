/// Platform-independent contract for the no-JS disclosure component.
library;

import 'package:coui_core/src/component/contracts/disclosure/disclosure_style.dart';

/// Contract for a disclosure — a titled section the reader opens and
/// closes, with no client-side state of its own.
///
/// ### Why this exists beside `Collapsible`
///
/// `Collapsible` owns an expansion animation and drives it from widget
/// state. That state is exactly what a statically rendered page does
/// not have before hydration: the panel ships closed, and with scripting
/// off it never opens. `Disclosure` gives up the animation to get the
/// open/close behaviour from the platform instead — Web renders
/// `<details>/<summary>`, where the browser owns the toggle, the
/// keyboard, and the screen-reader semantics with zero script.
///
/// Reach for `Collapsible` when the animation matters, for `Accordion`
/// when sections must close each other, and for `Disclosure` when the
/// section has to work before (or without) hydration.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreDisclosureContract<W> {
  /// Plain-text header. Either this or [trigger] must be supplied;
  /// [trigger] wins when both are.
  String? get title;

  /// Custom header slot, for when the header is more than text.
  W? get trigger;

  /// The body revealed while open.
  W get content;

  /// Whether the section starts open.
  ///
  /// This is an *initial* state, not a controlled one — the platform
  /// flips it from there (Web: the browser mutates the `open`
  /// attribute; Flutter: the widget's own state). That mirrors
  /// `<details open>` exactly, and it is what lets the component carry
  /// no state a static render would have to hydrate. Callers that need
  /// the open state to be theirs should use `Collapsible`.
  bool get open;

  /// Fires after the platform toggles the section, with the new state.
  ///
  /// Observational: returning without acting does not re-close the
  /// section, because the caller never owned the state.
  void Function(bool)? get onToggle;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreDisclosureStyle.defaultX)
  ///   → CoreDisclosureTheme.style
  ///   → parent component slot override
  ///   → widget.disclosureStyle
  /// ```
  CoreDisclosureStyle? get disclosureStyle;
}

/// Contract for a stack of independent disclosures.
///
/// ### Why there is no `DisclosureItem`
///
/// An `AccordionItem` exists because the accordion owns which section is
/// open and the item cannot answer that alone. A `Disclosure` owns
/// nothing, so the group has nothing to take from it — the items here
/// are `Disclosure`s themselves. That keeps every `Disclosure` feature
/// available inside a group without a second class restating it.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreDisclosureGroupContract<W> {
  /// The disclosures to stack, in order.
  List<W> get items;

  /// Per-instance style. The group reads exactly one field from it —
  /// [CoreDisclosureStyle.itemSpacing] — because that is the only value
  /// describing the stack rather than a section.
  ///
  /// It does **not** reach into the children: [items] is a list of
  /// platform widgets, so the group cannot know that a given entry is a
  /// `Disclosure` at all, and restyling something it has not identified
  /// would be guessing. Styling every section at once is what
  /// `CoreDisclosureTheme.style` is for — that reaches each child
  /// through its own resolver, which is also where a per-child override
  /// still gets to win.
  CoreDisclosureStyle? get disclosureStyle;
}
