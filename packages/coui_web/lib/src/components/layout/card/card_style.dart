import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/base/variant_system.dart';

/// Styling interface for Card components.
abstract interface class CardStyling implements Styling {}

/// Card style class using Tailwind CSS variants.
class CardStyle implements CardStyling {
  const CardStyle(
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

/// Card variant style using the new variant system.
class CardVariantStyle implements CardStyling {
  const CardVariantStyle({
    required this.variant,
    this.additionalClasses,
  });

  /// The card variant.
  final CardVariant variant;

  /// Additional custom classes.
  final String? additionalClasses;

  @override
  String get cssClass {
    return [
      variant.classes,
      additionalClasses,
    ].where((c) => c != null && c.isNotEmpty).join(' ');
  }

  @override
  StyleType get type => StyleType.layout;

  @override
  List<PrefixModifier>? get modifiers => null;

  @override
  String toString() => cssClass;
}
