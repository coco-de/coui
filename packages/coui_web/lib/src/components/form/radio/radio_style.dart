import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Styling interface for Radio components.
abstract interface class RadioStyling implements Styling {}

/// Radio style class using Tailwind CSS.
class RadioStyle implements RadioStyling {
  const RadioStyle(
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

/// Radio variant style.
class RadioVariantStyle implements RadioStyling {
  const RadioVariantStyle({
    this.additionalClasses,
  });

  /// Additional custom classes.
  final String? additionalClasses;

  @override
  String get cssClass {
    const baseClasses =
        'aspect-square h-4 w-4 rounded-full border border-primary text-primary ring-offset-background focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50';

    return [
      baseClasses,
      additionalClasses,
    ].where((c) => c != null && c.isNotEmpty).join(' ');
  }

  @override
  StyleType get type => StyleType.form;

  @override
  List<PrefixModifier>? get modifiers => null;

  @override
  String toString() => cssClass;
}
