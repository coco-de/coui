/// Cross-platform contract for the unified `Select` component.
library;

import 'package:coui_core/coui_core.dart';

/// Contract for the unified `Select` component.
///
/// A select is a form field whose value is chosen from a list: its trigger
/// is a `TextField` (read-only, with a chevron in the suffix seat) and its
/// options are `MenuItem` rows in a `Popover` panel. That is why the
/// field-side surface here — [variant], [label], [description],
/// [errorText], [required] — reads like `TextField`'s: six of the seven
/// systems surveyed treat a select as a field, and a button contract has no
/// place for an error, a label or `role="combobox"` (Select 코드 인계
/// 통합본 2026-09-08 §0).
///
/// Every chrome / dimensional override flows through the single
/// [selectStyle] slot — see [CoreSelectStyle]. Behaviour (placement /
/// collision / closeOnScroll) stays flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [T] — the type of the option value (typically `String`).
abstract interface class CoreSelectContract<W, T> {
  // === Data ===

  /// The option list.
  List<CoreSelectItem<T>> get items;

  /// Currently selected value, or `null` when nothing is selected.
  T? get value;

  /// Placeholder shown on the trigger when [value] is `null`.
  String? get placeholder;

  // === Field surface (the trigger is a TextField) ===

  /// Ordinary or error. `errorText` non-null forces `error` the way
  /// `TextField` does; state it here to draw the error chrome without a
  /// message.
  CoreSelectVariant get variant;

  /// Density — the trigger is 32 / 40 / 48 and hands its size to every row
  /// (32 / 36 / 48).
  CoreSelectSize get size;

  /// Field label rendered above the trigger, wired to it for assistive
  /// technology (`aria-labelledby`).
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Helper text rendered below the trigger; hidden while [errorText]
  /// shows.
  String? get description;

  /// Validation message rendered below the trigger; non-null forces the
  /// `error` variant and states `aria-invalid`.
  String? get errorText;

  /// Whether the label shows the required marker.
  bool get required;

  /// Optional non-interactive trailing content on the trigger.
  ///
  /// `null` keeps the default chevron. Use passive text or an icon, not a
  /// button or focusable control: the select remains the interaction owner.
  W? get suffix;

  // === Behaviour ===

  /// Whether the trigger is interactive.
  bool get enabled;

  /// Called when the user picks an option. Receives the selected value.
  void Function(T value)? get onChanged;

  // === Popover behaviour (geometry chrome lives in selectStyle) ===

  /// Preferred placement of the dropdown relative to the trigger.
  CorePopoverPlacement get popoverPlacement;

  /// Collision policy applied when the dropdown overflows the viewport.
  Set<CorePopoverCollision> get popoverCollision;

  /// Whether ancestor scroll events close the dropdown.
  bool get closeOnScroll;

  // Every reference system divides its components by whether the user can
  // type: a select's letters move the cursor (typeahead), an autocomplete's
  // filter the list. The kit has `Autocomplete` for the latter, so there is
  // no search box inside the panel and no contract for one.

  // === Style ===

  /// Per-instance style covering the trigger field, the popover panel,
  /// the option rows and the empty-state text.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreSelectTheme.style
  ///   → parent component slot override
  ///   → widget.selectStyle
  /// ```
  ///
  /// Named [selectStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreSelectStyle? get selectStyle;
}

/// Optional capability for selects that expose a panel width policy.
///
/// Kept separate so existing implementations of [CoreSelectContract]
/// continue to compile without implementing an additional member.
abstract interface class CoreSelectPopoverWidthContract {
  /// How the option panel's width relates to the trigger.
  CorePopoverConstraint get popoverWidthConstraint;
}
