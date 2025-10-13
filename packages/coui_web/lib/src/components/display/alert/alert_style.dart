import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/base/variant_system.dart';

/// Styling interface for Alert components.
abstract interface class AlertStyling implements Styling {}

/// Alert style class using Tailwind CSS variants.
class AlertStyle implements AlertStyling {
  const AlertStyle(
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

/// Alert variant style using the new variant system.
class AlertVariantStyle implements AlertStyling {
  const AlertVariantStyle({
    required this.variant,
    this.additionalClasses,
  });

  /// The alert variant.
  final AlertVariant variant;

  /// Additional custom classes.
  final String? additionalClasses;

  @override
  String get cssClass {
    return [
      AlertVariant.defaultVariant.classes,
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
