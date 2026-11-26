/// Platform-independent form controller contract.
library;

import 'dart:async';

import 'package:coui_core/src/component/contracts/form/core_form_field_handle.dart';
import 'package:coui_core/src/component/contracts/form/core_form_key.dart';
import 'package:coui_core/src/component/contracts/form/core_validation_context.dart';
import 'package:coui_core/src/component/contracts/form/form_validation_mode.dart';
import 'package:coui_core/src/component/contracts/form/validation_result.dart';
import 'package:coui_core/src/component/contracts/form/validator.dart';
import 'package:coui_core/src/component/listenable.dart';

/// Coordinates a form's fields: collects their values, runs their
/// validators, tracks per-field validation results, and notifies listeners
/// whenever any of it changes.
///
/// The observable surface ([values] / [validities] / [errors] / the lookup
/// methods / the [CoreListenable] callbacks) is what form UIs read. Fields
/// feed the controller through [attach]; a form triggers a full pass through
/// [revalidate]. Both take a [CoreValidationContext] rather than a platform
/// widget context, so the Flutter binding (`ChangeNotifier`-backed) and the
/// Web binding (listener bag) share one controller vocabulary.
abstract interface class CoreFormControllerContract implements CoreListenable {
  /// Current value of every attached field, keyed by [CoreFormKey].
  Map<CoreFormKey<dynamic>, Object?> get values;

  /// Current validation result of every attached field (synchronous, or an
  /// in-flight `Future`), keyed by [CoreFormKey].
  Map<CoreFormKey<dynamic>, FutureOr<ValidationResult?>> get validities;

  /// Only the fields currently in error, keyed by [CoreFormKey]. A field
  /// whose asynchronous validation is still pending surfaces a
  /// [WaitingResult].
  Map<CoreFormKey<dynamic>, ValidationResult> get errors;

  /// Current value of the field identified by [key], or null.
  T? getValue<T>(CoreFormKey<T> key);

  /// Whether the field identified by [key] currently holds a non-null value.
  bool hasValue(CoreFormKey<dynamic> key);

  /// The validation result for [key] (synchronous, or a `Future`), or null
  /// when none exists.
  FutureOr<ValidationResult?>? getError(CoreFormKey<dynamic> key);

  /// The synchronous validation result for [key], collapsing an in-flight
  /// validation to a [WaitingResult].
  ValidationResult? getSyncError(CoreFormKey<dynamic> key);

  /// Re-runs every attached field's validator for the [lifecycle] trigger,
  /// using [context] for localized messages and a liveness check.
  void revalidate(CoreValidationContext context, FormValidationMode lifecycle);

  /// Registers (or updates) the field behind [handle] with its [value] and
  /// [validator], validating immediately and triggering cross-field
  /// revalidation. Pass [forceRevalidate] to re-validate even when nothing
  /// changed. Returns the field's validation result.
  FutureOr<ValidationResult?> attach(
    CoreValidationContext context,
    CoreFormFieldHandle handle,
    Object? value,
    Validator<dynamic>? validator, {
    bool forceRevalidate,
  });

  /// Releases the controller's resources.
  void dispose();
}
