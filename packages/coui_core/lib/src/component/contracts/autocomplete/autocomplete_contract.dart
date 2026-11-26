/// Platform-independent contract for unified autocomplete components.
///
/// Defines the interface that all `Autocomplete` implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/autocomplete/autocomplete_mode.dart';
import 'package:coui_core/src/component/contracts/autocomplete/autocomplete_style.dart';

/// Contract for a unified autocomplete component.
///
/// `Autocomplete` is a self-contained text input that shows a filtered
/// suggestion dropdown. Typing filters the [suggestions] list
/// (case-insensitive `contains`); picking a suggestion applies it
/// according to [mode].
///
/// Per Epic #1302 chrome / dimensional overrides flow through the single
/// [autocompleteStyle] slot. Behavioural / semantic fields
/// (`suggestions`, `value`, `placeholder`, `enabled`, `required`,
/// `name`, `mode`, callbacks) stay flat.
///
/// Type parameter:
/// - [Cb] — change callback type derived as `void Function(String)?`.
abstract interface class CoreAutocompleteContract<Cb> {
  /// The list of available suggestion strings.
  List<String> get suggestions;

  /// Current input value.
  String? get value;

  /// Placeholder text shown when the input is empty.
  String? get placeholder;

  /// Whether the input is interactive.
  bool get enabled;

  /// Whether the input is required for form submission.
  bool get required;

  /// Form field name for submission.
  String? get name;

  /// Suggestion application strategy.
  CoreAutocompleteMode get mode;

  /// Called continuously as the input value changes.
  Cb get onChanged;

  /// Called when a suggestion is selected from the dropdown.
  Cb get onSelected;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreAutocompleteTheme.style
  ///   → parent component slot override
  ///   → widget.autocompleteStyle
  /// ```
  CoreAutocompleteStyle? get autocompleteStyle;
}
