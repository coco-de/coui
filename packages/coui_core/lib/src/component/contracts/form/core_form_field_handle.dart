/// Platform-independent form field handle.
library;

import 'dart:async';

import 'package:coui_core/src/component/contracts/form/core_form_key.dart';
import 'package:coui_core/src/component/contracts/form/validation_result.dart';

/// A per-field handle the controlled-state glue installs above each form
/// input — inputs report their value to it and it routes that to the
/// `CoreFormControllerContract`.
///
/// On Flutter the visual `FormField` mixes in the binding handle and
/// exposes itself through `Data.inherit`; an input mixes in
/// `FormValueSupplier` and finds the handle via `Data.maybeOf`. The Web
/// binding installs an equivalent handle. Lives in `coui_core` so both
/// bindings share one handle vocabulary — inputs depend only on this
/// interface.
abstract interface class CoreFormFieldHandle {
  /// Stable identity of this field within its controller.
  CoreFormKey<dynamic> get formKey;

  /// Whether the field's host is still active. Asynchronous reporting
  /// checks this before applying a result that resolved late.
  bool get mounted;

  /// Reports a new [value] for this field, returning the validation result
  /// (synchronous, or an in-flight `Future`).
  FutureOr<ValidationResult?> reportNewFormValue<T>(T? value);

  /// Re-runs this field's validator against its current value.
  FutureOr<ValidationResult?> revalidate();
}
