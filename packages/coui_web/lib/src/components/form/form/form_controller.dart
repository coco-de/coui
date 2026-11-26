/// Web binding for the unified form controller and validation context.
library;

import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:jaspr/jaspr.dart';

/// Stable identity of a field within a [FormController].
///
/// Mirrors Flutter `FormKey` (which additionally extends `LocalKey` to double
/// as a widget key — not needed on Web). Cross-platform: `FormKey('email')`
/// reads identically on both platforms. Implements the platform-neutral
/// [CoreFormKey].
class FormKey<T> implements CoreFormKey<T> {
  /// Creates a [FormKey] identified by [key].
  const FormKey(this.key);

  @override
  final Object key;

  @override
  Type get type => T;

  @override
  bool isInstanceOf(Object? value) {
    return value is T;
  }

  @override
  bool operator ==(Object other) {
    return other is FormKey && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() {
    return 'FormKey($key)';
  }
}

/// Web [CoreFormControllerContract] — coordinates a form's fields, runs their
/// validators, and notifies listeners on change.
///
/// The value/validity tracking and the `attach` / `revalidate` algorithm come
/// from the shared [CoreFormControllerMixin] (single-source with Flutter); this
/// binding supplies only the notification mechanism: a copy-on-write listener
/// bag plus microtask-deferred dispatch (mirroring Flutter `FormController`'s
/// `ChangeNotifier` + post-frame callback). Mechanism differs per platform;
/// capability and API are identical.
///
/// Example:
/// ```dart
/// final controller = FormController();
/// controller.addListener(() => print(controller.errors));
/// // A `FormField` attaches its inputs and the controller validates.
/// ```
class FormController with CoreFormControllerMixin {
  // Listener bag — copy-on-write so a dispatch can iterate a snapshot while a
  // listener calls [removeListener].
  List<void Function()> _listeners = const [];
  bool _disposed = false;

  @override
  void addListener(void Function() listener) {
    if (_disposed) {
      return;
    }
    _listeners = [..._listeners, listener];
  }

  @override
  void removeListener(void Function() listener) {
    if (_disposed) {
      return;
    }
    _listeners = _listeners.where((entry) => entry != listener).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _listeners = const [];
  }

  @override
  void scheduleNotification() {
    // Defer past the current synchronous batch (Flutter uses a post-frame
    // callback) and skip a disposed controller, then notify.
    scheduleMicrotask(() {
      if (_disposed) {
        return;
      }
      final snapshot = List.of(_listeners);
      for (final listener in snapshot) {
        listener();
      }
    });
  }
}

/// Web binding of [CoreValidationContext] — supplies validators their localized
/// default messages and a liveness flag.
///
/// Bridges [CouiLocalizations] for [messages] and an optional [isActive]
/// callback for the liveness check (mirroring Flutter `CoUIValidationContext`'s
/// `BuildContext.mounted`). A field's glue passes its own liveness; the default
/// reports always-active.
class CoUIWebValidationContext implements CoreValidationContext {
  /// Creates a [CoUIWebValidationContext]. [localizations] defaults to
  /// [CouiLocalizations.instance]; [isActive] defaults to always-active.
  CoUIWebValidationContext({
    CouiLocalizations? localizations,
    bool Function()? isActive,
  }) : _localizations = localizations ?? .instance,
       _isActive = isActive;

  final CouiLocalizations _localizations;
  final bool Function()? _isActive;

  @override
  CoreValidationMessages get messages =>
      _CouiValidationMessages(_localizations);

  @override
  bool get isActive => _isActive?.call() ?? true;
}

/// Bridges [CouiLocalizations] to the [CoreValidationMessages] surface
/// validators read for their default error strings.
class _CouiValidationMessages implements CoreValidationMessages {
  const _CouiValidationMessages(this._localizations);

  final CouiLocalizations _localizations;

  @override
  String get invalidValue => _localizations.invalidValue;

  @override
  String get formNotEmpty => _localizations.formNotEmpty;

