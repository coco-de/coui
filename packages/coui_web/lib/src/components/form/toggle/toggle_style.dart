import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Styling interface for Toggle components.
abstract interface class ToggleStyling implements Styling {}

/// Toggle style class using Tailwind CSS.
class ToggleStyle implements ToggleStyling {
  const ToggleStyle(
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

/// Toggle variant style (switch-style toggle).
class ToggleVariantStyle implements ToggleStyling {
  const ToggleVariantStyle({
    this.additionalClasses,
  });

  /// Additional custom classes.
  final String? additionalClasses;

  @override
  String get cssClass {
    const baseClasses =
        'peer inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=unchecked]:bg-input';

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
