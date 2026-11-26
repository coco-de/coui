/// Platform-independent contract for radio group components.
///
/// Defines the interface that all radio group implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/radio_group/radio_group_orientation.dart';
import 'package:coui_core/src/component/contracts/radio_group/radio_group_style.dart';
import 'package:coui_core/src/component/contracts/radio_group/radio_group_variant.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a single radio item, inside a group or on its own.
///
/// Inside a radio group the item reads the group's selection, callback,
/// variant and size. On its own — a card-style choice built from separate
/// radios — it carries them itself through [groupValue], [onChanged],
/// [groupVariant] and [groupSize].
///
/// Type parameters:
/// - [Val] — value type (Flutter `T`, Web `String`).
/// - [W] — platform widget type
///   (Flutter `Widget`, Web `Component`).
abstract interface class CoreRadioItemContract<Val, W> {
  /// The value represented by this radio item.
  Val get value;

  /// The selected value of the set this radio belongs to — the radio is
  /// selected when it equals [value].
  ///
  /// Inside a group it falls back to the group's selection when `null`.
  Val? get groupValue;

  /// Called with [value] when the user picks this radio.
  ///
  /// Inside a group it falls back to the group's callback when `null`. A
  /// radio with no callback from either source is not interactive.
  void Function(Val?)? get onChanged;

  /// Variant of a radio on its own. Inside a group the group's variant
  /// decides and this is not read.
  CoreRadioGroupVariant get groupVariant;

  /// Size of a radio on its own. Inside a group the group's size decides
  /// and this is not read.
  CoreComponentSize get groupSize;

  /// Optional text label displayed next to the radio indicator.
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Optional supporting line rendered under [label], in the quieter
  /// description foreground.
  ///
  /// Distinct from [suffix], which *replaces* the label rather than
  /// joining it: label and description stack in one column, and either
  /// can be present without the other. The `card` variant's tiles are
  /// where it is usually read, but a plain row carries it too.
  String? get description;

  /// Widget displayed before the radio indicator.
  W? get prefix;

  /// Widget displayed after the radio indicator.
  W? get suffix;

  /// Whether this individual radio item is enabled.
  bool get enabled;
}

/// Contract for a radio group component.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [radioGroupStyle] field — see [CoreRadioGroupStyle] for
/// the merge chain. Semantic enums (`variant`, `size`, `orientation`)
/// stay flat on the contract because they describe the group's
/// **identity**.
///
/// Type parameters:
/// - [Val] — value type (Flutter `T`, Web `String`).
/// - [W] — platform widget type
///   (Flutter `Widget`, Web `Component`).
/// - [Focus] — focus node type
///   (Flutter `FocusNode`, Web `CoreFocusNode`).
/// - [States] — states controller (Flutter `WidgetStatesController`).
/// - [Ctrl] — controller type.
abstract interface class CoreRadioGroupContract<Val, W, Focus, States, Ctrl> {
  // === State ===

  /// The currently selected value.
  Val? get value;

  /// Seed selection for the uncontrolled path.
  ///
  /// When non-null the group owns its own selection: it starts here and
  /// moves on its own as the user picks, while [onChanged] still reports
  /// every change. [value] is not read in that mode — a caller that
  /// wants to drive selection from outside leaves this `null` and passes
  /// [value] instead.
  ///
  /// Both together would give the group two sources for one selection,
  /// which is why the two modes are exclusive rather than merged.
  Val? get initialValue;

  /// Called when the selected value changes.
  void Function(Val?)? get onChanged;

  /// Whether the entire radio group is enabled.
  bool? get enabled;

  // === Content ===

  /// String-based options for convenience API.
  ///
  /// When provided, auto-generates radio items.
  List<({Val value, String label})>? get options;

  /// Custom child widget for advanced layout.
  W? get child;

  // === Semantic identity (widget params, not chrome) ===

  /// Visual variant. Identifies the radio group semantically.
  CoreRadioGroupVariant get variant;

  /// Size token (xs / sm / md / lg / xl).
  CoreComponentSize get size;

  /// Layout orientation (horizontal or vertical).
  CoreRadioGroupOrientation get orientation;

  // === Style (chrome / dimensional / nested slot) ===

  /// Per-instance style covering chrome + dimensional overrides plus
  /// nested indicator-dot icon and label styles.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default for variant
  ///   → CoreRadioGroupTheme.style
  ///   → CoreRadioGroupTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.radioGroupStyle
  /// ```
  ///
  /// Named [radioGroupStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreRadioGroupStyle? get radioGroupStyle;

  // === Form ===

  /// Form field name for submission.
  String? get name;

  // === Focus & State ===

  /// Focus node for keyboard focus management.
  Focus? get focusNode;

  /// External controller for component interaction states.
  States? get statesController;

  /// Radio group controller for programmatic state management.
  Ctrl? get controller;
}
