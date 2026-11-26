/// Structured error type for form fields shared between Flutter and Web.
///
/// Replaces the existing `error: String?` simple text with a richer
/// representation that carries severity and an optional field identifier
/// for mapping multi-field validation results back onto specific inputs.
///
/// Existing `error: String?` APIs continue to work — [CoreFormFieldError]
/// is an additive, opt-in enrichment.
library;

import 'package:meta/meta.dart';

/// Severity levels applied to a [CoreFormFieldError].
///
/// Declaration order reflects **decreasing severity** — callers may safely
/// sort on `CoreFormFieldSeverity.values.indexOf(x)` to rank issues.
///
/// The visual treatment (color, icon) differs per severity but **the icon
/// must always accompany the color** so the message is not conveyed by
/// color alone (WCAG 1.4.1 Use of Color).
enum CoreFormFieldSeverity {
  /// Blocks submission — colored with the theme error token.
  error,

  /// Should be reviewed but does not block submission — theme warning token.
  warning,

  /// Purely informational — theme primary/info token.
  info,
}

/// When field-level validation runs.
///
/// A form-level validation trigger setting controls the default; individual
/// fields may override. See [kDefaultFormValidationTrigger] for the
/// CoUI-wide default.
enum CoreFormValidationTrigger {
  /// Validate only on explicit submit (form `onSubmit`).
  onSubmit,

  /// Validate when the field loses focus.
  onBlur,

  /// Validate on every change/keystroke.
  onChange,
}

/// The CoUI-wide default [CoreFormValidationTrigger].
///
/// Form and field components should fall back to this when no trigger is
/// explicitly configured.
const CoreFormValidationTrigger kDefaultFormValidationTrigger = .onBlur;

/// A structured form field error.
///
/// Carries the display [message], an optional [field] identifier (useful
/// when a form aggregates errors from multiple inputs), and a [severity]
/// that drives the visual treatment.
@immutable
class CoreFormFieldError {
  /// Creates a [CoreFormFieldError].
  const CoreFormFieldError({
    required this.message,
    this.field,
    this.severity = CoreFormFieldSeverity.error,
  });

  /// Human-readable message shown to the user.
  final String message;

  /// Optional field identifier used to map multi-field validation results
  /// back to their source input (e.g. `'email'`, `'password'`).
  final String? field;

  /// Severity of this error. Defaults to [CoreFormFieldSeverity.error].
  final CoreFormFieldSeverity severity;

  /// Returns a copy with selected fields replaced.
  CoreFormFieldError copyWith({
    String? message,
    String? field,
    CoreFormFieldSeverity? severity,
  }) {
    return CoreFormFieldError(
      message: message ?? this.message,
      field: field ?? this.field,
      severity: severity ?? this.severity,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CoreFormFieldError &&
        other.message == message &&
        other.field == field &&
        other.severity == severity;
  }

  @override
  int get hashCode => Object.hash(message, field, severity);

  @override
  String toString() =>
      'CoreFormFieldError(message: $message, '
      'field: $field, severity: ${severity.name})';
}
