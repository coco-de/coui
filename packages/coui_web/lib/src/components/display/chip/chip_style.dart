import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Styling interface for Chip components.
abstract interface class ChipStyling implements Styling {}

/// Chip style class using Tailwind CSS.
class ChipStyle implements ChipStyling {
  const ChipStyle(
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

/// Chip variant style.
class ChipVariantStyle implements ChipStyling {
  const ChipVariantStyle({
    this.additionalClasses,
  });

  /// Additional custom classes.
  final String? additionalClasses;

  @override
  String get cssClass {
    const baseClasses =
        'inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-semibold transition-colors border bg-background text-foreground hover:bg-accent';

    return [
      baseClasses,
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
