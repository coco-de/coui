/// Platform-independent contract for form field wrapper components.
library;

import 'package:coui_core/src/component/contracts/form/form_field_style.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a form field wrapper component.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreFormFieldContract<W> {
  /// Label text for the field.
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Custom label widget (overrides label text).
  W? get labelWidget;

  /// An affordance shown at the far end of the label row — a "Forgot
  /// password?" link beside a password field, a "What's this?" opener
  /// beside an unfamiliar one.
  ///
  /// A widget slot rather than text-plus-callback because what belongs
  /// here is already a component: the kit's own `Link` when it goes
  /// somewhere, `Button(variant: .plain)` when it opens something in place,
  /// and the caller owns both its copy and what it does. Absent, the label
  /// row is exactly what it was.
  W? get labelAction;

  /// The main content/input widget.
  W? get child;

  /// Error message to display below the field.
  String? get error;

  /// Helper/description text below the field.
  String? get description;

  /// A character/'item' tally shown at the far end of the footer row —
  /// `0 / 20` beside a length-capped input.
  ///
  /// A `String?` the caller composes, not a pair of numbers this widget
  /// formats. Two reasons, and the second is the one that decides it:
  ///
  /// 1. The separator and the order are a locale's business, not this
  ///    widget's — `0 / 20` is one rendering of that idea among several.
  /// 2. This field wraps an ARBITRARY [child]. It cannot read a length
  ///    it does not own; a version that formatted numbers would still
  ///    need the caller to supply them, having gained nothing but a
  ///    fixed separator.
  String? get counterText;

  /// Whether the field is required (shows required indicator).
  bool get required;

  /// Whether the field is enabled.
  bool get enabled;

  /// Size tier — forwarded straight to the composed `FormLabel`, whose
  /// own `CoreFormLabelStyle.defaultsBySize` ladder already states the
  /// label typography rung (`md`/`lg` are the canvas-confirmed pivots;
  /// the rest extend to the nearest one). `FormField` states no
  /// `defaultsBySize` of its own — the ladder already exists once, on
  /// `FormLabel`, and repeating it here would be a second copy of the
  /// same decision (`core/style-contract.md`: a parent does not reach
  /// into a composed child's own defaults).
  CoreComponentSize get size;

  /// Per-instance composite chrome / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreFormFieldTheme.style
  ///   → parent component slot override
  ///   → widget.formFieldStyle
  /// ```
  CoreFormFieldStyle? get formFieldStyle;
}
