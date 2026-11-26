import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';

class FormKey<T> extends LocalKey implements CoreFormKey<T> {
  const FormKey(this.key);

  @override
  final Object key;

  @override
  Type get type => T;

  @override
  bool isInstanceOf(Object? value) {
    return value is T;
  }

  T? getValue(FormMapValues values) {
    return values.getValue(this);
  }

  T? operator [](FormMapValues values) {
    return values.getValue(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FormKey && other.key == key;
  }

  @override
  String toString() {
    return 'FormKey($key)';
  }

  @override
  int get hashCode => key.hashCode;
}

mixin FormFieldHandle implements CoreFormFieldHandle {
  // `mounted`, `reportNewFormValue`, and `revalidate` come straight from
  // [CoreFormFieldHandle]; only `formKey` is re-declared to narrow its return
  // to the Flutter [FormKey] (covariant).
  @override
  FormKey<dynamic> get formKey;

  /// The live validity of this field. Flutter-only extra on top of
  /// [CoreFormFieldHandle] — drives the visual `FormField` error text via a
  /// `ValueListenableBuilder`.
  ValueListenable<ValidationResult?>? get validity;
}

class _FormEntryCachedValue {
  _FormEntryCachedValue(this.value);
  Object? value;
}

typedef FormMapValues = Map<FormKey<dynamic>, dynamic>;

/// Typed lookup over a [FormMapValues] map keyed by [FormKey].
extension FormMapValuesExtension on FormMapValues {
  /// Returns the value for [key], or null if absent.
  T? getValue<T>(FormKey<T> key) {
    final Object? value = this[key];
    if (value == null) {
      return null;
    }
    assert(
      key.isInstanceOf(value),
      'The value for key $key is not of type ${key.type}',
    );

    return value as T?;
  }
}

/// Adapts a Flutter [BuildContext] to the platform-neutral
/// [CoreValidationContext] that validators consume — bridging
/// [CoUILocalizations] for default messages and `mounted` for the liveness
/// check.
///
/// This is the Flutter binding of [CoreValidationContext]: callers that hand
/// a `BuildContext`-rooted value to [FormController.attach] /
/// [FormController.revalidate] wrap it as `CoUIValidationContext(context)`.
/// The Web binding supplies its own [CoreValidationContext].
class CoUIValidationContext implements CoreValidationContext {
  /// Creates a [CoUIValidationContext] from a [context].
  const CoUIValidationContext(this._context);

  final BuildContext _context;

  // Looked up lazily so a validator with an explicit message (which never
  // reads [messages]) needs no `CoUILocalizations` in scope. Validators that
  // read it after an `await` capture it synchronously beforehand.
  @override
  CoreValidationMessages get messages => _CoUIValidationMessages(
    Localizations.of<CoUILocalizations>(_context, CoUILocalizations)!,
  );

  @override
  bool get isActive => _context.mounted;
}

/// Bridges [CoUILocalizations] to the [CoreValidationMessages] surface
/// validators read for their default error strings.
class _CoUIValidationMessages implements CoreValidationMessages {
  const _CoUIValidationMessages(this._localizations);

  final CoUILocalizations _localizations;

  @override
  String get invalidValue => _localizations.invalidValue;

  @override
  String get formNotEmpty => _localizations.formNotEmpty;

  @override
  String get phoneNumberIncomplete => _localizations.phoneNumberIncomplete;
}

/// Controller for managing form state, validation, and submission.
///
/// Coordinates all form field interactions, maintaining a centralized
/// registry of field values and validation states. Provides programmatic
/// access to form data collection and validation triggering, and supports
/// both synchronous and asynchronous validation plus cross-field validation
/// dependencies.
///
/// The Flutter binding of [CoreFormControllerContract]: the value/validity
/// tracking and the `attach` / `revalidate` algorithm live in the shared
/// [CoreFormControllerMixin] (so Flutter and Web stay single-source); this
/// class supplies only the `ChangeNotifier`-backed notification mechanism.
///
/// Example:
/// ```dart
/// final controller = FormController();
///
/// // Listen to form state changes.
/// controller.addListener(() {
///   print('Form values: ${controller.values}');
/// });
///
/// // Access specific field values.
/// final emailValue = controller.getValue(emailKey);
/// ```
class FormController extends ChangeNotifier with CoreFormControllerMixin {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void scheduleNotification() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_disposed) {
        return;
      }
      notifyListeners();
    });
  }
}

mixin FormValueSupplier<T, X extends StatefulWidget> on State<X> {
  _FormEntryCachedValue? _cachedValue;
  int _futureCounter = 0;
  FormFieldHandle? _entryState;

  T? get formValue => _cachedValue?.value as T?;
  set formValue(T? value) {
    if (_cachedValue != null && _cachedValue!.value == value) {
      return;
    }
    _cachedValue = _FormEntryCachedValue(value);
    _reportNewFormValue(value);
  }

  /// Whether this input reports to the [FormFieldHandle] found above it.
  ///
  /// `true` by default: an input reports to whichever field encloses it. An
  /// input that also gets mounted *away* from the field it belongs to — a
  /// text box in a dialog or popover opened from inside the field — returns
  /// `false` there. `FormField` publishes the handle as a `Data`, and the
  /// kit's overlays copy every `Data` into what they open, so the handle
  /// follows the overlay while the field's own scope does not.
  ///
  /// Read from `didChangeDependencies`, so it may depend on inherited
  /// widgets; a change in what it depends on re-evaluates it.
  @protected
  bool get reportsToFormField => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newState = reportsToFormField
        ? Data.maybeOf<FormFieldHandle>(context)
        : null;
    if (newState != _entryState) {
      _entryState = newState;
      _reportNewFormValue(_cachedValue?.value as T?);
    }
  }

  @protected
  void didReplaceFormValue(T value);

  void _reportNewFormValue(T? value) {
    final state = _entryState;
    if (state == null) {
      return;
    }
    final currentCounter = _futureCounter += 1;
    final validationResult = state.reportNewFormValue<T>(value);
    if (validationResult is Future<ValidationResult?>) {
      unawaited(
        validationResult.then((value) {
          if (_futureCounter == currentCounter && value is ReplaceResult<T>) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              if (context.mounted) {
                didReplaceFormValue(value.value);
              }
            });
          }
        }),
      );
    } else if (validationResult is ReplaceResult<T>) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (context.mounted) {
          didReplaceFormValue(validationResult.value);
        }
      });
    }
  }
}
