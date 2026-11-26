/// Field definition for `ObjectInput`.
library;

import 'package:meta/meta.dart';

/// A single key-value field within a `ObjectInput`.
///
/// Each field has a unique [key] (used as the map key in the emitted
/// values), a [placeholder] shown when empty, an optional [maxLength]
/// constraint, and an optional per-character [pattern] filter.
///
/// Platform-neutral — both Flutter `ObjectInput` and Web
/// `ObjectInput` consume the same field list.
@immutable
class CoreObjectInputField {
  /// Creates a [CoreObjectInputField].
  const CoreObjectInputField({
    required this.key,
    required this.placeholder,
    this.maxLength,
    this.pattern,
  });

  /// Unique identifier for this field in the emitted values map.
  final String key;

  /// Placeholder text shown when the field is empty.
  final String placeholder;

  /// Maximum number of characters accepted, or `null` for unbounded.
  final int? maxLength;

  /// Regular-expression source each character must match (e.g. `r'\d'`
  /// for digit-only fields) — non-matching input is rejected on both
  /// platforms. `null` accepts any character.
  final String? pattern;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreObjectInputField &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          placeholder == other.placeholder &&
          maxLength == other.maxLength &&
          pattern == other.pattern;

  @override
  int get hashCode => Object.hash(key, placeholder, maxLength, pattern);
}
