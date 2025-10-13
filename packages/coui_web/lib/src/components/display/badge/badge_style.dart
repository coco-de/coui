import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/base/variant_system.dart';

/// Styling interface for Badge components.
abstract interface class BadgeStyling implements Styling {}

/// Badge style class using Tailwind CSS variants.
class BadgeStyle implements BadgeStyling {
  const BadgeStyle(
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

/// Badge variant style using the new variant system.
class BadgeVariantStyle implements BadgeStyling {
  const BadgeVariantStyle({
    required this.variant,
    this.additionalClasses,
  });

  /// The badge variant.
  final BadgeVariant variant;

  /// Additional custom classes.
  final String? additionalClasses;

  @override
  String get cssClass {
    return [
      BadgeVariant.defaultVariant.classes,
      variant.classes,
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
