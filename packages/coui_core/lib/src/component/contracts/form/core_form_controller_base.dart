/// Platform-independent form controller algorithm.
library;

import 'dart:async';

import 'package:coui_core/src/component/contracts/form/core_form_controller.dart';
import 'package:coui_core/src/component/contracts/form/core_form_field_handle.dart';
import 'package:coui_core/src/component/contracts/form/core_form_key.dart';
import 'package:coui_core/src/component/contracts/form/core_validation_context.dart';
import 'package:coui_core/src/component/contracts/form/form_validation_mode.dart';
import 'package:coui_core/src/component/contracts/form/validation_result.dart';
import 'package:coui_core/src/component/contracts/form/validator.dart';
import 'package:meta/meta.dart';

/// A field's reported value paired with the validator guarding it. Stored per
/// field by [CoreFormControllerMixin]; its [==] lets `attach` short-circuit
/// when neither the value nor the validator changed.
@immutable
class FormValueState<T> {
  /// Creates a [FormValueState].
  const FormValueState({this.validator, this.value});

  /// The field's current value.
  final T? value;

  /// The validator applied to [value], if any.
  final Validator<T>? validator;

  @override
  bool operator ==(Object other) {
    return other is FormValueState &&
        other.value == value &&
        other.validator == validator;
  }

  @override
  int get hashCode => Object.hash(value, validator);
}

/// A field's latest validation result together with the trigger mode that
/// produced it.
class _ValidatorResultStash {
  const _ValidatorResultStash(this.result, this.state);

  final FutureOr<ValidationResult?> result;

  final FormValidationMode state;
}

