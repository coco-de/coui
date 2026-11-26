/// Platform-independent form field key.
library;

/// Opaque, typed identity addressing a single field's value within a form's
/// value / validation maps.
///
/// Platform form keys (Flutter `FormKey`, the Web binding) implement this so
/// `coui_core` validation types (`ValidationResult`, the form-controller
/// contract) can reference a key without depending on a platform widget key.
/// The Flutter `FormKey` additionally `extends LocalKey` so it doubles as a
/// widget key — that framework coupling stays in `coui_flutter` while the
/// shared identity surface lives here.
///
/// Type parameter:
/// - [T] — the value type this key addresses.
abstract interface class CoreFormKey<T> {
  /// The opaque identity object distinguishing this key from others. Two
  /// keys with equal [key] address the same field.
  Object get key;

  /// The value type [T] this key addresses.
  Type get type;

  /// Whether [value] is assignable to this key's value type [T].
  bool isInstanceOf(Object? value);
}
