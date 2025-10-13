import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/base/variant_system.dart';

/// Styling interface for Dialog components.
abstract interface class DialogStyling implements Styling {}

/// Dialog style class using Tailwind CSS.
class DialogStyle implements DialogStyling {
  const DialogStyle(
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

/// Dialog variant style.
class DialogVariantStyle implements DialogStyling {
  const DialogVariantStyle({
    required this.variant,
    this.additionalClasses,
  });

  /// The dialog variant.
  final DialogVariant variant;

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
