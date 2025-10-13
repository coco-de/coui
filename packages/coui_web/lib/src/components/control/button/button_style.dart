import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
import 'package:coui_web/src/base/variant_system.dart';

/// Styling interface for Button components using Tailwind CSS variants.
///
/// This class is kept for backward compatibility but delegates to the
/// new variant system internally.
abstract interface class ButtonStyling implements Styling {}

/// Button style class supporting Tailwind CSS-based styling.
class ButtonStyle implements ButtonStyling {
  const ButtonStyle(
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

/// Button variant class using the new variant system.
///
/// This provides a more flexible way to compose button styles using
/// Tailwind CSS utility classes.
class ButtonVariantStyle implements ButtonStyling {
  const ButtonVariantStyle({
    required this.variant,
    this.size,
    this.additionalClasses,
  });

  /// The button variant (primary, secondary, etc.).
  final ButtonVariant variant;

  /// The button size.
  final ButtonSize? size;

  /// Additional custom classes.
  final String? additionalClasses;

  @override
  String get cssClass {
    final sizeClasses = size?.classes ?? ButtonSize.md.classes;
    final baseClasses =
        'inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50';

    return [
      baseClasses,
      variant.classes,
      sizeClasses,
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
