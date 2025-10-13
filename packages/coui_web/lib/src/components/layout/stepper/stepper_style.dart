import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Styling interface for Stepper components.
abstract interface class StepperStyling implements Styling {}

/// Stepper style class using Tailwind CSS.
class StepperStyle implements StepperStyling {
  const StepperStyle(
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
