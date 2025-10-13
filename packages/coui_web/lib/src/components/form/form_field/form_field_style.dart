import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Styling interface for FormField components.
abstract interface class FormFieldStyling implements Styling {}

/// FormField style class using Tailwind CSS.
class FormFieldStyle implements FormFieldStyling {
  const FormFieldStyle(
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
