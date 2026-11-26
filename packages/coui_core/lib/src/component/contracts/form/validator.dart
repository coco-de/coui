/// Platform-independent form field validators.
library;

import 'dart:async';

import 'package:coui_core/src/component/contracts/form/core_form_key.dart';
import 'package:coui_core/src/component/contracts/form/core_validation_context.dart';
import 'package:coui_core/src/component/contracts/form/form_validation_mode.dart';
import 'package:coui_core/src/component/contracts/form/validation_result.dart';
import 'package:meta/meta.dart';

/// Abstract base class for implementing form field validation logic.
///
/// Validators check the validity of form field values and return a
/// [ValidationResult]. They support both synchronous and asynchronous
/// validation through the [FutureOr] return type and can be combined with
/// logical operators:
/// - `&` or `+`: combine (all must pass)
/// - `|`: OR logic (at least one must pass)
///
/// Negate a validator with `NotValidator(validator)`.
///
/// Lives in `coui_core` so Flutter and Web share one validator vocabulary.
/// Platform dependencies (localized messages, host liveness) flow through
/// the [CoreValidationContext] argument rather than a platform widget
/// context.
abstract class Validator<T> {
  /// Creates a [Validator].
  const Validator();

  /// Validates [value] for the given [lifecycle], returning `null` when
  /// valid or a [ValidationResult] describing the error. [context] supplies
  /// localized default messages and a liveness flag.
  FutureOr<ValidationResult?> validate(
    CoreValidationContext context,
    T? value,
    FormValidationMode lifecycle,
  );

  /// Combines this validator with [other] using AND logic (both must pass).
  Validator<T> combine(Validator<T> other) {
    return CompositeValidator([this, other]);
  }

  /// AND logic (alias for [combine]).
  Validator<T> operator &(Validator<T> other) {
    return combine(other);
  }

  /// OR logic (at least one of the two must pass).
  Validator<T> operator |(Validator<T> other) {
    return OrValidator([this, other]);
  }

  /// AND logic (alias for [combine]).
  Validator<T> operator +(Validator<T> other) {
    return combine(other);
  }

  /// Whether this validator should re-run when the field identified by
  /// [source] changes (cross-field validation). Defaults to `false`.
  bool shouldRevalidate(CoreFormKey<dynamic> source) => false;
}

/// Inverts the result of another [validator] — passes when it fails and
/// fails (with [message] or the default `invalidValue`) when it passes.
@immutable
class NotValidator<T> extends Validator<T> {
  /// Creates a [NotValidator].
  const NotValidator(this.validator, {this.message});

  /// The validator whose result is inverted.
  final Validator<T> validator;

  /// Overrides the default `invalidValue` message. Null uses the localized
  /// default from [CoreValidationContext.messages].
  final String? message;

  @override
  FutureOr<ValidationResult?> validate(
    CoreValidationContext context,
    T? value,
    FormValidationMode state,
  ) {
    final result = validator.validate(context, value, state);
    if (result is Future<ValidationResult?>) {
      // Capture before the await — `context` may be inactive afterwards.
      final messages = context.messages;
      return result.then((value) {
        return value == null
            ? InvalidResult(message ?? messages.invalidValue, state: state)
            : null;
      });
    } else if (result == null) {
      return InvalidResult(
        message ?? context.messages.invalidValue,
        state: state,
      );
    }

    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is NotValidator &&
        other.validator == validator &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(validator, message);
}

/// Passes when at least one of [validators] passes (OR logic).
@immutable
class OrValidator<T> extends Validator<T> {
  /// Creates an [OrValidator].
  const OrValidator(this.validators);

  /// The validators combined with OR logic.
  final List<Validator<T>> validators;

  @override
  FutureOr<ValidationResult?> validate(
    CoreValidationContext context,
    T? value,
    FormValidationMode state,
  ) {
    return _chainedValidation(context, value, state, 0);
  }

  @override
  Validator<T> operator |(Validator<T> other) {
    return OrValidator([...validators, other]);
  }

  @override
  bool shouldRevalidate(CoreFormKey<dynamic> source) {
    for (final validator in validators) {
      if (validator.shouldRevalidate(source)) {
        return true;
      }
    }

    return false;
  }

  @override
  bool operator ==(Object other) {
    return other is OrValidator && _listEquals(other.validators, validators);
  }

  FutureOr<ValidationResult?> _chainedValidation(
    CoreValidationContext context,
    T? value,
    FormValidationMode state,
    int index,
  ) {
    if (index >= validators.length) {
      return null;
    }
    final validator = validators[index];
    final result = validator.validate(context, value, state);
    if (result is Future<ValidationResult?>) {
      return result.then((nextValue) {
        if (nextValue == null) {
          // One validator passed — short-circuit.
          return null;
        }

        return !context.isActive
            ? null
            : _chainedValidation(context, value, state, index + 1);
      });
    } else if (result == null) {
      // One validator passed — short-circuit.
      return null;
    }

    return _chainedValidation(context, value, state, index + 1);
  }

  @override
  int get hashCode => Object.hashAll(validators);
}

/// Passes only when all [validators] pass (AND logic).
@immutable
class CompositeValidator<T> extends Validator<T> {
  /// Creates a [CompositeValidator].
  const CompositeValidator(this.validators);

  /// The validators combined with AND logic.
  final List<Validator<T>> validators;

  @override
  FutureOr<ValidationResult?> validate(
    CoreValidationContext context,
    T? value,
    FormValidationMode state,
  ) {
    return _chainValidation(context, value, state, 0);
  }

  @override
  Validator<T> combine(Validator<T> other) {
    return CompositeValidator([...validators, other]);
  }

  @override
  bool shouldRevalidate(CoreFormKey<dynamic> source) {
    for (final validator in validators) {
      if (validator.shouldRevalidate(source)) {
        return true;
      }
    }

    return false;
  }

  @override
  bool operator ==(Object other) {
    return other is CompositeValidator &&
        _listEquals(other.validators, validators);
  }

  FutureOr<ValidationResult?> _chainValidation(
    CoreValidationContext context,
    T? value,
    FormValidationMode state,
    int index,
  ) {
    if (index >= validators.length) {
      return null;
    }
    final validator = validators[index];
    final result = validator.validate(context, value, state);
    if (result is Future<ValidationResult?>) {
      return result.then((nextValue) {
        if (nextValue != null) {
          return nextValue;
        }

        return !context.isActive
            ? null
            : _chainValidation(context, value, state, index + 1);
      });
    }

    return result ?? _chainValidation(context, value, state, index + 1);
  }

  @override
  int get hashCode => Object.hashAll(validators);
}

/// Passes when a value is present — fails (with [message] or the default
/// `formNotEmpty`) when it is `null` or an empty `String`. The essential
/// "required field" leaf validator.
@immutable
class RequiredValidator<T> extends Validator<T> {
  /// Creates a [RequiredValidator].
  const RequiredValidator({this.message});

  /// Overrides the default `formNotEmpty` message shown when the value is
  /// missing. Null uses the localized default from
  /// [CoreValidationContext.messages].
  final String? message;

  @override
  FutureOr<ValidationResult?> validate(
    CoreValidationContext context,
    T? value,
    FormValidationMode state,
  ) {
    final isMissing = value == null || (value is String && value.isEmpty);
    if (!isMissing) {
      return null;
    }

    return InvalidResult(
      message ?? context.messages.formNotEmpty,
      state: state,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RequiredValidator && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}
