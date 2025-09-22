import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// An abstract generic class representing a UI utility class (modifier).
///
/// This class provides a foundation for creating type-safe utility classes
/// that can be combined with [PrefixModifier]s (e.g., for responsive or
/// state-based styling).
/// It implements [Styling] to be usable in heterogeneous lists of modifiers
/// and [Comparable] to allow sorting of utilities of the same specific
/// type `T`.
///
/// Type parameter:
///   `T`: The concrete type of the utility class itself, enabling fluent
///        chaining methods like `on()` and `at()` to return the correct
///        specific type.
abstract class BaseStyle<T extends BaseStyle<T>>
    implements Styling, Comparable<T> {
  /// Constructs a [BaseStyle].
  ///
  /// [cssClass]: The core CSS class string (e.g., "text-center").
  /// [type]: The [StyleType] categorizing this utility.
  /// [modifiers]: An optional list of [PrefixModifier]s already applied.
  const BaseStyle(this.cssClass, {this.modifiers, required this.type});

  @override
  final String cssClass;
  @override
  final StyleType type;
  @override
  final List<PrefixModifier>? modifiers;

  /// Abstract factory method to create a new instance of this utility
  /// class (`T`) with a given list of [PrefixModifier]s.
  ///
  /// This method must be implemented by concrete subclasses to ensure
  /// that methods like `on()` and `at()` can return the correct specific
  /// type `T`.
  T create(List<PrefixModifier> newModifiers);

  /// Applies a list of [PrefixModifier]s to this utility class.
  ///
  /// Returns a new instance of `T` with the combined prefixes.
  /// If this utility already has prefixes, the new ones are appended.
  T on(List<PrefixModifier> newModifiers) {
    // Ensure existing modifiers are preserved and new ones are added.
    // Handle null or empty existing modifiers.
    final current = modifiers ?? [];

    return create([...current, ...newModifiers]);
  }

  /// Applies a single responsive breakpoint [PrefixModifier] to this
  /// utility class.
  ///
  /// If the provided [breakpoint] is not of type
  /// [PrefixModifierType.breakpoint], `this` instance is returned unchanged.
  /// Otherwise, a new instance of `T` with the breakpoint prefix applied
  /// is returned.
  T at(PrefixModifier breakpoint) {
    if (breakpoint.type == PrefixModifierType.breakpoint) {
      final existingModifiers = modifiers ?? [];

      return create([...existingModifiers, breakpoint]);
    }

    // It might be more robust to throw an error or log a warning if a
    // non-breakpoint modifier is passed to `at()`, but returning `this` is
    // also an option. For now, let's assume `at` is strictly for breakpoints.
    return this as T;
  }

  /// Returns the string representation of this utility class, including
  /// all applied prefixes. For example, `hover:md:text-lg`.
  @override
  String toString() {
    final currentModifiers = modifiers;
    if (currentModifiers == null || currentModifiers.isEmpty) {
      return cssClass;
    }
    final prefixesString = currentModifiers
        .map((modifier) => modifier.prefix)
        .join();

    return '$prefixesString$cssClass';
  }

  /// Compares this utility class to another of the same type `T`.
  ///
  /// Comparison is based on:
  /// 1. [StyleType] (enum index).
  /// 2. [cssClass] (lexicographically).
  /// 3. Applied [PrefixModifier]s (lexicographically by prefix string,
  ///    then by count).
  @override
  int compareTo(T other) {
    final typeComparison = type.index.compareTo(other.type.index);
    if (typeComparison != 0) return typeComparison;

    final cssComparison = cssClass.compareTo(other.cssClass);
    if (cssComparison != 0) return cssComparison;

    return _compareModifiers(modifiers, other.modifiers);
  }

  // Performance note: consider optimizing modifier comparison if needed.
  /// Helper method to compare lists of [PrefixModifier]s.
  int _compareModifiers(
    List<PrefixModifier>? firstList,
    List<PrefixModifier>? secondList,
  ) {
    final first = firstList ?? [];
    final second = secondList ?? [];

    if (first.isEmpty && second.isEmpty) return 0;
    if (first.isEmpty) return -1; // Empty list comes before non-empty
    if (second.isEmpty) return 1; // Non-empty list comes after empty

    final firstIt = first.iterator;
    final secondIt = second.iterator;
    while (firstIt.moveNext() && secondIt.moveNext()) {
      final comparison = firstIt.current.prefix.compareTo(
        secondIt.current.prefix,
      );
      if (comparison != 0) return comparison;
    }

    // If all compared prefixes equal, shorter list comes first
    return first.length.compareTo(second.length);
  }
}
