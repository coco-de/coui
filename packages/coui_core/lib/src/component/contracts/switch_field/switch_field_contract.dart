/// Platform-independent contract for switch field components.
///
/// A switch field combines a toggle with a label and optional
/// description text. Chrome overrides flow exclusively through the
/// `switchFieldStyle` slot — there are no flat widget chrome props.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/switch_field/switch_field_style.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a switch field component.
///
/// The value-change callback is the platform-neutral
/// [CoreValueChanged] — Flutter's `ValueChanged<bool>` is structurally
/// identical, so no platform type parameter is needed.
abstract interface class CoreSwitchFieldContract {
  /// Label text for the switch field.
  String get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Current toggle state.
  bool get value;

  /// Called when the toggle value changes.
  CoreValueChanged<bool>? get onChanged;

  /// Optional description text below the label.
  String? get description;

  /// Whether the switch field is enabled.
  ///
  /// `null` (default) follows [onChanged]: a field with a callback takes
  /// input, one without does not — the rule a toggle uses, so a field nobody
  /// listens to is not drawn as one that does.
  bool? get enabled;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreSwitchFieldTheme.style
  ///   → parent component slot override
  ///   → widget.switchFieldStyle
  /// ```
  CoreSwitchFieldStyle? get switchFieldStyle;
}
