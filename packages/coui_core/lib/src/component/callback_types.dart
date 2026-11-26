/// Platform-independent callback type definitions.
///
/// These are used in component contracts to define callback signatures
/// without depending on Flutter or Jaspr callback types.
library;

/// A callback with no arguments and no return value.
typedef CoreVoidCallback = void Function();

/// A callback that receives a single value of type [T].
typedef CoreValueChanged<T> = void Function(T value);

/// A callback that receives a single value of type [T] and returns a bool.
typedef CoreValuePredicate<T> = bool Function(T value);

/// A callback that receives a single value and returns a string
/// (for formatters).
typedef CoreValueFormatter<T> = String Function(T value);
