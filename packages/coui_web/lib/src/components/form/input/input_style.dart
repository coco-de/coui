import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/base/variant_system.dart';

/// Styling interface for Input components.
abstract interface class InputStyling implements Styling {}

/// Input style class using Tailwind CSS variants.
class InputStyle implements InputStyling {
  const InputStyle(
    this.cssClass, {
    this.modifiers,
    required this.type,
  });

  @override
  final String cssClass;

  @override
  final StyleType type;

  @override
  final List<PrefixModifier>? modifiers;

  @override
  String toString() {
    final currentModifiers = modifiers;
    if (currentModifiers == null || currentModifiers.isEmpty) {
      return cssClass;
    }
    final prefixesString = currentModifiers.map((m) => m.prefix).join();

    return '$prefixesString$cssClass';
  }
}

/// Input variant style using the new variant system.
class InputVariantStyle implements InputStyling {
  const InputVariantStyle({
    this.variant,
    this.additionalClasses,
  });

  /// The input variant.
  final InputVariant? variant;

  /// Additional custom classes.
  final String? additionalClasses;

  @override
  String get cssClass {
    final variantClasses =
        variant?.classes ?? InputVariant.defaultVariant.classes;

    return [
      variantClasses,
      additionalClasses,
    ].where((c) => c != null && c.isNotEmpty).join(' ');
  }

  @override
  StyleType get type => StyleType.style;

  @override
  List<PrefixModifier>? get modifiers => null;

  @override
  String toString() => cssClass;
}