  @override
  String get phoneNumberIncomplete => _localizations.phoneNumberIncomplete;
}

/// Provides a [FormController] to descendant `FormField`s.
///
/// Installed by `Form` when it is given a controller; a `FormField` finds it
/// via [maybeOf] (the Web counterpart to Flutter's `Data<FormController>`).
class FormControllerScope extends InheritedComponent {
  /// Creates a [FormControllerScope] exposing [controller] to [child].
  const FormControllerScope({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The controller shared with descendants.
  final FormController controller;

  /// Returns the nearest [FormController] above [context], or null.
  static FormController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<FormControllerScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(FormControllerScope oldComponent) {
    return controller != oldComponent.controller;
  }
}

/// Provides a [CoreFormFieldHandle] to a `FormField`'s child input.
///
/// Installed by `FormField`; an input mixing in [FormValueSupplier] finds it
/// via [maybeOf] to report its value (the Web counterpart to Flutter's
/// `Data<FormFieldHandle>`).
class FormFieldHandleScope extends InheritedComponent {
  /// Creates a [FormFieldHandleScope] exposing [handle] to [child].
  const FormFieldHandleScope({
    required CoreFormFieldHandle this.handle,
    required super.child,
    super.key,
  });

  /// Ends the enclosing field's reach: inputs under [child] find no handle,
  /// so none of them reports to that field.
  ///
  /// For a composite that embeds an input as an implementation detail (the
  /// number field of a `PhoneInput`, the trigger of a `Select`): the
  /// composite owns the value the enclosing `FormField` is shown, and the
  /// text it hands to its parts is not that value. The Web counterpart to
  /// Flutter's `Data<FormFieldHandle>.boundary`.
  const FormFieldHandleScope.boundary({
    required super.child,
    super.key,
  }) : handle = null;

  /// The field handle shared with the child input, or `null` for a
  /// [FormFieldHandleScope.boundary].
  final CoreFormFieldHandle? handle;

  /// Returns the nearest [CoreFormFieldHandle] above [context], or null.
  static CoreFormFieldHandle? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<FormFieldHandleScope>()
        ?.handle;
  }

  @override
  bool updateShouldNotify(FormFieldHandleScope oldComponent) {
    return handle != oldComponent.handle;
  }
}

/// Mixin for a stateful input that participates in a form: it reports its
/// value to the enclosing `FormField`'s [CoreFormFieldHandle] whenever the
/// value changes, so the form controller validates and the field shows the
/// result.
///
/// The Web counterpart to Flutter `FormValueSupplier` — same surface
/// (`formValue` getter/setter + [didReplaceFormValue]); mechanism differs
/// (Jaspr `State` + [FormFieldHandleScope] lookup instead of `Data`).
mixin FormValueSupplier<T, C extends StatefulComponent> on State<C> {
  T? _formValue;
  bool _hasFormValue = false;
  int _futureCounter = 0;
  CoreFormFieldHandle? _handle;

  /// The most recent value reported to the form field.
  T? get formValue => _formValue;

  /// Reports [value] to the enclosing form field (if any) for validation.
  /// No-op when unchanged.
  set formValue(T? value) {
    if (_hasFormValue && _formValue == value) {
      return;
    }
    _hasFormValue = true;
    _formValue = value;
    _reportNewFormValue(value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final handle = FormFieldHandleScope.maybeOf(context);
    if (handle != _handle) {
      _handle = handle;
      _reportNewFormValue(_formValue);
    }
  }

  /// Called when an asynchronous validator returns a [ReplaceResult]
  /// normalising the value — the input should adopt the replacement.
  @protected
  void didReplaceFormValue(T value);

  void _reportNewFormValue(T? value) {
    final handle = _handle;
    if (handle == null) {
      return;
    }
    final currentCounter = _futureCounter += 1;
    final result = handle.reportNewFormValue<T>(value);
    if (result is Future<ValidationResult?>) {
      unawaited(
        result.then((resolved) {
          if (_futureCounter == currentCounter &&
              resolved is ReplaceResult<T> &&
              mounted) {
            didReplaceFormValue(resolved.value);
          }
        }),
      );
    } else if (result is ReplaceResult<T> && mounted) {
      didReplaceFormValue(result.value);
    }
  }
}