/// The shared [CoreFormControllerContract] algorithm — per-field value and
/// validity tracking plus the `attach` / `revalidate` cross-field validation
/// logic — so both platform controllers keep one validation behaviour
/// (single-source, no Flutter/Web divergence).
///
/// The Flutter binding mixes this into a `ChangeNotifier`; the Web binding
/// mixes it into a listener-bag controller. Each supplies only
/// [scheduleNotification] (defer a change notification past the current
/// build/frame, skip a disposed controller, then notify) plus the
/// `CoreListenable` surface and `dispose`.
mixin CoreFormControllerMixin implements CoreFormControllerContract {
  // Reassigned (not mutated in place) on every change — each update rebuilds
  // the map via a spread, keeping the controller free of in-place collection
  // mutation while async validators reassign these from their own callbacks.
  Map<CoreFormKey<dynamic>, FormValueState<dynamic>> _attachedInputs = {};
  Map<CoreFormKey<dynamic>, _ValidatorResultStash> _validity = {};

  /// Schedules a deferred change notification. The platform binding defers
  /// past the current build/frame (Flutter: post-frame callback; Web:
  /// microtask), skips a disposed controller, then notifies listeners.
  @protected
  void scheduleNotification();

  @override
  Map<CoreFormKey<dynamic>, Object?> get values {
    return {
      for (final entry in _attachedInputs.entries) entry.key: entry.value.value,
    };
  }

  @override
  Map<CoreFormKey<dynamic>, FutureOr<ValidationResult?>> get validities {
    return {
      for (final entry in _validity.entries) entry.key: entry.value.result,
    };
  }

  @override
  Map<CoreFormKey<dynamic>, ValidationResult> get errors {
    final errors = <CoreFormKey<dynamic>, ValidationResult>{};
    for (final entry in _validity.entries) {
      final result = entry.value.result;
      if (result is Future<ValidationResult?>) {
        errors[entry.key] = WaitingResult.attached(
          key: entry.key,
          state: entry.value.state,
        );
      } else if (result != null) {
        errors[entry.key] = result;
      }
    }

    return errors;
  }

  @override
  FutureOr<ValidationResult?>? getError(CoreFormKey<dynamic> key) {
    return _validity[key]?.result;
  }

  @override
  ValidationResult? getSyncError(CoreFormKey<dynamic> key) {
    final entry = _validity[key];
    final result = entry?.result;

    return result is Future<ValidationResult?>
        ? WaitingResult.attached(key: key, state: entry!.state)
        : result;
  }

  @override
  T? getValue<T>(CoreFormKey<T> key) {
    return _attachedInputs[key]?.value as T?;
  }

  @override
  bool hasValue(CoreFormKey<dynamic> key) {
    return _attachedInputs[key]?.value != null;
  }

  @override
  void revalidate(CoreValidationContext context, FormValidationMode state) {
    var changed = false;
    final validityUpdates = <CoreFormKey<dynamic>, _ValidatorResultStash>{};
    for (final entry in _attachedInputs.entries) {
      final key = entry.key;
      final input = entry.value;
      if (input.validator != null) {
        final future = input.validator!.validate(context, input.value, state);
        if (_validity[key]?.result != future) {
          if (future is Future<ValidationResult?>) {
            validityUpdates[key] = _ValidatorResultStash(future, state);
            unawaited(
              future.then((value) {
                if (_validity[key]?.result == future) {
                  _validity = {
                    ..._validity,
                    key: _ValidatorResultStash(value?.attach(key), state),
                  };
                  scheduleNotification();
                }
              }),
            );
          } else {
            validityUpdates[key] = _ValidatorResultStash(future, state);
          }
          changed = true;
        }
      }
    }
    _validity = {..._validity, ...validityUpdates};
    if (changed) {
      scheduleNotification();
    }
  }

  @override
  FutureOr<ValidationResult?> attach(
    CoreValidationContext context,
    CoreFormFieldHandle handle,
    Object? value,
    Validator<dynamic>? validator, {
    bool forceRevalidate = false,
  }) {
    final key = handle.formKey;
    final oldState = _attachedInputs[key];
    final state = FormValueState(validator: validator, value: value);
    if (oldState == state && !forceRevalidate) {
      return _validity[key]?.result;
    }
    final lifecycle = oldState == null
        ? FormValidationMode.initial
        : FormValidationMode.changed;
    _attachedInputs = {..._attachedInputs, key: state};
    // Validate the changed field.
    final future = validator?.validate(context, value, lifecycle);
    if (future is Future<ValidationResult?>) {
      _validity = {..._validity, key: _ValidatorResultStash(future, lifecycle)};
      unawaited(
        future.then((value) {
          // Resolve the future and store the synchronous value.
          if (_validity[key]?.result == future) {
            _validity = {
              ..._validity,
              key: _ValidatorResultStash(value?.attach(key), lifecycle),
            };
            scheduleNotification();
          }
        }),
      );
    } else {
      _validity = {..._validity, key: _ValidatorResultStash(future, lifecycle)};
    }
    // Re-run any field whose validator depends on the changed one.
    final revalidate = <CoreFormKey<dynamic>, FutureOr<ValidationResult?>>{};
    for (final entry in _attachedInputs.entries) {
      final k = entry.key;
      final input = entry.value;
      if (key == k) {
        continue;
      }
      if (input.validator != null && input.validator!.shouldRevalidate(key)) {
        revalidate[k] = input.validator!.validate(
          context,
          input.value,
          lifecycle,
        );
      }
    }
    final inputsUpdates = <CoreFormKey<dynamic>, FormValueState<dynamic>>{};
    final validityUpdates = <CoreFormKey<dynamic>, _ValidatorResultStash>{};
    for (final entry in revalidate.entries) {
      final k = entry.key;
      final future = entry.value;
      final attachedInput = _attachedInputs[k]!;
      inputsUpdates[k] = FormValueState(
        validator: attachedInput.validator,
        value: attachedInput.value,
      );
      if (future is Future<ValidationResult?>) {
        validityUpdates[k] = _ValidatorResultStash(future, lifecycle);
        unawaited(
          future.then((value) {
            if (_validity[k]?.result == future) {
              _validity = {
                ..._validity,
                k: _ValidatorResultStash(value?.attach(k), lifecycle),
              };
              scheduleNotification();
            }
          }),
        );
      } else {
        validityUpdates[k] = _ValidatorResultStash(future, lifecycle);
      }
    }
    _attachedInputs = {..._attachedInputs, ...inputsUpdates};
    _validity = {..._validity, ...validityUpdates};
    scheduleNotification();

    return _validity[key]?.result;
  }
}
