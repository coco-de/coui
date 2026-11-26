/// Platform-independent contract for checkbox components.
///
/// Defines the interface that all checkbox implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/checkbox/checkbox_style.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a checkbox component.
///
/// Every chrome / dimensional override flows through the single
/// [checkboxStyle] field — see [CoreCheckboxStyle] for the merge chain.
/// The semantic `size` stays flat on the contract because it describes the
/// checkbox's **identity**. Behaviour fields (`tristate`, callbacks, focus,
/// controllers) likewise stay flat.
///
/// The value is Flutter's tristate `bool?` — `true` / `false` / `null` for
/// indeterminate — and the change callback is derived directly as
/// `void Function(bool?)?`. Hover / focus / pressed are DETECTION, not
/// value: each platform's native engine (`Clickable` on Flutter, CSS
/// pseudo-classes on Web) reports them, and the chrome for each state comes
/// from [CoreCheckboxStyle]'s per-state fields.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [Focus] — focus node type
///   (Flutter `FocusNode`, Web `CoreFocusNode`).
/// - [States] — states controller (Flutter `WidgetStatesController`).
/// - [Ctrl] — checkbox controller type.
abstract interface class CoreCheckboxContract<W, Focus, States, Ctrl> {
  // === Value ===

  /// Whether the checkbox is checked — `null` is the indeterminate
  /// (partially checked) state.
  bool? get checked;

  /// Called with the next value when the checkbox is toggled.
  CoreValueChanged<bool?>? get onChanged;

  /// Whether the checkbox is enabled.
  bool? get enabled;

  /// Whether the checkbox cycles through the indeterminate state on tap
  /// (`false → null → true`) rather than toggling between two.
  bool get tristate;

  // === Content ===

  /// Widget displayed before the checkbox square.
  W? get prefix;

  /// Widget displayed after the checkbox square.
  W? get suffix;

  /// Optional text label displayed next to the checkbox.
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
  /// `onSurfaceVariant` foreground.
  ///
  /// Distinct from [suffix], which *replaces* the label rather than
  /// joining it: label and description stack in one column, and either
  /// can be present without the other.
  String? get description;

  /// Widget pinned after the content column — the end of the row.
  ///
  /// Distinct from [suffix] for the same reason [description] is: this
  /// one sits beside the label rather than instead of it, which is what
  /// an affordance like a chevron on a disclosure row needs.
  W? get trailing;

  // === Semantic identity (widget params, not chrome) ===

  /// Size token (xs / sm / md / lg / xl / xl2).
  CoreComponentSize get size;

  // === Style (chrome / dimensional / nested slot) ===

  /// Per-instance checkbox style covering chrome + dimensional
  /// overrides plus nested checkmark icon and label styles.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreCheckboxTheme.style
  ///   → parent component slot override
  ///   → widget.checkboxStyle
  /// ```
  ///
  /// Named [checkboxStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreCheckboxStyle? get checkboxStyle;

  // === Form ===

  /// Form field name for submission.
  String? get name;

  // === Focus & State ===

  /// Focus node for keyboard focus management.
  Focus? get focusNode;

  /// External controller for component interaction states.
  States? get statesController;

  /// Checkbox controller for programmatic state management.
  Ctrl? get controller;
}
