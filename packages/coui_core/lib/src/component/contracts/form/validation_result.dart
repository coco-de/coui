/// Platform-independent form validation results.
library;

import 'package:coui_core/src/component/contracts/form/core_form_key.dart';
import 'package:coui_core/src/component/contracts/form/form_validation_mode.dart';

/// Outcome of validating a single form field.
///
/// Subtypes describe the kinds of result a `Validator` can produce:
/// [InvalidResult] (an error message), [ReplaceResult] (a normalised value
/// to write back), and [WaitingResult] (an asynchronous validation still in
/// flight). A result is created detached and later `attach`ed to the
/// [CoreFormKey] of the field it belongs to.
abstract class ValidationResult {
  /// Creates a [ValidationResult] for the given validation [state].
  const ValidationResult({required this.state});

  /// The validation trigger mode that produced this result.
  final FormValidationMode state;

  /// The key of the field this result belongs to (after [attach]).
  CoreFormKey<dynamic> get key;

  /// Returns a copy of this result bound to [key].
  ValidationResult attach(CoreFormKey<dynamic> key);
}

/// A result that replaces the field's value with a normalised [value]
/// (e.g. trimming whitespace, reformatting a number).
class ReplaceResult<T> extends ValidationResult {
  /// Creates a detached [ReplaceResult].
  const ReplaceResult(this.value, {required super.state}) : _key = null;

  /// Creates a [ReplaceResult] already bound to [key].
  const ReplaceResult.attached(
    this.value, {
    required CoreFormKey<dynamic> key,
    required super.state,
  }) : _key = key;

  /// The normalised value to write back to the field.
  final T value;

  final CoreFormKey<dynamic>? _key;

  @override
  CoreFormKey<dynamic> get key {
    assert(_key != null, 'The result has not been attached to a key');

    return _key!;
  }

  @override
  ReplaceResult<T> attach(CoreFormKey<dynamic> key) {
    return ReplaceResult.attached(value, key: key, state: state);
  }
}

/// A validation failure carrying a human-readable [message].
class InvalidResult extends ValidationResult {
  /// Creates a detached [InvalidResult].
  const InvalidResult(this.message, {required super.state}) : _key = null;

  /// Creates an [InvalidResult] already bound to [key].
  const InvalidResult.attached(
    this.message, {
    required CoreFormKey<dynamic> key,
    required super.state,
  }) : _key = key;

  /// The error message describing why the value is invalid.
  final String message;

  final CoreFormKey<dynamic>? _key;

  @override
  CoreFormKey<dynamic> get key {
    assert(_key != null, 'The result has not been attached to a key');

    return _key!;
  }

  @override
  InvalidResult attach(CoreFormKey<dynamic> key) {
    return InvalidResult.attached(message, key: key, state: state);
  }
}

/// A placeholder result indicating an asynchronous validation is still in
/// progress for the field.
class WaitingResult extends ValidationResult {
  /// Creates a [WaitingResult] already bound to [key].
  const WaitingResult.attached({
    required CoreFormKey<dynamic> key,
    required super.state,
  }) : _key = key;

  final CoreFormKey<dynamic>? _key;

  @override
  CoreFormKey<dynamic> get key {
    assert(_key != null, 'The result has not been attached to a key');

    return _key!;
  }

  @override
  WaitingResult attach(CoreFormKey<dynamic> key) {
    return WaitingResult.attached(key: key, state: state);
  }
}
